import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/vacante_model.dart';
import '../../../domain/entities/vacante.dart';
import '../../../domain/repositories/vacante_repository.dart';

enum VacantesStatus { initial, loading, loaded, error }

class VacantesProvider extends ChangeNotifier {
  final VacanteRepository _repo;

  VacantesProvider(this._repo);

  static const _cacheKey = 'offline_vacantes_cache';

  VacantesStatus status = VacantesStatus.initial;
  List<Vacante> vacantes = [];
  String? error;
  bool loadingPub = false;
  bool isOffline = false;

  // Filtros activos
  String? _ubicacion;
  String? _categoria;
  String _query = '';

  // Filtros locales interactivos
  String? _filtroCategoria;
  double? _filtroSalarioMin;

  String? get filtroCategoria => _filtroCategoria;
  double? get filtroSalarioMin => _filtroSalarioMin;

  List<Vacante> get filtered {
    var lista = vacantes;

    if (_filtroCategoria != null && _filtroCategoria!.trim().isNotEmpty) {
      final cat = _filtroCategoria!.trim().toLowerCase();
      lista = lista.where((v) => v.categoria?.toLowerCase() == cat).toList();
    }

    if (_filtroSalarioMin != null) {
      lista = lista.where((v) => (v.salarioMin ?? 0) >= _filtroSalarioMin!).toList();
    }

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      lista = lista.where((v) {
        return v.titulo.toLowerCase().contains(q) ||
            v.ubicacion.toLowerCase().contains(q) ||
            (v.categoria?.toLowerCase().contains(q) ?? false) ||
            v.descripcion.toLowerCase().contains(q);
      }).toList();
    }
    return lista;
  }

  void setCategoriaFiltro(String? cat) {
    if (cat == null || cat.trim().isEmpty || _filtroCategoria == cat.trim()) {
      _filtroCategoria = null;
    } else {
      _filtroCategoria = cat.trim();
    }
    notifyListeners();
  }

  void setSalarioFiltro(double? min) {
    if (_filtroSalarioMin == min) {
      _filtroSalarioMin = null;
    } else {
      _filtroSalarioMin = min;
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Carga Offline-First y Persistencia de Caché
  // ─────────────────────────────────────────────

  Future<void> _loadCache() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final cachedJson = sp.getString(_cacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decoded = jsonDecode(cachedJson) as List<dynamic>;
        final cachedVacantes = decoded
            .map((item) => VacanteModel.fromJson(item as Map<String, dynamic>).toEntity())
            .toList();
        if (cachedVacantes.isNotEmpty && vacantes.isEmpty) {
          vacantes = cachedVacantes;
          status = VacantesStatus.loaded;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> _saveCache(List<Vacante> list) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final listMap = list.map((v) => VacanteModel.fromEntity(v).toJson()).toList();
      await sp.setString(_cacheKey, jsonEncode(listMap));
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  // Cargar vacantes (Offline-First)
  // ─────────────────────────────────────────────

  Future<void> cargar({String? ubicacion, String? categoria, String? query}) async {
    _ubicacion = ubicacion;
    _categoria = categoria;
    if (query != null) _query = query;

    // 1. Carga inmediata desde caché si no hay filtros activos y la lista está vacía (0ms UI)
    if (_ubicacion == null && _categoria == null && _query.isEmpty && vacantes.isEmpty) {
      await _loadCache();
    }

    if (vacantes.isEmpty) {
      status = VacantesStatus.loading;
      error = null;
      notifyListeners();
    }

    try {
      final fresh = await _repo.listarVacantes(
        ubicacion: _ubicacion,
        categoria: _categoria,
        query: _query.isNotEmpty ? _query : null,
      );
      vacantes = fresh;
      status = VacantesStatus.loaded;
      error = null;
      isOffline = false;
      if (_ubicacion == null && _categoria == null && _query.isEmpty) {
        _saveCache(fresh);
      }
    } on ApiException catch (e) {
      if (vacantes.isEmpty) {
        error = e.message;
        status = VacantesStatus.error;
      } else {
        isOffline = true;
      }
    } catch (_) {
      if (vacantes.isEmpty) {
        error = 'Sin conexión. Verifica tu red.';
        status = VacantesStatus.error;
      } else {
        isOffline = true;
      }
    }
    notifyListeners();
  }

  Future<Vacante?> getVacanteDetalle(String id) async {
    final idx = vacantes.indexWhere((v) => v.id == id);
    if (idx != -1 &&
        vacantes[idx].requisitos.isNotEmpty &&
        vacantes[idx].descripcion.isNotEmpty) {
      return vacantes[idx];
    }
    try {
      final vacante = await _repo.getVacante(id);
      if (idx != -1) {
        vacantes[idx] = vacante;
      } else {
        vacantes.add(vacante);
      }
      notifyListeners();
      return vacante;
    } catch (_) {
      return idx != -1 ? vacantes[idx] : null;
    }
  }

  Future<bool> publicarVacante({
    required String titulo,
    required String descripcion,
    required List<String> requisitos,
    required String ubicacion,
    required String categoria,
    double? salarioMin,
    double? salarioMax,
  }) async {
    loadingPub = true;
    error = null;
    notifyListeners();

    try {
      final nuevaVacante = await _repo.publicarVacante(
        titulo: titulo,
        descripcion: descripcion,
        requisitos: requisitos,
        ubicacion: ubicacion,
        categoria: categoria,
        salarioMin: salarioMin,
        salarioMax: salarioMax,
      );
      vacantes.insert(0, nuevaVacante);
      loadingPub = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      loadingPub = false;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Sin conexión. Verifica tu red.';
      loadingPub = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarVacante(String id) async {
    try {
      await _repo.eliminarVacante(id);
      vacantes.removeWhere((v) => v.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      error = e is ApiException ? e.message : 'Error al eliminar vacante.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> destacarVacante(String id) async {
    final success = await _repo.destacarVacante(id);
    if (success) {
      final idx = vacantes.indexWhere((v) => v.id == id);
      if (idx != -1) {
        vacantes[idx] = vacantes[idx].copyWith(esDestacada: true);
        notifyListeners();
      }
    }
    return success;
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void clearQuery() {
    _query = '';
    notifyListeners();
  }
}
