import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talentmatch/core/network/api_client.dart';
import 'package:talentmatch/domain/entities/user_session.dart';
import 'package:talentmatch/domain/entities/vacante.dart';
import 'package:talentmatch/domain/entities/postulacion.dart';
import 'package:talentmatch/domain/entities/notificacion.dart';
import 'package:talentmatch/domain/entities/recomendacion.dart';
import 'package:talentmatch/domain/repositories/auth_repository.dart';
import 'package:talentmatch/domain/repositories/vacante_repository.dart';
import 'package:talentmatch/domain/repositories/postulacion_repository.dart';
import 'package:talentmatch/domain/repositories/notificacion_repository.dart';
import 'package:talentmatch/domain/repositories/recomendacion_repository.dart';
import 'package:talentmatch/presentation/shared/providers/auth_provider.dart';
import 'package:talentmatch/presentation/shared/providers/vacantes_provider.dart';
import 'package:talentmatch/presentation/shared/providers/postulaciones_provider.dart';
import 'package:talentmatch/presentation/shared/providers/notificaciones_provider.dart';
import 'package:talentmatch/presentation/shared/providers/recomendaciones_provider.dart';

// ── FAKES DE REPOSITORIOS ──

class FakeAuthRepo implements AuthRepository {
  bool shouldFail = false;
  bool shouldTimeout = false;
  ApiException? apiException;
  UserSession? currentSession;

  @override
  Future<UserSession> login({required String email, required String password}) async {
    if (shouldTimeout) throw TimeoutException('timeout');
    if (apiException != null) throw apiException!;
    if (shouldFail) throw Exception('fail');
    return currentSession ?? const UserSession(userId: 'u1', profileId: 'p1', role: 'candidate');
  }

  @override
  Future<UserSession?> restoreSession() async => currentSession;

  @override
  Future<void> logout() async {
    currentSession = null;
  }

  @override
  Future<void> registerCandidate({
    required String email,
    required String password,
    required String fullName,
    List<String> skills = const [],
    int experienceYears = 0,
    String? location,
    String? education,
  }) async {
    if (shouldFail) throw Exception('fail');
  }

  @override
  Future<void> registerCompany({required String email, required String password}) async {
    if (shouldFail) throw Exception('fail');
  }

  @override
  Future<void> requestPasswordReset(String email) async {}
}

class FakeVacanteRepo implements VacanteRepository {
  List<Vacante> vacantes = [];
  bool shouldFail = false;
  ApiException? apiException;

  @override
  Future<List<Vacante>> listarVacantes({String? ubicacion, String? categoria}) async {
    if (apiException != null) throw apiException!;
    if (shouldFail) throw Exception('fail');
    return vacantes;
  }

  @override
  Future<Vacante> getVacante(String id) async => vacantes.firstWhere((v) => v.id == id);

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
  }) async {
    if (shouldFail) throw Exception('fail');
    final v = Vacante(
      id: 'v-new',
      empresaId: 'emp-1',
      titulo: titulo,
      descripcion: descripcion,
      requisitos: requisitos,
      ubicacion: ubicacion,
      estado: VacanteEstado.activa,
      categoria: categoria,
      salarioMin: salarioMin,
      salarioMax: salarioMax,
      creadoEn: DateTime.now(),
    );
    vacantes.add(v);
    return v;
  }

  @override
  Future<void> eliminarVacante(String id) async {
    vacantes.removeWhere((v) => v.id == id);
  }
}

class FakePostulacionRepo implements PostulacionRepository {
  List<Postulacion> postulaciones = [];
  bool shouldFail = false;
  ApiException? apiException;

  @override
  Future<List<Postulacion>> listarMisPostulaciones(String candidatoId) async {
    if (apiException != null) throw apiException!;
    if (shouldFail) throw Exception('fail');
    return postulaciones;
  }

  @override
  Future<Postulacion> postularse({required String candidatoId, required String vacanteId}) async {
    if (apiException != null) throw apiException!;
    if (shouldFail) throw Exception('fail');
    final p = Postulacion(
      id: 'p-new',
      candidatoId: candidatoId,
      vacanteId: vacanteId,
      estado: PostulacionEstado.postulado,
      fecha: DateTime.now(),
    );
    postulaciones.add(p);
    return p;
  }

  @override
  Future<void> cancelarPostulacion(String postulacionId) async {
    if (apiException != null) throw apiException!;
    if (shouldFail) throw Exception('fail');
    postulaciones.removeWhere((p) => p.id == postulacionId);
  }
}

class FakeNotificacionRepo implements NotificacionRepository {
  List<Notificacion> notificaciones = [];
  bool shouldFail = false;

  @override
  Future<List<Notificacion>> getNotificaciones(String usuarioId, {int limit = 50, int offset = 0}) async {
    if (shouldFail) throw Exception('fail');
    return notificaciones;
  }

  @override
  Future<void> marcarLeida(String notificacionId) async {
    if (shouldFail) throw Exception('fail');
    final idx = notificaciones.indexWhere((n) => n.id == notificacionId);
    if (idx != -1) {
      notificaciones[idx] = notificaciones[idx].copyWith(leido: true);
    }
  }

  @override
  Future<void> registrarToken(String token, {String? dispositivoInfo}) async {}
}

class FakeRecomendacionRepo implements RecomendacionRepository {
  List<Recomendacion> recomendaciones = [];
  bool shouldFail = false;
  ApiException? apiException;

  @override
  Future<List<Recomendacion>> getRecomendaciones(String candidatoId) async {
    if (apiException != null) throw apiException!;
    if (shouldFail) throw Exception('fail');
    return recomendaciones;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthProvider Tests', () {
    test('Login exitoso autentica y guarda la sesión', () async {
      final fakeRepo = FakeAuthRepo();
      final provider = AuthProvider(fakeRepo);

      await provider.login('candidato@test.com', 'password123');

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.session?.userId, 'u1');
      expect(provider.error, isNull);
      expect(provider.loading, isFalse);
    });

    test('Login con ApiException maneja error amigable', () async {
      final fakeRepo = FakeAuthRepo()
        ..apiException = const ApiException(401, 'Credenciales incorrectas');
      final provider = AuthProvider(fakeRepo);

      await provider.login('bad@test.com', 'wrong');

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.error, isNotNull);
      expect(provider.loading, isFalse);
    });

    test('Login con TimeoutException maneja timeout correctamente', () async {
      final fakeRepo = FakeAuthRepo()..shouldTimeout = true;
      final provider = AuthProvider(fakeRepo);

      await provider.login('user@test.com', 'password');

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.error, contains('tardó demasiado'));
    });

    test('completeOnboarding actualiza SharedPreferences', () async {
      final fakeRepo = FakeAuthRepo();
      final provider = AuthProvider(fakeRepo);

      await provider.completeOnboarding();
      expect(provider.hasSeenOnboarding, isTrue);
    });

    test('Logout limpia la sesión', () async {
      final fakeRepo = FakeAuthRepo()
        ..currentSession = const UserSession(userId: 'u1', profileId: 'p1', role: 'candidate');
      final provider = AuthProvider(fakeRepo);

      await provider.logout();
      expect(provider.session, isNull);
      expect(provider.status, AuthStatus.unauthenticated);
    });
  });

  group('VacantesProvider Tests', () {
    test('Cargar vacantes exitosamente y aplicar filtros combinados', () async {
      final fakeRepo = FakeVacanteRepo()
        ..vacantes = [
          Vacante(
            id: 'v1',
            empresaId: 'e1',
            titulo: 'Flutter Engineer',
            descripcion: 'Mobile developer',
            requisitos: ['Dart'],
            ubicacion: 'Bogotá',
            estado: VacanteEstado.activa,
            categoria: 'Tecnología',
            salarioMin: 4000000,
            creadoEn: DateTime.now(),
          ),
          Vacante(
            id: 'v2',
            empresaId: 'e1',
            titulo: 'Diseñador UI/UX',
            descripcion: 'Figma y diseño web',
            requisitos: ['Figma'],
            ubicacion: 'Remoto',
            estado: VacanteEstado.activa,
            categoria: 'Diseño',
            salarioMin: 3000000,
            creadoEn: DateTime.now(),
          ),
        ];

      final provider = VacantesProvider(fakeRepo);
      await provider.cargar();

      expect(provider.status, VacantesStatus.loaded);
      expect(provider.vacantes.length, 2);
      expect(provider.filtered.length, 2);

      // Filtro por categoría
      provider.setCategoriaFiltro('Tecnología');
      expect(provider.filtered.length, 1);
      expect(provider.filtered.first.titulo, 'Flutter Engineer');

      // Toggle categoría (desactiva)
      provider.setCategoriaFiltro('Tecnología');
      expect(provider.filtroCategoria, isNull);
      expect(provider.filtered.length, 2);

      // Filtro por salario mínimo
      provider.setSalarioFiltro(3500000);
      expect(provider.filtered.length, 1);
      expect(provider.filtered.first.id, 'v1');

      provider.setSalarioFiltro(3500000);
      expect(provider.filtroSalarioMin, isNull);
    });

    test('Cargar vacantes con fallo maneja estado de error', () async {
      final fakeRepo = FakeVacanteRepo()
        ..apiException = const ApiException(500, 'Error de servidor');
      final provider = VacantesProvider(fakeRepo);

      await provider.cargar();

      expect(provider.status, VacantesStatus.error);
      expect(provider.error, 'Error de servidor');
    });

    test('Publicar vacante exitosamente', () async {
      final fakeRepo = FakeVacanteRepo();
      final provider = VacantesProvider(fakeRepo);

      final ok = await provider.publicarVacante(
        titulo: 'Backend Python',
        descripcion: 'FastAPI',
        requisitos: ['FastAPI', 'PostgreSQL'],
        ubicacion: 'Medellín',
        categoria: 'Tecnología',
      );

      expect(ok, isTrue);
      expect(provider.vacantes.any((v) => v.titulo == 'Backend Python'), isTrue);
    });
  });

  group('PostulacionesProvider Tests', () {
    test('Cargar postulaciones y verificar yaPostulado', () async {
      final fakeRepo = FakePostulacionRepo()
        ..postulaciones = [
          Postulacion(
            id: 'p1',
            candidatoId: 'cand-1',
            vacanteId: 'v100',
            estado: PostulacionEstado.postulado,
            fecha: DateTime.now(),
          ),
        ];

      final provider = PostulacionesProvider(fakeRepo);
      await provider.cargar('cand-1');

      expect(provider.status, PostulacionesStatus.loaded);
      expect(provider.yaPostulado('v100'), isTrue);
      expect(provider.yaPostulado('v200'), isFalse);
      expect(provider.postulacionDe('v100')?.id, 'p1');
    });

    test('Postularse previene duplicidad si ya está postulado', () async {
      final fakeRepo = FakePostulacionRepo()
        ..postulaciones = [
          Postulacion(
            id: 'p1',
            candidatoId: 'cand-1',
            vacanteId: 'v100',
            estado: PostulacionEstado.postulado,
            fecha: DateTime.now(),
          ),
        ];

      final provider = PostulacionesProvider(fakeRepo);
      await provider.cargar('cand-1');

      final duplicateOk = await provider.postularse(candidatoId: 'cand-1', vacanteId: 'v100');
      expect(duplicateOk, isFalse);
    });

    test('Postularse a nueva vacante y luego cancelar', () async {
      final fakeRepo = FakePostulacionRepo();
      final provider = PostulacionesProvider(fakeRepo);

      final ok = await provider.postularse(candidatoId: 'cand-1', vacanteId: 'v200');
      expect(ok, isTrue);
      expect(provider.yaPostulado('v200'), isTrue);

      final cancelOk = await provider.cancelar('p-new');
      expect(cancelOk, isTrue);
      expect(provider.yaPostulado('v200'), isFalse);
    });
  });

  group('NotificacionesProvider Tests', () {
    test('Cargar notificaciones y calcular noLeidasCount', () async {
      final fakeRepo = FakeNotificacionRepo()
        ..notificaciones = [
          Notificacion(id: 'n1', tipo: 'postulacion', mensaje: 'Msg 1', leido: false, creadoEn: DateTime.now()),
          Notificacion(id: 'n2', tipo: 'sistema', mensaje: 'Msg 2', leido: true, creadoEn: DateTime.now()),
        ];

      final provider = NotificacionesProvider(fakeRepo);
      await provider.cargar('user-1');

      expect(provider.status, NotificacionesStatus.loaded);
      expect(provider.notificaciones.length, 2);
      expect(provider.noLeidasCount, 1);

      await provider.marcarLeida('n1');
      expect(provider.noLeidasCount, 0);
    });
  });

  group('RecomendacionesProvider Tests', () {
    test('Cargar recomendaciones exitosamente y verificar top4', () async {
      final fakeRepo = FakeRecomendacionRepo()
        ..recomendaciones = List.generate(
          6,
          (i) => Recomendacion(
            vacanteId: 'v-$i',
            titulo: 'Vacante $i',
            empresaId: 'e-1',
            scoreSimilitud: 0.9 - (i * 0.05),
            explicacion: 'Match $i',
          ),
        );

      final provider = RecomendacionesProvider(fakeRepo);
      await provider.cargar('cand-1');

      expect(provider.status, RecomendacionesStatus.loaded);
      expect(provider.hasData, isTrue);
      expect(provider.top4.length, 4);
    });

    test('Fallo de ML activa estado de fallback para resiliencia', () async {
      final fakeRepo = FakeRecomendacionRepo()
        ..apiException = const ApiException(503, 'ML offline');

      final provider = RecomendacionesProvider(fakeRepo);
      await provider.cargar('cand-1');

      expect(provider.isFallback, isTrue);
      expect(provider.status, RecomendacionesStatus.fallback);
    });
  });
}
