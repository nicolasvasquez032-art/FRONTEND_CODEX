/// Estado de la vacante — espeja el backend enum VacanteEstado.
enum VacanteEstado { activa, pausada, cerrada }

/// Entidad de dominio — no importa nada de infraestructura.
class Vacante {
  final String id;
  final String empresaId;
  final String titulo;
  final String descripcion;
  final List<String> requisitos;
  final String ubicacion;
  final VacanteEstado estado;
  final String? categoria;
  final double? salarioMin;
  final double? salarioMax;
  final double? latitud;
  final double? longitud;
  final DateTime creadoEn;

  const Vacante({
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
  });

  /// Descripción del rango salarial formateada.
  String get salarioDisplay {
    if (salarioMin == null && salarioMax == null) return 'Salario no indicado';
    if (salarioMin != null && salarioMax != null) {
      return '\$${salarioMin!.toStringAsFixed(0)} – \$${salarioMax!.toStringAsFixed(0)}';
    }
    if (salarioMin != null) return 'Desde \$${salarioMin!.toStringAsFixed(0)}';
    return 'Hasta \$${salarioMax!.toStringAsFixed(0)}';
  }

  /// Tiempo relativo desde la creación.
  String get tiempoRelativo {
    final diff = DateTime.now().difference(creadoEn);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    return 'Hace ${diff.inDays} días';
  }
}
