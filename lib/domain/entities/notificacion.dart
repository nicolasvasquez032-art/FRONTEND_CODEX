/// Entidad de dominio — Notificación del usuario
class Notificacion {
  final String id;
  final String tipo;
  final String mensaje;
  final bool leido;
  final DateTime creadoEn;

  const Notificacion({
    required this.id,
    required this.tipo,
    required this.mensaje,
    required this.leido,
    required this.creadoEn,
  });

  /// Crea una copia con campos modificados
  Notificacion copyWith({bool? leido}) => Notificacion(
        id: id,
        tipo: tipo,
        mensaje: mensaje,
        leido: leido ?? this.leido,
        creadoEn: creadoEn,
      );
}
