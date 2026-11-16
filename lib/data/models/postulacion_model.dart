import '../../domain/entities/postulacion.dart';

/// DTO que mapea exactamente el JSON de `PostulacionResponse` del backend.
class PostulacionModel {
  final String id;
  final String candidatoId;
  final String vacanteId;
  final String estado;
  final String fecha;
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
  final String? candidatoCvUrl;
  final String? candidatoCvText;

  const PostulacionModel({
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
    this.candidatoCvUrl,
    this.candidatoCvText,
  });

  factory PostulacionModel.fromJson(Map<String, dynamic> json) =>
      PostulacionModel(
        id: json['id'] as String,
        candidatoId: json['candidato_id'] as String,
        vacanteId: json['vacante_id'] as String,
        estado: json['estado'] as String,
        fecha: json['fecha'] as String,
        scoreMatch: (json['score_match'] as num?)?.toDouble(),
        candidatoNombre: json['candidato_nombre'] as String?,
        candidatoEmail: json['candidato_email'] as String?,
        candidatoJobTitle: json['candidato_job_title'] as String?,
        candidatoSkills: (json['candidato_skills'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        candidatoExperienceYears: json['candidato_experience_years'] as int?,
        candidatoLocation: json['candidato_location'] as String?,
        candidatoPhone: json['candidato_phone'] as String?,
        candidatoUserId: json['candidato_user_id'] as String?,
        vacanteTitulo: json['vacante_titulo'] as String?,
        empresaNombre: json['empresa_nombre'] as String?,
        vacanteUbicacion: json['vacante_ubicacion'] as String?,
        vacanteCategoria: json['vacante_categoria'] as String?,
        vacanteSalarioMin: (json['vacante_salario_min'] as num?)?.toDouble(),
        vacanteSalarioMax: (json['vacante_salario_max'] as num?)?.toDouble(),
        vacanteDescripcion: json['vacante_descripcion'] as String?,
        vacanteRequisitos: (json['vacante_requisitos'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        candidatoCvUrl: json['candidato_cv_url'] as String?,
        candidatoCvText: json['candidato_cv_text'] as String?,
      );

  factory PostulacionModel.fromEntity(Postulacion p) => PostulacionModel(
        id: p.id,
        candidatoId: p.candidatoId,
        vacanteId: p.vacanteId,
        estado: p.estado.name,
        fecha: p.fecha.toIso8601String(),
        scoreMatch: p.scoreMatch,
        candidatoNombre: p.candidatoNombre,
        candidatoEmail: p.candidatoEmail,
        candidatoJobTitle: p.candidatoJobTitle,
        candidatoSkills: p.candidatoSkills,
        candidatoExperienceYears: p.candidatoExperienceYears,
        candidatoLocation: p.candidatoLocation,
        candidatoPhone: p.candidatoPhone,
        candidatoUserId: p.candidatoUserId,
        vacanteTitulo: p.vacanteTitulo,
        empresaNombre: p.empresaNombre,
        vacanteUbicacion: p.vacanteUbicacion,
        vacanteCategoria: p.vacanteCategoria,
        vacanteSalarioMin: p.vacanteSalarioMin,
        vacanteSalarioMax: p.vacanteSalarioMax,
        vacanteDescripcion: p.vacanteDescripcion,
        vacanteRequisitos: p.vacanteRequisitos,
        candidatoCvUrl: p.candidatoCvUrl,
        candidatoCvText: p.candidatoCvText,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'candidato_id': candidatoId,
        'vacante_id': vacanteId,
        'estado': estado,
        'fecha': fecha,
        'score_match': scoreMatch,
        'candidato_nombre': candidatoNombre,
        'candidato_email': candidatoEmail,
        'candidato_job_title': candidatoJobTitle,
        'candidato_skills': candidatoSkills,
        'candidato_experience_years': candidatoExperienceYears,
        'candidato_location': candidatoLocation,
        'candidato_phone': candidatoPhone,
        'candidato_user_id': candidatoUserId,
        'vacante_titulo': vacanteTitulo,
        'empresa_nombre': empresaNombre,
        'vacante_ubicacion': vacanteUbicacion,
        'vacante_categoria': vacanteCategoria,
        'vacante_salario_min': vacanteSalarioMin,
        'vacante_salario_max': vacanteSalarioMax,
        'vacante_descripcion': vacanteDescripcion,
        'vacante_requisitos': vacanteRequisitos,
        'candidato_cv_url': candidatoCvUrl,
        'candidato_cv_text': candidatoCvText,
      };

  /// Convierte el DTO a la entidad de dominio.
  Postulacion toEntity() => Postulacion(
        id: id,
        candidatoId: candidatoId,
        vacanteId: vacanteId,
        estado: _parseEstado(estado),
        fecha: DateTime.parse(fecha),
        scoreMatch: scoreMatch,
        candidatoNombre: candidatoNombre,
        candidatoEmail: candidatoEmail,
        candidatoJobTitle: candidatoJobTitle,
        candidatoSkills: candidatoSkills,
        candidatoExperienceYears: candidatoExperienceYears,
        candidatoLocation: candidatoLocation,
        candidatoPhone: candidatoPhone,
        candidatoUserId: candidatoUserId,
        vacanteTitulo: vacanteTitulo,
        empresaNombre: empresaNombre,
        vacanteUbicacion: vacanteUbicacion,
        vacanteCategoria: vacanteCategoria,
        vacanteSalarioMin: vacanteSalarioMin,
        vacanteSalarioMax: vacanteSalarioMax,
        vacanteDescripcion: vacanteDescripcion,
        vacanteRequisitos: vacanteRequisitos,
        candidatoCvUrl: candidatoCvUrl,
        candidatoCvText: candidatoCvText,
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
