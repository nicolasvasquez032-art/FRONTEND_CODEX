import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../domain/entities/recomendacion.dart';
import '../../../domain/repositories/recomendacion_repository.dart';

enum RecomendacionesStatus { initial, loading, loaded, error, fallback }

/// Provider que gestiona las recomendaciones del motor semántico ML.
///
/// Si el ML no responde (timeout, 500, sin red), el status pasa a
/// [RecomendacionesStatus.fallback] y el HomeScreen cae al listado general
/// de vacantes ya cargado por [VacantesProvider].
class RecomendacionesProvider extends ChangeNotifier {
  final RecomendacionRepository _repo;

  RecomendacionesProvider(this._repo);

  RecomendacionesStatus status = RecomendacionesStatus.initial;
  List<Recomendacion> recomendaciones = [];
  String? error;

  // ──────────────────────────────────────────────
  // Cargar recomendaciones
  // ──────────────────────────────────────────────

  Future<void> cargar(String candidatoId) async {
    if (status == RecomendacionesStatus.loading) return;
    status = RecomendacionesStatus.loading;
    error  = null;
    notifyListeners();

    try {
      recomendaciones = await _repo.getRecomendaciones(candidatoId);
      status = RecomendacionesStatus.loaded;
    } on ApiException catch (e) {
      // 401 → sesión expirada (el AuthProvider lo manejará en la UI)
      // 404 → sin perfil aún → fallback
      // 500 / otro → ML no disponible → fallback
      error  = e.message;
      status = RecomendacionesStatus.fallback;
    } catch (_) {
      // Timeout o sin red → fallback al listado general
      error  = 'El motor IA no está disponible. Mostrando vacantes generales.';
      status = RecomendacionesStatus.fallback;
    }
    notifyListeners();
  }

  /// Las 4 mejores recomendaciones para mostrar en el Home.
  List<Recomendacion> get top4 => recomendaciones.take(4).toList();

  bool get hasData =>
      status == RecomendacionesStatus.loaded && recomendaciones.isNotEmpty;

  bool get isFallback => status == RecomendacionesStatus.fallback;
}
