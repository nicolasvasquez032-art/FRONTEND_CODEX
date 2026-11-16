import 'package:flutter_test/flutter_test.dart';
import 'package:talentmatch/core/network/api_client.dart';
import 'package:talentmatch/core/storage/secure_storage.dart';
import 'package:talentmatch/data/repositories/admin_repository_impl.dart';
import 'package:talentmatch/data/repositories/postulacion_repository_impl.dart';
import 'package:talentmatch/data/repositories/perfil_repository_impl.dart';
import 'package:talentmatch/data/repositories/auth_repository_impl.dart';
import 'package:talentmatch/domain/entities/postulacion.dart';
import 'package:talentmatch/domain/entities/vacante.dart';

class MockSecureStorage extends SecureStorage {
  final Map<String, String> _mem = {};

  @override
  Future<void> saveSession({
    required String token,
    required String userId,
    required String profileId,
    required String role,
    String? refreshToken,
    bool isPremium = false,
  }) async {
    _mem['auth_token'] = token;
    _mem['user_id'] = userId;
    _mem['profile_id'] = profileId;
    _mem['user_role'] = role;
    if (refreshToken != null) _mem['refresh_token'] = refreshToken;
    _mem['is_premium'] = isPremium.toString();
  }

  @override
  Future<String?> getToken() async => _mem['auth_token'];
  @override
  Future<String?> getRefreshToken() async => _mem['refresh_token'];
  @override
  Future<String?> getUserId() async => _mem['user_id'];
  @override
  Future<String?> getProfileId() async => _mem['profile_id'];
  @override
  Future<String?> getRole() async => _mem['user_role'];
  @override
  Future<bool> getIsPremium() async => _mem['is_premium'] == 'true';
  @override
  Future<void> clearSession() async => _mem.clear();
}

class MockApiClient extends ApiClient {
  MockApiClient(super.storage);

  Map<String, dynamic> nextGet = {};
  List<dynamic> nextList = [];
  Map<String, dynamic> nextPost = {};
  Map<String, dynamic> nextPut = {};
  Map<String, dynamic> nextPatch = {};

  @override
  Future<Map<String, dynamic>> get(String path, {Map<String, String>? queryParams, bool auth = true}) async {
    return nextGet;
  }

  @override
  Future<List<dynamic>> getList(String path, {Map<String, String>? queryParams, bool auth = true}) async {
    return nextList;
  }

  @override
  Future<Map<String, dynamic>> post(String path, dynamic body, {bool auth = true}) async {
    return nextPost;
  }

  @override
  Future<Map<String, dynamic>> put(String path, dynamic body, {bool auth = true}) async {
    return nextPut;
  }

  @override
  Future<Map<String, dynamic>> patch(String path, dynamic body, {bool auth = true}) async {
    return nextPatch;
  }

  @override
  Future<Map<String, dynamic>> delete(String path, {bool auth = true}) async {
    return {};
  }

  @override
  Future<Map<String, dynamic>> postMultipart(
    String path,
    List<int> fileBytes,
    String fileName,
    String mimeType, {
    Map<String, String>? fields,
  }) async {
    return nextPost;
  }
}

void main() {
  late MockSecureStorage mockStorage;
  late MockApiClient mockApi;

  setUp(() {
    mockStorage = MockSecureStorage();
    mockApi = MockApiClient(mockStorage);
  });

  group('AdminRepositoryImpl Tests', () {
    test('getMetricas obtiene métricas generales y de efectividad', () async {
      final repo = AdminRepositoryImpl(mockApi);
      mockApi.nextGet = {
        'total_candidatos': 50,
        'total_vacantes_activas': 10,
        'total_postulaciones': 25,
        'tiempo_promedio_dias': 4.5,
        'efectividad_porcentaje': 88.0,
      };
      mockApi.nextList = [
        {'sector': 'Tecnología', 'total_vacantes': 8, 'porcentaje': 80.0},
      ];

      final metrics = await repo.getMetricas();
      expect(metrics.totalCandidatos, 50);
      expect(metrics.totalVacantesActivas, 10);
      expect(metrics.totalPostulaciones, 25);
    });

    test('getTodasVacantes y moderarVacante funcionan', () async {
      final repo = AdminRepositoryImpl(mockApi);
      mockApi.nextList = [
        {
          'id': 'v-flagged',
          'empresa_id': 'emp-1',
          'titulo': 'Vacante Inapropiada',
          'descripcion': 'Contenido',
          'requisitos': ['Dart'],
          'ubicacion': 'Remoto',
          'estado': 'activa',
          'creado_en': '2026-11-01T00:00:00.000Z',
        }
      ];
      final vacantes = await repo.getTodasVacantes();
      expect(vacantes.length, 1);
      expect(vacantes.first.titulo, 'Vacante Inapropiada');

      mockApi.nextPatch = {
        'id': 'v-flagged',
        'empresa_id': 'emp-1',
        'titulo': 'Vacante Inapropiada',
        'descripcion': 'Contenido',
        'requisitos': ['Dart'],
        'ubicacion': 'Remoto',
        'estado': 'cerrada',
        'creado_en': '2026-11-01T00:00:00.000Z',
      };
      final moderada = await repo.moderarVacante('v-flagged', 'cerrada');
      expect(moderada.estado, VacanteEstado.cerrada);
    });
  });

  group('PostulacionRepositoryImpl Tests', () {
    test('postularse crea postulación correctamente', () async {
      final repo = PostulacionRepositoryImpl(mockApi);
      mockApi.nextPost = {
        'id': 'p-1',
        'candidato_id': 'cand-1',
        'vacante_id': 'v-1',
        'estado': 'postulado',
        'fecha': '2026-11-16T10:00:00.000Z',
      };

      final p = await repo.postularse(candidatoId: 'cand-1', vacanteId: 'v-1');
      expect(p.id, 'p-1');
      expect(p.estado, PostulacionEstado.postulado);
    });

    test('listarMisPostulaciones usa candidatoId o fallback /me', () async {
      final repo = PostulacionRepositoryImpl(mockApi);
      mockApi.nextList = [
        {
          'id': 'p-2',
          'candidato_id': 'cand-1',
          'vacante_id': 'v-2',
          'estado': 'en_revision',
          'fecha': '2026-11-16T10:00:00.000Z',
          'vacante_titulo': 'Full Stack Dev',
        }
      ];

      final posts = await repo.listarMisPostulaciones('cand-1');
      expect(posts.length, 1);
      expect(posts.first.vacanteTitulo, 'Full Stack Dev');

      final postsMe = await repo.listarMisPostulaciones('');
      expect(postsMe.length, 1);
    });

    test('listarPostulacionesVacante y cancelarPostulacion funcionan', () async {
      final repo = PostulacionRepositoryImpl(mockApi);
      mockApi.nextList = [
        {
          'id': 'p-3',
          'candidato_id': 'cand-9',
          'vacante_id': 'v-3',
          'estado': 'postulado',
          'fecha': '2026-11-16T10:00:00.000Z',
        }
      ];
      final res = await repo.listarPostulacionesVacante('v-3');
      expect(res.length, 1);

      mockApi.nextPatch = {'status': 'success'};
      await repo.cancelarPostulacion('p-3');
    });
  });

  group('PerfilRepositoryImpl Tests', () {
    test('getPerfil y getMiPerfil devuelven entidad Profile', () async {
      final repo = PerfilRepositoryImpl(mockApi);
      mockApi.nextGet = {
        'id': 'prof-123',
        'user_id': 'user-123',
        'full_name': 'Nicolás Vásquez',
        'skills': ['Python', 'Dart'],
        'experience_years': 3,
      };

      final p1 = await repo.getPerfil('prof-123');
      expect(p1.fullName, 'Nicolás Vásquez');
      expect(p1.skills.length, 2);

      final p2 = await repo.getMiPerfil();
      expect(p2.id, 'prof-123');
    });

    test('updatePerfil y uploadCv mapean datos correctamente', () async {
      final repo = PerfilRepositoryImpl(mockApi);
      mockApi.nextPut = {
        'id': 'prof-123',
        'user_id': 'user-123',
        'full_name': 'Nicolás Vásquez Gómez',
        'skills': ['Python', 'Flutter'],
        'experience_years': 4,
      };

      final updated = await repo.updatePerfil(
        profileId: 'prof-123',
        fullName: 'Nicolás Vásquez Gómez',
        skills: ['Python', 'Flutter'],
        experienceYears: 4,
      );
      expect(updated.fullName, 'Nicolás Vásquez Gómez');

      mockApi.nextPost = {
        'profile_id': 'prof-123',
        'message': 'CV subido',
        'cv_preview': 'Texto extraído del CV',
      };
      final preview = await repo.uploadCv(
        profileId: 'prof-123',
        fileBytes: [1, 2, 3],
        fileName: 'cv.pdf',
        mimeType: 'application/pdf',
      );
      expect(preview, 'Texto extraído del CV');
    });
  });

  group('AuthRepositoryImpl Tests', () {
    test('restoreSession retorna null si no hay token o recupera la sesion', () async {
      final repo = AuthRepositoryImpl(mockApi, mockStorage);
      final empty = await repo.restoreSession();
      expect(empty, isNull);

      await mockStorage.saveSession(
        token: 'token.abc',
        userId: 'u-1',
        profileId: 'p-1',
        role: 'candidate',
        isPremium: true,
      );
      final restored = await repo.restoreSession();
      expect(restored?.userId, 'u-1');
      expect(restored?.isPremium, isTrue);

      await repo.logout();
      expect(await mockStorage.getToken(), isNull);
    });
  });
}
