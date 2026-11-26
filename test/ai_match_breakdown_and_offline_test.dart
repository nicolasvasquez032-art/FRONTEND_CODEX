import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talentmatch/core/network/api_client.dart';
import 'package:talentmatch/domain/entities/profile.dart';
import 'package:talentmatch/domain/entities/postulacion.dart';
import 'package:talentmatch/domain/entities/recomendacion.dart';
import 'package:talentmatch/domain/entities/vacante.dart';
import 'package:talentmatch/domain/repositories/vacante_repository.dart';
import 'package:talentmatch/domain/repositories/postulacion_repository.dart';
import 'package:talentmatch/presentation/job_detail/widgets/match_breakdown_card.dart';
import 'package:talentmatch/presentation/profile/widgets/cv_skills_extraction_sheet.dart';
import 'package:talentmatch/presentation/shared/providers/vacantes_provider.dart';
import 'package:talentmatch/presentation/shared/providers/postulaciones_provider.dart';

class _MockVacanteRepo implements VacanteRepository {
  List<Vacante> vacantesToReturn = [];
  bool throwError = false;

  @override
  Future<List<Vacante>> listarVacantes({String? ubicacion, String? categoria, String? query, int offset = 0, int limit = 20}) async {
    if (throwError) throw Exception('No network');
    return vacantesToReturn;
  }

  @override
  Future<bool> destacarVacante(String vacanteId) async => true;

  @override
  Future<Vacante> getVacante(String id) async => vacantesToReturn.first;

  @override
  Future<Vacante> publicarVacante({
    required String titulo,
    required String descripcion,
    required List<String> requisitos,
    required String ubicacion,
    required String categoria,
    double? salarioMin,
    double? salarioMax,
    double? latitud,
    double? longitud,
  }) async => vacantesToReturn.first;

  @override
  Future<void> eliminarVacante(String id) async {}
}

class _MockPostulacionRepo implements PostulacionRepository {
  bool shouldFail = false;

  @override
  Future<List<Postulacion>> listarMisPostulaciones(String candidatoId) async => [];

  @override
  Future<List<Postulacion>> listarPostulacionesVacante(String vacanteId) async => [];

  @override
  Future<Postulacion> postularse({required String candidatoId, required String vacanteId}) async {
    if (shouldFail) throw const ApiException(400, 'Error al postularse');
    return Postulacion(
      id: 'real-p1',
      candidatoId: candidatoId,
      vacanteId: vacanteId,
      estado: PostulacionEstado.postulado,
      fecha: DateTime.now(),
    );
  }

  @override
  Future<void> cancelarPostulacion(String postulacionId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AI Match Breakdown Widget Tests', () {
    final testVacante = Vacante(
      id: 'v-flutter',
      empresaId: 'emp-1',
      titulo: 'Desarrollador Flutter Senior',
      descripcion: 'Buscamos desarrollador con experiencia en Dart, Docker y AWS',
      requisitos: const ['Flutter', 'Dart', 'AWS', 'Docker'],
      ubicacion: 'Bogotá',
      estado: VacanteEstado.activa,
      creadoEn: DateTime(2026, 10, 1),
    );

    const testProfile = Profile(
      id: 'p-1',
      userId: 'u-1',
      fullName: 'Nicolas Vasquez',
      skills: ['Flutter', 'Dart', 'Git', 'Firebase'],
      experienceYears: 4,
      cvText: 'Desarrollador móvil con Flutter y Dart',
    );

    testWidgets('Renders MatchBreakdownCard with Cumples and Por Potenciar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MatchBreakdownCard(
                vacante: testVacante,
                profile: testProfile,
                isSpanish: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Título del componente
      expect(find.text('Desglose de Compatibilidad IA'), findsOneWidget);
      expect(find.text('Cumples con tu perfil'), findsOneWidget);
      expect(find.text('Por potenciar / Para aprender'), findsOneWidget);

      // Cumple Flutter y Dart
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);

      // Faltan AWS y Docker
      expect(find.text('AWS'), findsOneWidget);
      expect(find.text('Docker'), findsOneWidget);

      // Consejo de IA presente
      expect(find.text('Consejo de la IA'), findsOneWidget);
    });

    testWidgets('MatchBreakdownData respects recomendacionML score if provided', (tester) async {
      const recML = Recomendacion(
        vacanteId: 'v-flutter',
        titulo: 'Desarrollador Flutter Senior',
        empresaId: 'emp-1',
        scoreSimilitud: 0.94,
        explicacion: 'Tu experiencia en Flutter y Dart se adapta directamente al perfil requerido.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MatchBreakdownCard(
                vacante: testVacante,
                profile: testProfile,
                recomendacionML: recML,
                isSpanish: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));

      expect(find.textContaining('94%'), findsWidgets);
      expect(find.text(recML.explicacion), findsOneWidget);
    });
  });

  group('CV Skills Extraction Sheet Tests', () {
    const testProfile = Profile(
      id: 'p-1',
      userId: 'u-1',
      fullName: 'Nicolas Vasquez',
      skills: ['Flutter'],
      experienceYears: 3,
    );

    testWidgets('Extracts skills from cvText and confirms selection', (tester) async {
      List<String>? confirmed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CvSkillsExtractionSheet(
              profile: testProfile,
              cvText: 'Experiencia en Python, FastAPI, Docker, Git y Clean Architecture',
              isSpanish: true,
              onConfirm: (skills) async {
                confirmed = skills;
                return true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debe haber detectado Python, FastAPI, Docker, Git, etc.
      expect(find.text('Habilidades detectadas por IA'), findsOneWidget);
      expect(find.text('Python'), findsOneWidget);
      expect(find.text('FastAPI'), findsOneWidget);
      expect(find.text('Docker'), findsOneWidget);

      // Confirmar habilidades
      await tester.tap(find.text('Confirmar Habilidades'));
      await tester.pumpAndSettle();

      expect(confirmed, isNotNull);
      expect(confirmed!.contains('Python'), isTrue);
      expect(confirmed!.contains('FastAPI'), isTrue);
      expect(confirmed!.contains('Docker'), isTrue);
    });
  });

  group('Offline-First & Optimistic Update Tests', () {
    test('VacantesProvider caches feed and loads from cache when offline', () async {
      final repo = _MockVacanteRepo();
      final v1 = Vacante(
        id: 'v-cached-1',
        empresaId: 'e-1',
        titulo: 'Flutter Remote',
        descripcion: 'Full remote',
        requisitos: ['Flutter'],
        ubicacion: 'Remoto',
        estado: VacanteEstado.activa,
        creadoEn: DateTime.now(),
      );
      repo.vacantesToReturn = [v1];

      final provider = VacantesProvider(repo);
      await provider.cargar();

      expect(provider.vacantes.length, 1);
      expect(provider.status, VacantesStatus.loaded);

      // Simular app restart con fallo de red
      final offlineRepo = _MockVacanteRepo()..throwError = true;
      final newProvider = VacantesProvider(offlineRepo);

      // Al cargar, el proveedor carga de caché (0ms) y preserva el estado loaded
      await newProvider.cargar();

      expect(newProvider.vacantes.isNotEmpty, isTrue);
      expect(newProvider.vacantes.first.titulo, 'Flutter Remote');
      expect(newProvider.isOffline, isTrue);
      expect(newProvider.status, VacantesStatus.loaded);
    });

    test('PostulacionesProvider performs optimistic update and rolls back on failure', () async {
      final repo = _MockPostulacionRepo()..shouldFail = true;
      final provider = PostulacionesProvider(repo);

      // Antes de postularse
      expect(provider.yaPostulado('v-99'), isFalse);

      final result = await provider.postularse(candidatoId: 'cand-1', vacanteId: 'v-99');

      // Falló en red, por lo que rollback ejecutado
      expect(result, isFalse);
      expect(provider.yaPostulado('v-99'), isFalse);
      expect(provider.postulaciones.isEmpty, isTrue);
    });

    test('VacantesProvider destacarVacante updates local entity to esDestacada: true', () async {
      final repo = _MockVacanteRepo();
      final v1 = Vacante(
        id: 'v-destacar-1',
        empresaId: 'e-1',
        titulo: 'Python Lead',
        descripcion: 'Full remote',
        requisitos: ['Python', 'Docker'],
        ubicacion: 'Remoto',
        estado: VacanteEstado.activa,
        creadoEn: DateTime.now(),
        esDestacada: false,
      );
      repo.vacantesToReturn = [v1];
      final provider = VacantesProvider(repo);
      await provider.cargar();

      expect(provider.vacantes.first.esDestacada, isFalse);
      final ok = await provider.destacarVacante('v-destacar-1');
      expect(ok, isTrue);
      expect(provider.vacantes.first.esDestacada, isTrue);
    });
  });
}
