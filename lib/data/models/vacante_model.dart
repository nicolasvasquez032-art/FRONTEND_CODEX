import '../../domain/entities/vacante.dart';

/// DTO que mapea exactamente el JSON de `VacanteResponse` del backend.
class VacanteModel {
  final String id;
  final String empresaId;
  final String titulo;
  final String descripcion;
  final List<String> requisitos;
  final String ubicacion;
  final String estado;
  final String? categoria;
  final double? salarioMin;
  final double? salarioMax;
  final double? latitud;
  final double? longitud;
  final String creadoEn;
  final int totalPostulaciones;
  final bool esDestacada;

  const VacanteModel({
    required this.id,
    required this.empresaId,
    required this.titulo,
    required this.descripcion,
    required this.requisitos,
    required this.ubicacion,
    required this.estado,
    required this.creadoEn,
    this.categoria,
    this.salarioMin,
    this.salarioMax,
    this.latitud,
    this.longitud,
    this.totalPostulaciones = 0,
    this.esDestacada = false,
  });

  factory VacanteModel.fromJson(Map<String, dynamic> json) => VacanteModel(
        id: json['id'] as String,
        empresaId: json['empresa_id'] as String,
        titulo: json['titulo'] as String,
        descripcion: json['descripcion'] as String,
        requisitos: (json['requisitos'] as List<dynamic>).cast<String>(),
        ubicacion: json['ubicacion'] as String,
        estado: json['estado'] as String,
        categoria: json['categoria'] as String?,
        salarioMin: (json['salario_min'] as num?)?.toDouble(),
        salarioMax: (json['salario_max'] as num?)?.toDouble(),
        latitud: (json['latitud'] as num?)?.toDouble(),
        longitud: (json['longitud'] as num?)?.toDouble(),
        creadoEn: json['creado_en'] as String,
        totalPostulaciones: (json['total_postulaciones'] as num?)?.toInt() ?? 0,
        esDestacada: json['es_destacada'] as bool? ?? false,
      );

  factory VacanteModel.fromEntity(Vacante v) => VacanteModel(
        id: v.id,
        empresaId: v.empresaId,
        titulo: v.titulo,
        descripcion: v.descripcion,
        requisitos: v.requisitos,
        ubicacion: v.ubicacion,
        estado: v.estado.name,
        categoria: v.categoria,
        salarioMin: v.salarioMin,
        salarioMax: v.salarioMax,
        latitud: v.latitud,
        longitud: v.longitud,
        creadoEn: v.creadoEn.toIso8601String(),
        totalPostulaciones: v.totalPostulaciones,
        esDestacada: v.esDestacada,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'titulo': titulo,
        'descripcion': descripcion,
        'requisitos': requisitos,
        'ubicacion': ubicacion,
        'estado': estado,
        'categoria': categoria,
        'salario_min': salarioMin,
        'salario_max': salarioMax,
        'latitud': latitud,
        'longitud': longitud,
        'creado_en': creadoEn,
        'total_postulaciones': totalPostulaciones,
        'es_destacada': esDestacada,
      };

  /// Convierte el DTO a la entidad de dominio.
  Vacante toEntity() => Vacante(
        id: id,
        empresaId: empresaId,
        titulo: titulo,
        descripcion: descripcion,
        requisitos: requisitos,
        ubicacion: ubicacion,
        estado: _parseEstado(estado),
        categoria: categoria,
        salarioMin: salarioMin,
        salarioMax: salarioMax,
        latitud: latitud,
        longitud: longitud,
        creadoEn: DateTime.parse(creadoEn),
        totalPostulaciones: totalPostulaciones,
        esDestacada: esDestacada,
      );

  static VacanteEstado _parseEstado(String s) {
    switch (s.toLowerCase()) {
      case 'pausada':  return VacanteEstado.pausada;
      case 'cerrada':  return VacanteEstado.cerrada;
      default:         return VacanteEstado.activa;
    }
  }
}
