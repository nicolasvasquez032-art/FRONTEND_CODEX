/// Recomendación de vacante generada por el motor semántico ML.
/// El [scoreSimilitud] viene como float 0.0–1.0 del backend.
class Recomendacion {
  final String vacanteId;
  final String titulo;
  final String empresaId;
  final double scoreSimilitud;
  final String explicacion;

  const Recomendacion({
    required this.vacanteId,
    required this.titulo,
    required this.empresaId,
    required this.scoreSimilitud,
    required this.explicacion,
  });

  /// Porcentaje de compatibilidad redondeado (0–100).
  int get scorePercent => (scoreSimilitud * 100).round();

  /// Texto de badge: "✦ 87% compatible contigo"
  String get badgeText => '✦ $scorePercent% compatible contigo';
}
