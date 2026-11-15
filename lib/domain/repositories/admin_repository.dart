import '../entities/admin_metrics.dart';
import '../entities/vacante.dart';

abstract class AdminRepository {
  Future<AdminMetrics> getMetricas();
  Future<List<Vacante>> getTodasVacantes();
  Future<Vacante> moderarVacante(String vacanteId, String nuevoEstado);
}
