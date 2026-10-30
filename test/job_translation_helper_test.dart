import 'package:flutter_test/flutter_test.dart';
import 'package:talentmatch/core/utils/job_translation_helper.dart';

void main() {
  group('JobTranslationHelper Tests', () {
    test('translateCategory traduce correctamente a inglés y preserva español', () {
      expect(JobTranslationHelper.translateCategory('Tecnología', true), 'Tecnología');
      expect(JobTranslationHelper.translateCategory('Tecnología', false), 'Technology');
      expect(JobTranslationHelper.translateCategory('ingeniería de software', false), 'Software Engineering');
      expect(JobTranslationHelper.translateCategory(null, false), isNull);
      expect(JobTranslationHelper.translateCategory('', false), '');
      expect(JobTranslationHelper.translateCategory('Desconocida', false), 'Desconocida');
    });

    test('translateTitle traduce títulos comunes y preserva desconocidos', () {
      expect(JobTranslationHelper.translateTitle('Desarrollador Backend', true), 'Desarrollador Backend');
      expect(JobTranslationHelper.translateTitle('Desarrollador Backend', false), 'Backend Developer');
      expect(JobTranslationHelper.translateTitle('desarrollador flutter senior', false), 'Senior Flutter Developer');
      expect(JobTranslationHelper.translateTitle('', false), '');
      expect(JobTranslationHelper.translateTitle('Rol Custom', false), 'Rol Custom');
      expect(JobTranslationHelper.translateTitle('Ingeniero de Inteligencia Artificial', false), 'Artificial Intelligence Engineer');
      expect(JobTranslationHelper.translateTitle('Desarrollador de Software', false), 'Software Developer');
      expect(JobTranslationHelper.translateTitle('Diseñadora', false), 'Designer');
    });

    test('translateLocation maneja ciudades colombianas y remoto', () {
      expect(JobTranslationHelper.translateLocation('Bogotá, Colombia', true), 'Bogotá, Colombia');
      expect(JobTranslationHelper.translateLocation('Bogotá, Colombia', false), 'Bogota, Colombia');
      expect(JobTranslationHelper.translateLocation('Remoto', false), 'Remote');
      expect(JobTranslationHelper.translateLocation('Híbrido', false), 'Hybrid');
      expect(JobTranslationHelper.translateLocation('Presencial', false), 'On-site');
      expect(JobTranslationHelper.translateLocation('Medellín, Antioquia', false), 'Medellin, Colombia');
      expect(JobTranslationHelper.translateLocation('', false), '');
    });

    test('translateRequirements traduce listas de requisitos técnicos', () {
      final reqsEs = [
        'Trabajo en equipo',
        'Experiencia de 3 años',
        'Conocimientos en Python',
        'Manejo de Docker',
        'Habilidad inventada',
      ];
      final reqsEn = JobTranslationHelper.translateRequirements(reqsEs, false);

      expect(reqsEn.length, 5);
      expect(reqsEn[0], 'Teamwork');
      expect(reqsEn[1], '3 years of experience');
      expect(reqsEn[2], 'Knowledge of Python');
      expect(reqsEn[3], 'Proficiency in Docker');
      expect(reqsEn[4], 'Habilidad inventada');
      expect(JobTranslationHelper.translateRequirements(reqsEs, true), reqsEs);
      expect(JobTranslationHelper.translateRequirements([], false), isEmpty);
    });

    test('translateDescription traduce descripciones predeterminadas', () {
      expect(JobTranslationHelper.translateDescription('', false), '');
      expect(JobTranslationHelper.translateDescription('Texto español', true), 'Texto español');
      expect(
        JobTranslationHelper.translateDescription(
          'Buscamos un desarrollador experto en Python y bases de datos para unirse a nuestro equipo. El candidato ideal tiene experiencia con Fastapi.',
          false,
        ),
        'We are looking for an expert Python and database developer to join our team. The ideal candidate has experience with FastAPI.',
      );
      expect(
        JobTranslationHelper.translateDescription(
          'Asegúrate de que nuestra aplicación genere un WOW en los usuarios con diseños fluidos y estéticos.',
          false,
        ),
        'Ensure our application generates a WOW effect for users with fluid and aesthetic designs.',
      );
      expect(
        JobTranslationHelper.translateDescription(
          'Descripción del trabajo: Buscamos un desarrollador para unirse a nuestro equipo en tiempo récord.',
          false,
        ),
        contains('Job Description: We are looking for a developer to join our team in record time.'),
      );
    });

    test('translateExplanation traduce mensajes y prefijos de IA', () {
      expect(JobTranslationHelper.translateExplanation('', false), '');
      expect(JobTranslationHelper.translateExplanation('Explicación original', true), 'Explicación original');
      expect(
        JobTranslationHelper.translateExplanation(
          'Habilidades coincidentes: Python, Flutter',
          false,
        ),
        'Matching skills: Python, Flutter',
      );
      expect(
        JobTranslationHelper.translateExplanation(
          'Alta compatibilidad con tu perfil y experiencia.',
          false,
        ),
        contains('High match with your profile'),
      );
      expect(
        JobTranslationHelper.translateExplanation(
          'Perfil recomendado por afinidad técnica en IA y ML',
          false,
        ),
        'Recommended profile based on technical affinity in AI & ML',
      );
    });
  });
}
