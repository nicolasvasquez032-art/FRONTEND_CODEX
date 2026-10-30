import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talentmatch/core/constants/app_strings.dart';
import 'package:talentmatch/core/network/api_client.dart';
import 'package:talentmatch/core/storage/secure_storage.dart';
import 'package:talentmatch/data/repositories/auth_repository_impl.dart';

class MockAuthApiClient implements ApiClient {
  String lastPath = '';
  Map<String, dynamic> lastPostData = {};
  bool failProfile = false;

  @override
  Future<Map<String, dynamic>> post(String path, dynamic body, {bool auth = true}) async {
    lastPath = path;
    lastPostData = body as Map<String, dynamic>;

    if (path == '/auth/login') {
      final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
      final payload = base64Url.encode(utf8.encode(jsonEncode({
        'sub': 'usr-jwt-123',
        'role': 'candidate',
        'profile_id': 'prof-jwt-456',
        'is_premium': true,
      })));
      final jwt = '$header.$payload.fakeSignature';
      return {
        'access_token': jwt,
        'refresh_token': 'refresh-xyz',
      };
    }
    return {'status': 'ok'};
  }

  @override
  Future<Map<String, dynamic>> get(String path, {bool auth = true, Map<String, String>? queryParams}) async {
    lastPath = path;
    if (path == '/perfiles/me') {
      if (failProfile) throw Exception('Network error');
      return {'id': 'real-profile-789'};
    }
    return {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureStorage Tests', () {
    late SecureStorage storage;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      storage = SecureStorage();
    });

    test('Guardar sesión completa, leer valores individuales y limpiar', () async {
      expect(await storage.hasSession(), isFalse);

      await storage.saveSession(
        token: 'token-abc',
        userId: 'usr-1',
        profileId: 'prof-1',
        role: 'candidate',
        refreshToken: 'refresh-1',
        isPremium: true,
      );

      expect(await storage.hasSession(), isTrue);
      expect(await storage.getToken(), 'token-abc');
      expect(await storage.getRefreshToken(), 'refresh-1');
      expect(await storage.getUserId(), 'usr-1');
      expect(await storage.getProfileId(), 'prof-1');
      expect(await storage.getRole(), 'candidate');
      expect(await storage.getIsPremium(), isTrue);

      await storage.saveToken('token-updated');
      expect(await storage.getToken(), 'token-updated');

      await storage.saveRefreshToken('refresh-updated');
      expect(await storage.getRefreshToken(), 'refresh-updated');

      await storage.saveProfileId('prof-updated');
      expect(await storage.getProfileId(), 'prof-updated');

      await storage.clearSession();
      expect(await storage.hasSession(), isFalse);
      expect(await storage.getToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getUserId(), isNull);
      expect(await storage.getProfileId(), isNull);
      expect(await storage.getRole(), isNull);
      expect(await storage.getIsPremium(), isFalse);
    });
  });

  group('AuthRepositoryImpl Tests', () {
    late MockAuthApiClient api;
    late SecureStorage storage;
    late AuthRepositoryImpl authRepo;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      api = MockAuthApiClient();
      storage = SecureStorage();
      authRepo = AuthRepositoryImpl(api, storage);
    });

    test('login exitoso parsea claims de JWT y obtiene perfil real', () async {
      final session = await authRepo.login(email: 'dev@codex.com', password: 'password123');

      expect(session.userId, 'usr-jwt-123');
      expect(session.profileId, 'real-profile-789');
      expect(session.role, 'candidate');
      expect(session.isPremium, isTrue);

      // Debe persistir en SecureStorage
      expect(await storage.getToken(), contains('fakeSignature'));
      expect(await storage.getProfileId(), 'real-profile-789');
    });

    test('login con fallo en _fetchProfileId usa profileId del JWT', () async {
      api.failProfile = true;
      final session = await authRepo.login(email: 'dev@codex.com', password: 'password123');

      expect(session.userId, 'usr-jwt-123');
      expect(session.profileId, 'prof-jwt-456');
    });

    test('registerCandidate envía payload completo', () async {
      await authRepo.registerCandidate(
        email: 'new@candidate.com',
        password: 'pass',
        fullName: 'New Dev',
        skills: ['Dart', 'Flutter'],
        experienceYears: 2,
        location: 'Bogotá',
        education: 'Tecnólogo',
      );

      expect(api.lastPath, '/auth/registro/candidato');
      expect(api.lastPostData['full_name'], 'New Dev');
      expect(api.lastPostData['location'], 'Bogotá');
      expect(api.lastPostData['skills'], ['Dart', 'Flutter']);
    });

    test('registerCompany, requestPasswordReset y logout', () async {
      await authRepo.registerCompany(email: 'company@talent.com', password: 'pass');
      expect(api.lastPath, '/auth/registro/empresa');

      await authRepo.requestPasswordReset('recover@talent.com');
      expect(api.lastPath, '/auth/recuperar-password');

      await storage.saveToken('test-token');
      expect(await storage.hasSession(), isTrue);
      await authRepo.logout();
      expect(await storage.hasSession(), isFalse);
    });

    test('restoreSession retorna UserSession válida o null si no hay sesión', () async {
      expect(await authRepo.restoreSession(), isNull);

      await storage.saveSession(
        token: 'token-active',
        userId: 'usr-9',
        profileId: 'prof-9',
        role: 'company',
        isPremium: false,
      );

      final restored = await authRepo.restoreSession();
      expect(restored, isNotNull);
      expect(restored!.userId, 'usr-9');
      expect(restored.profileId, 'prof-9');
      expect(restored.role, 'company');
      expect(restored.isPremium, isFalse);
    });
  });

  group('AppStrings Tests', () {
    test('AppStrings constantes están definidas', () {
      expect(AppStrings.appName, 'TalentMatch');
      expect(AppStrings.login, 'Iniciar sesión');
      expect(AppStrings.register, 'Crear cuenta');
      expect(AppStrings.successApplied, 'Tu postulación fue enviada.');
    });
  });
}
