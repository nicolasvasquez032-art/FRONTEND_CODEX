import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/postulacion_model.dart';
import '../../../domain/entities/postulacion.dart';
import '../../../domain/repositories/postulacion_repository.dart';

enum PostulacionesStatus { initial, loading, loaded, error }

class PostulacionesProvider extends ChangeNotifier {
  final PostulacionRepository _repo;

  PostulacionesProvider(this._repo);

  PostulacionesStatus status = PostulacionesStatus.initial;
  List<Postulacion> postulaciones = [];
  String? error;

  // Mapa vacante_id → Postulacion para saber si ya postuló
  final Map<String, Postulacion> _byVacante = {};

  bool yaPostulado(String vacanteId) => _byVacante.containsKey(vacanteId);
  Postulacion? postulacionDe(String vacanteId) => _byVacante[vacanteId];

  // ─────────────────────────────────────────────
  // Resetear al cambiar de cuenta / logout
  // ─────────────────────────────────────────────

  void limpiar() {
    status = PostulacionesStatus.initial;
    postulaciones = [];
    _byVacante.clear();
    error = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Carga Offline-First y Persistencia de Caché
  // ─────────────────────────────────────────────

  String _cacheKey(String candidatoId) => 'offline_postulaciones_$candidatoId';

  Future<void> _loadCache(String candidatoId) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final cachedJson = sp.getString(_cacheKey(candidatoId));
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decoded = jsonDecode(cachedJson) as List<dynamic>;
        final cached = decoded
            .map((item) => PostulacionModel.fromJson(item as Map<String, dynamic>).toEntity())
            .toList();
        if (cached.isNotEmpty && postulaciones.isEmpty) {
          postulaciones = cached;
          _byVacante
            ..clear()
            ..addEntries(postulaciones.map((p) => MapEntry(p.vacanteId, p)));
          status = PostulacionesStatus.loaded;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> _saveCache(String candidatoId) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final listMap = postulaciones.map((p) => PostulacionModel.fromEntity(p).toJson()).toList();
      await sp.setString(_cacheKey(candidatoId), jsonEncode(listMap));
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  // Cargar postulaciones del candidato (Offline-First)
  // ─────────────────────────────────────────────

  Future<void> cargar(String candidatoId) async {
    // 1. Carga inmediata desde caché si la lista está vacía
    if (postulaciones.isEmpty) {
      await _loadCache(candidatoId);
    }

    if (postulaciones.isEmpty) {
      status = PostulacionesStatus.loading;
      error = null;
      notifyListeners();
    }

    try {
      postulaciones = await _repo.listarMisPostulaciones(candidatoId);
      _byVacante
        ..clear()
        ..addEntries(postulaciones.map((p) => MapEntry(p.vacanteId, p)));
      status = PostulacionesStatus.loaded;
      error = null;
      _saveCache(candidatoId);
    } on ApiException catch (e) {
      if (postulaciones.isEmpty) {
        error = e.message;
        status = PostulacionesStatus.error;
      }
    } catch (_) {
      if (postulaciones.isEmpty) {
        error = 'Sin conexión. Verifica tu red.';
        status = PostulacionesStatus.error;
      }
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Postularse a una vacante (UI Optimista)
  // ─────────────────────────────────────────────

  /// Retorna `true` si fue exitoso, `false` si ya estaba postulado o error.
  Future<bool> postularse({
    required String candidatoId,
    required String vacanteId,
  }) async {
    if (yaPostulado(vacanteId)) return false;

    // ── ACTUALIZACIÓN OPTIMISTA INMEDIATA (0ms de latencia percibida) ──
    final optimisticPostulacion = Postulacion(
      id: 'opt_${DateTime.now().millisecondsSinceEpoch}',
      candidatoId: candidatoId,
      vacanteId: vacanteId,
      estado: PostulacionEstado.postulado,
      fecha: DateTime.now(),
    );

    postulaciones.add(optimisticPostulacion);
    _byVacante[vacanteId] = optimisticPostulacion;
    notifyListeners();

    try {
      final p = await _repo.postularse(
        candidatoId: candidatoId,
        vacanteId: vacanteId,
      );
      // Reemplazamos la optimista con la confirmada del backend
      final optIdx = postulaciones.indexWhere((item) => item.id == optimisticPostulacion.id);
      if (optIdx != -1) {
        postulaciones[optIdx] = p;
      }
      _byVacante[vacanteId] = p;
      _saveCache(candidatoId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      // Rollback silencioso si la API rechaza la postulación
      postulaciones.removeWhere((item) => item.id == optimisticPostulacion.id);
      _byVacante.remove(vacanteId);
      error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      // Rollback silencioso si no hay conexión
      postulaciones.removeWhere((item) => item.id == optimisticPostulacion.id);
      _byVacante.remove(vacanteId);
      error = 'Sin conexión. Verifica tu red.';
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Cancelar postulación
  // ─────────────────────────────────────────────

  Future<bool> cancelar(String postulacionId) async {
    try {
      await _repo.cancelarPostulacion(postulacionId);
      final idx = postulaciones.indexWhere((e) => e.id == postulacionId);
      if (idx != -1) {
        final p = postulaciones.removeAt(idx);
        _byVacante.remove(p.vacanteId);
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Error al cancelar. Verifica tu red.';
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Postulaciones de una vacante (para empresa)
  // ─────────────────────────────────────────────

  Future<List<Postulacion>> listarPorVacante(String vacanteId) async {
    try {
      return await _repo.listarPostulacionesVacante(vacanteId);
    } catch (_) {
      return [];
    }
  }
}
