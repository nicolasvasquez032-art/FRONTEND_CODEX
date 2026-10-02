import '../../domain/entities/notificacion.dart';

/// DTO — mapea exactamente la respuesta del backend
/// GET /notificaciones/usuario/{usuario_id}
/// [{id, tipo, mensaje, leido, creado_en}]
class NotificacionModel {
  final String id;
  final String tipo;
  final String mensaje;
  final bool leido;
  final DateTime creadoEn;

  const NotificacionModel({
    required this.id,
    required this.tipo,
    required this.mensaje,
    required this.leido,
    required this.creadoEn,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) =>
      NotificacionModel(
        id: json['id'] as String,
        tipo: json['tipo'] as String? ?? 'general',
        mensaje: json['mensaje'] as String? ?? '',
        leido: json['leido'] as bool? ?? false,
        creadoEn: DateTime.tryParse(json['creado_en'] as String? ?? '') ??
            DateTime.now(),
      );

  Notificacion toEntity() => Notificacion(
        id: id,
        tipo: tipo,
        mensaje: mensaje,
        leido: leido,
        creadoEn: creadoEn,
      );
}
