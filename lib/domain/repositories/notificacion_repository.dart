import '../entities/notificacion.dart';

/// Contrato abstracto para el repositorio de notificaciones
abstract class NotificacionRepository {
  /// Obtiene las notificaciones del usuario
  Future<List<Notificacion>> getNotificaciones(
    String usuarioId, {
    int limit = 50,
    int offset = 0,
  });

  /// Marca una notificación como leída
  Future<void> marcarLeida(String notificacionId);

  /// Registra un token FCM del dispositivo
  Future<void> registrarToken(String token, {String? dispositivoInfo});
}
