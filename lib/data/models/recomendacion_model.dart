import '../../domain/entities/recomendacion.dart';

/// DTO que mapea la respuesta JSON de
/// GET /recomendaciones/candidato/{candidatoId}.
///
/// Respuesta del backend:
/// ```json
/// [{
///   "vacante_id": "uuid",
///   "titulo": "string",
///   "empresa_id": "uuid",
///   "score_similitud": 0.94,
///   "explicacion": "Habilidades coincidentes: Python, análisis de datos"
/// }]
/// ```
class RecomendacionModel extends Recomendacion {
  RecomendacionModel({
    required super.vacanteId,
    required super.titulo,
    required super.empresaId,
    required super.scoreSimilitud,
    required super.explicacion,
    super.descripcion,
    super.requisitos,
    super.ubicacion,
    super.categoria,
    super.salarioMin,
    super.salarioMax,
  });

  factory RecomendacionModel.fromJson(Map<String, dynamic> json) =>
      RecomendacionModel(
        vacanteId: json['vacante_id'] as String,
        titulo: json['titulo'] as String,
        empresaId: json['empresa_id'] as String,
        scoreSimilitud: (json['score_similitud'] as num).toDouble(),
        explicacion: json['explicacion'] as String,
        descripcion: json['descripcion'] as String?,
        requisitos: (json['requisitos'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        ubicacion: json['ubicacion'] as String?,
        categoria: json['categoria'] as String?,
        salarioMin: (json['salario_min'] as num?)?.toDouble(),
        salarioMax: (json['salario_max'] as num?)?.toDouble(),
      );
}
