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
  final String? candidatoNombre;
  final String? candidatoEmail;
  final String? candidatoJobTitle;
  final List<String>? candidatoSkills;
  final int? candidatoExperienceYears;
  final String? candidatoLocation;
  final String? candidatoPhone;
  final String? candidatoUserId;
  final String? vacanteTitulo;
  final String? empresaNombre;
  final String? vacanteUbicacion;
  final String? vacanteCategoria;
  final double? vacanteSalarioMin;
  final double? vacanteSalarioMax;
  final String? vacanteDescripcion;
  final List<String>? vacanteRequisitos;

  const Postulacion({
    required this.id,
    required this.candidatoId,
    required this.vacanteId,
    required this.estado,
    required this.fecha,
    this.scoreMatch,
    this.candidatoNombre,
    this.candidatoEmail,
    this.candidatoJobTitle,
    this.candidatoSkills,
    this.candidatoExperienceYears,
    this.candidatoLocation,
    this.candidatoPhone,
    this.candidatoUserId,
    this.vacanteTitulo,
    this.empresaNombre,
    this.vacanteUbicacion,
    this.vacanteCategoria,
    this.vacanteSalarioMin,
    this.vacanteSalarioMax,
    this.vacanteDescripcion,
    this.vacanteRequisitos,
  });
}
