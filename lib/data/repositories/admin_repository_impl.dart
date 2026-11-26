import '../../core/network/api_client.dart';
import '../../domain/entities/admin_metrics.dart';
import '../../domain/entities/vacante.dart';
import '../../domain/repositories/admin_repository.dart';
import '../models/vacante_model.dart';

class AdminRepositoryImpl implements AdminRepository {
  final ApiClient _api;

  AdminRepositoryImpl(this._api);

  @override
  Future<AdminMetrics> getMetricas() async {
    // 1. Resumen general
    final resumen = await _api.get('/admin/metricas/resumen', auth: true);
    final totalCandidatos = (resumen['total_candidatos'] ?? 0) as int;
    final totalVacantesActivas = (resumen['total_vacantes_activas'] ?? 0) as int;
    final totalPostulaciones = (resumen['total_postulaciones'] ?? 0) as int;

    // 2. Sectores demanda
    List<SectorDemanda> sectores = [];
    try {
      final sectoresRaw = await _api.getList('/admin/metricas/sectores-demanda', auth: true, queryParams: {'limite': '6'});
      sectores = sectoresRaw
          .map((item) => SectorDemanda.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Graceful fallback si la tabla no tiene categorías suficientes
    }

    // 3. Tiempo de contratación
    double? tiempoPromedio;
    try {
      final tiempoRaw = await _api.get('/admin/metricas/tiempo-contratacion', auth: true);
      if (tiempoRaw['tiempo_promedio_dias'] != null) {
        tiempoPromedio = (tiempoRaw['tiempo_promedio_dias'] as num).toDouble();
      }
    } catch (_) {}

    // 4. Efectividad recomendación IA
    double? efectividad;
    try {
      final efectividadRaw = await _api.get('/admin/metricas/efectividad-recomendacion', auth: true);
      if (efectividadRaw['efectividad_porcentaje'] != null) {
        efectividad = (efectividadRaw['efectividad_porcentaje'] as num).toDouble();
      }
    } catch (_) {}

    return AdminMetrics(
      totalCandidatos: totalCandidatos,
      totalVacantesActivas: totalVacantesActivas,
      totalPostulaciones: totalPostulaciones,
      tiempoPromedioDias: tiempoPromedio,
      efectividadPorcentaje: efectividad,
      sectoresDemanda: sectores,
    );
  }

  @override
  Future<List<Vacante>> getTodasVacantes() async {
    const pageSize = 100;
    final vacantes = <String, Vacante>{};
    var offset = 0;
    while (true) {
      final page = await _api.getList(
        '/admin/vacantes',
        auth: true,
        queryParams: {'offset': '$offset', 'limit': '$pageSize'},
      );
      for (final item in page) {
        final vacante = VacanteModel.fromJson(item as Map<String, dynamic>).toEntity();
        vacantes[vacante.id] = vacante;
      }
      if (page.length < pageSize) return vacantes.values.toList();
      offset += page.length;
    }
  }

  @override
  Future<Vacante> moderarVacante(String vacanteId, String nuevoEstado) async {
    final raw = await _api.patch(
      '/admin/vacantes/$vacanteId/estado',
      {'estado': nuevoEstado},
    );
    return VacanteModel.fromJson(raw).toEntity();
  }
}
