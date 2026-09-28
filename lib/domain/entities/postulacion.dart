/// Estado de la postulación — espeja el backend enum PostulacionEstado.
enum PostulacionEstado { postulado, entrevista, rechazado, contratado }

extension PostulacionEstadoX on PostulacionEstado {
  String get label {
    switch (this) {
      case PostulacionEstado.postulado:  return 'Postulado';
      case PostulacionEstado.entrevista: return 'En entrevista';
      case PostulacionEstado.rechazado:  return 'Rechazado';
      case PostulacionEstado.contratado: return 'Contratado';
    }
  }
}

/// Entidad de dominio — no importa nada de infraestructura.
class Postulacion {
  final String id;
  final String candidatoId;
  final String vacanteId;
  final PostulacionEstado estado;
  final DateTime fecha;
  final double? scoreMatch;

  const Postulacion({
    required this.id,
    required this.candidatoId,
    required this.vacanteId,
    required this.estado,
    required this.fecha,
    this.scoreMatch,
  });
}
