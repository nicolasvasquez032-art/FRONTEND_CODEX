import '../../../domain/entities/recomendacion.dart';
import '../../../domain/entities/vacante.dart';

/// Modelo de presentación para renderizar vacantes en la pantalla principal (Home),
/// alineado con el diseño de Figma y unificando vacantes del backend y recomendaciones IA.
class DisplayJob {
  final String id;
  final String title;
  final String company;
  final String initialLetter;
  final String location;
  final String category;
  final int matchScore;
  final String timeAgo;
  final String salary;
  final Vacante vacante;
  final Recomendacion? recomendacion;

  const DisplayJob({
    required this.id,
    required this.title,
    required this.company,
    required this.initialLetter,
    required this.location,
    required this.category,
    required this.matchScore,
    required this.timeAgo,
    required this.salary,
    required this.vacante,
    this.recomendacion,
  });

  factory DisplayJob.fromVacante({
    required Vacante v,
    required bool isEs,
    int customMatch = 85,
    Recomendacion? rec,
  }) {
    // Determina inicial para el avatar
    String initial = 'R';
    if (v.titulo.trim().isNotEmpty) {
      initial = v.titulo.trim()[0].toUpperCase();
    }

    // Modalidad / Ubicación
    String loc = v.ubicacionLocalized(isEs);
    if (loc.isEmpty) {
      loc = isEs ? 'Remoto' : 'Remote';
    }

    // Categoría
    String cat = v.categoriaLocalized(isEs) ?? v.categoria ?? 'Backend';
    if (cat.isEmpty) cat = 'Backend';

    // Salario adaptativo
    String sal = v.salarioDisplayLocalized(isEs);
    if (sal.contains('convenir') || sal.contains('negotiable')) {
      sal = isEs ? '\$ 3.000 – \$ 5.000 COP' : '\$3,000 – \$5,000 USD';
    }

    return DisplayJob(
      id: v.id,
      title: v.tituloLocalized(isEs),
      company: isEs ? 'Empresa Confidencial' : 'Confidential Company',
      initialLetter: initial,
      location: loc,
      category: cat,
      matchScore: customMatch,
      timeAgo: v.tiempoRelativoLocalized(isEs),
      salary: sal,
      vacante: v,
      recomendacion: rec,
    );
  }

  /// Vacantes iniciales de demostración idénticas a Figma para usuarios sin sesión o pruebas.
  static List<DisplayJob> getFigmaDefaults(bool isEs) {
    return [
      DisplayJob(
        id: 'figma-1',
        title: isEs
            ? 'Desarrollador Python Senior'
            : 'Senior Python Developer',
        company: isEs ? 'Empresa Confidencial' : 'Confidential Company',
        initialLetter: 'R',
        location: isEs ? 'Remoto' : 'Remote',
        category: 'Backend',
        matchScore: 98,
        timeAgo: isEs ? 'Hace 23 h' : '23h ago',
        salary: '\$ 3.000 – \$ 5.000 COP',
        vacante: Vacante(
          id: 'figma-1',
          empresaId: 'confidencial',
          titulo: 'Desarrollador Python Senior',
          descripcion:
              'Buscamos Desarrollador Python Senior con experiencia en FastAPI, Django y microservicios.',
          requisitos: const ['Python', 'FastAPI', 'PostgreSQL', 'Docker'],
          ubicacion: 'Remoto',
          categoria: 'Backend',
          estado: VacanteEstado.activa,
          creadoEn: DateTime.now().subtract(const Duration(hours: 23)),
          salarioMin: 3000,
          salarioMax: 5000,
        ),
      ),
      DisplayJob(
        id: 'figma-2',
        title: isEs
            ? 'Desarrollador Python Junior'
            : 'Junior Python Developer',
        company: isEs ? 'Empresa Confidencial' : 'Confidential Company',
        initialLetter: 'R',
        location: isEs ? 'Remoto' : 'Remote',
        category: 'Backend',
        matchScore: 94,
        timeAgo: isEs ? 'Hace 1 día' : '1d ago',
        salary: '\$ 1.500 – \$ 2.500 COP',
        vacante: Vacante(
          id: 'figma-2',
          empresaId: 'confidencial',
          titulo: 'Desarrollador Python Junior',
          descripcion:
              'Oportunidad para Desarrollador Python Junior con ganas de aprender en equipo ágil.',
          requisitos: const ['Python', 'Git', 'SQL básico'],
          ubicacion: 'Remoto',
          categoria: 'Backend',
          estado: VacanteEstado.activa,
          creadoEn: DateTime.now().subtract(const Duration(days: 1)),
          salarioMin: 1500,
          salarioMax: 2500,
        ),
      ),
    ];
  }
}
