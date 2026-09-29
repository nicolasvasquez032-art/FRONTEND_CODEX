import '../entities/recomendacion.dart';

/// Contrato para obtener recomendaciones del motor semántico ML.
abstract class RecomendacionRepository {
  /// Obtiene la lista de vacantes recomendadas para un candidato
  /// via GET /recomendaciones/candidato/{candidatoId}.
  Future<List<Recomendacion>> getRecomendaciones(String candidatoId);
}
