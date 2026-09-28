import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
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
  // Cargar postulaciones del candidato
  // ─────────────────────────────────────────────

  Future<void> cargar(String candidatoId) async {
    status = PostulacionesStatus.loading;
    error = null;
    notifyListeners();

    try {
      postulaciones = await _repo.listarMisPostulaciones(candidatoId);
      _byVacante
        ..clear()
        ..addEntries(postulaciones.map((p) => MapEntry(p.vacanteId, p)));
      status = PostulacionesStatus.loaded;
    } on ApiException catch (e) {
      error = e.message;
      status = PostulacionesStatus.error;
    } catch (_) {
      error = 'Sin conexión. Verifica tu red.';
      status = PostulacionesStatus.error;
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Postularse a una vacante
  // ─────────────────────────────────────────────

  /// Retorna `true` si fue exitoso, `false` si ya estaba postulado o error.
  Future<bool> postularse({
    required String candidatoId,
    required String vacanteId,
  }) async {
    if (yaPostulado(vacanteId)) return false;

    try {
      final p = await _repo.postularse(
        candidatoId: candidatoId,
        vacanteId: vacanteId,
      );
      postulaciones.add(p);
      _byVacante[vacanteId] = p;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Sin conexión. Verifica tu red.';
      notifyListeners();
      return false;
    }
  }
}
