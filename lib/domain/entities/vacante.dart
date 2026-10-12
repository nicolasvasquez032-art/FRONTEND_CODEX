import '../../core/utils/format_helper.dart';
import '../../core/utils/job_translation_helper.dart';

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

  /// Descripción del rango salarial formateada de forma adaptativa (intl).
  /// En español: $ 4.500 – $ 7.000 COP
  /// En inglés:  $4,500 – $7,000 USD
  String salarioDisplayLocalized(bool isSpanish) {
    return FormatHelper.formatSalaryRange(
      min: salarioMin,
      max: salarioMax,
      isSpanish: isSpanish,
      contextText: descripcion,
    );
  }

  String get salarioDisplay => salarioDisplayLocalized(true);

  /// Tiempo relativo y fecha adaptativa desde la creación (intl).
  /// En español: 12 de oct. / Hace 3 días
  /// En inglés:  Oct 12 / 3d ago
  String tiempoRelativoLocalized(bool isSpanish) {
    return FormatHelper.formatRelativeTime(creadoEn, isSpanish: isSpanish);
  }

  /// Fecha de publicación formateada (corta o completa).
  String fechaPublicacionLocalized(bool isSpanish, {bool full = false}) {
    return FormatHelper.formatDate(creadoEn, isSpanish: isSpanish, full: full);
  }

  String get tiempoRelativo => tiempoRelativoLocalized(true);

  // ── Localización dinámica de contenido ─────────────────────────
  String tituloLocalized(bool isSpanish) =>
      JobTranslationHelper.translateTitle(titulo, isSpanish);

  String? categoriaLocalized(bool isSpanish) =>
      JobTranslationHelper.translateCategory(categoria, isSpanish);

  String descripcionLocalized(bool isSpanish) =>
      JobTranslationHelper.translateDescription(descripcion, isSpanish);

  List<String> requisitosLocalized(bool isSpanish) =>
      JobTranslationHelper.translateRequirements(requisitos, isSpanish);

  String ubicacionLocalized(bool isSpanish) =>
      JobTranslationHelper.translateLocation(ubicacion, isSpanish);
}
