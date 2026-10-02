import '../../core/network/api_client.dart';
import '../../domain/entities/notificacion.dart';
import '../../domain/repositories/notificacion_repository.dart';
import '../models/notificacion_model.dart';

class NotificacionRepositoryImpl implements NotificacionRepository {
  final ApiClient _apiClient;

  NotificacionRepositoryImpl(this._apiClient);

  @override
  Future<List<Notificacion>> getNotificaciones(
    String usuarioId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _apiClient.getList(
      '/notificaciones/usuario/$usuarioId',
      queryParams: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );

    return response
        .map((e) => NotificacionModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  @override
  Future<void> marcarLeida(String notificacionId) async {
    await _apiClient.patch('/notificaciones/$notificacionId/leida', {});
  }

  @override
  Future<void> registrarToken(String token, {String? dispositivoInfo}) async {
    final body = <String, dynamic>{'token': token};
    if (dispositivoInfo != null) {
      body['dispositivo_info'] = dispositivoInfo;
    }
    await _apiClient.post('/notificaciones/token-dispositivo', body);
  }
}
