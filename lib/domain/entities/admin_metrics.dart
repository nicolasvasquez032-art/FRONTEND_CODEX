class SectorDemanda {
  final String categoria;
  final int totalVacantes;

  const SectorDemanda({
    required this.categoria,
    required this.totalVacantes,
  });

  factory SectorDemanda.fromJson(Map<String, dynamic> json) {
    return SectorDemanda(
      categoria: (json['categoria'] ?? json['sector'] ?? 'General').toString(),
      totalVacantes: (json['total_vacantes'] ?? json['total'] ?? 0) as int,
    );
  }
}

class AdminMetrics {
  final int totalCandidatos;
  final int totalVacantesActivas;
  final int totalPostulaciones;
  final double? tiempoPromedioDias;
  final double? efectividadPorcentaje;
  final List<SectorDemanda> sectoresDemanda;

  const AdminMetrics({
    required this.totalCandidatos,
    required this.totalVacantesActivas,
    required this.totalPostulaciones,
    this.tiempoPromedioDias,
    this.efectividadPorcentaje,
    this.sectoresDemanda = const [],
  });

  AdminMetrics copyWith({
    int? totalCandidatos,
    int? totalVacantesActivas,
    int? totalPostulaciones,
    double? tiempoPromedioDias,
    double? efectividadPorcentaje,
    List<SectorDemanda>? sectoresDemanda,
  }) {
    return AdminMetrics(
      totalCandidatos: totalCandidatos ?? this.totalCandidatos,
      totalVacantesActivas: totalVacantesActivas ?? this.totalVacantesActivas,
      totalPostulaciones: totalPostulaciones ?? this.totalPostulaciones,
      tiempoPromedioDias: tiempoPromedioDias ?? this.tiempoPromedioDias,
      efectividadPorcentaje: efectividadPorcentaje ?? this.efectividadPorcentaje,
      sectoresDemanda: sectoresDemanda ?? this.sectoresDemanda,
    );
  }
}
