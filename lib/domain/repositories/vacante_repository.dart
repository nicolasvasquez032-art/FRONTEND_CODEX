import '../entities/vacante.dart';

/// Contrato de vacantes que la capa de presentación conoce.
/// La implementación concreta vive en data/repositories/.
abstract class VacanteRepository {
  /// Lista vacantes activas. Soporta filtros opcionales.
  Future<List<Vacante>> listarVacantes({
    String? ubicacion,
    String? categoria,
  });

  /// Obtiene una vacante por su ID.
  Future<Vacante> getVacante(String id);

  /// Publica una nueva vacante. Requiere sesión de empresa.
  Future<Vacante> publicarVacante({
    required String titulo,
    required String descripcion,
    required List<String> requisitos,
    required String ubicacion,
    required String categoria,
    double? salarioMin,
    double? salarioMax,
    double? latitud,
    double? longitud,
  });
}
