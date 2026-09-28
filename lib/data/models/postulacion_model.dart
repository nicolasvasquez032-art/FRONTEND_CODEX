import '../../domain/entities/postulacion.dart';

/// DTO que mapea exactamente el JSON de `PostulacionResponse` del backend.
class PostulacionModel {
  final String id;
  final String candidatoId;
  final String vacanteId;
  final String estado;
  final String fecha;
  final double? scoreMatch;

  const PostulacionModel({
    required this.id,
    required this.candidatoId,
    required this.vacanteId,
    required this.estado,
    required this.fecha,
    this.scoreMatch,
  });

  factory PostulacionModel.fromJson(Map<String, dynamic> json) =>
      PostulacionModel(
        id: json['id'] as String,
        candidatoId: json['candidato_id'] as String,
        vacanteId: json['vacante_id'] as String,
        estado: json['estado'] as String,
        fecha: json['fecha'] as String,
        scoreMatch: (json['score_match'] as num?)?.toDouble(),
      );

  /// Convierte el DTO a la entidad de dominio.
  Postulacion toEntity() => Postulacion(
        id: id,
        candidatoId: candidatoId,
        vacanteId: vacanteId,
        estado: _parseEstado(estado),
        fecha: DateTime.parse(fecha),
        scoreMatch: scoreMatch,
      );

  static PostulacionEstado _parseEstado(String s) {
    switch (s.toLowerCase()) {
      case 'entrevista': return PostulacionEstado.entrevista;
      case 'rechazado':  return PostulacionEstado.rechazado;
      case 'contratado': return PostulacionEstado.contratado;
      default:           return PostulacionEstado.postulado;
    }
  }
}
