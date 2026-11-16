import '../entities/postulacion.dart';

/// Contrato de postulaciones que la capa de presentación conoce.
/// La implementación concreta vive en data/repositories/.
abstract class PostulacionRepository {
  /// Crea una nueva postulación.
  Future<Postulacion> postularse({
    required String candidatoId,
    required String vacanteId,
  });

  /// Lista las postulaciones del candidato autenticado.
  Future<List<Postulacion>> listarMisPostulaciones(String candidatoId);

  /// Lista las postulaciones de una vacante para la empresa.
  Future<List<Postulacion>> listarPostulacionesVacante(String vacanteId);

  /// Elimina (cancela) una postulación existente.
  Future<void> cancelarPostulacion(String postulacionId);
}
