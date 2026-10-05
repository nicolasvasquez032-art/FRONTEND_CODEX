import '../../core/network/api_client.dart';
import '../../domain/entities/postulacion.dart';
import '../../domain/repositories/postulacion_repository.dart';
import '../models/postulacion_model.dart';

class PostulacionRepositoryImpl implements PostulacionRepository {
  final ApiClient _api;

  PostulacionRepositoryImpl(this._api);

  @override
  Future<Postulacion> postularse({
    required String candidatoId,  // Ya no se envía al backend; el JWT lo resuelve
    required String vacanteId,
  }) async {
    final raw = await _api.post(
      '/postulaciones',
      {
        'vacante_id': vacanteId,  // candidato_id se extrae del JWT en el backend
      },
      auth: true,
    );
    return PostulacionModel.fromJson(raw).toEntity();
  }

  @override
  Future<List<Postulacion>> listarMisPostulaciones(String candidatoId) async {
    final raw = await _api.getList(
      '/postulaciones/candidato/$candidatoId',
      auth: true,
    );
    return raw
        .map((e) =>
            PostulacionModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  @override
  Future<void> cancelarPostulacion(String postulacionId) async {
    await _api.delete(
      '/postulaciones/$postulacionId',
      auth: true,
    );
  }
}
