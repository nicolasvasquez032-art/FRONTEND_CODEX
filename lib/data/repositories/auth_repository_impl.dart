import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/profile_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _api;
  final SecureStorage _storage;

  AuthRepositoryImpl(this._api, this._storage);

  // ──────────────────────────────────────────────
  // Login
  // ──────────────────────────────────────────────

  @override
  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    // 1. Obtener token
    final tokenData = await _api.post(
      '/auth/login',
      {'email': email, 'password': password},
      auth: false,
    );
    final token = tokenData['access_token'] as String;

    // 2. Guardar token temporalmente para poder llamar el endpoint de perfil
    await _storage.saveSession(
      token: token,
      userId: '',
      profileId: '',
      role: 'candidate',
      isPremium: false,
    );

    // 3. Obtener el perfil del candidato para extraer user_id y profile_id
    //    Llamamos a /perfiles usando un endpoint auxiliar que devuelve el perfil
    //    del usuario actual. Como el backend no tiene /me, usamos el token JWT
    //    decodificado o bien registramos con el flujo normal.
    //    El backend devuelve el sub del JWT como user_id en el token.
    //    Decodificamos el payload del JWT (sin verificar firma — solo para leer claims).
    final session = _decodeJwtSession(token);

    await _storage.saveSession(
      token: token,
      userId: session.userId,
      profileId: session.profileId,
      role: session.role,
      isPremium: session.isPremium,
    );

    // Obtener el profile_id real desde el backend (el JWT no lo incluye)
    final profileId = await _fetchProfileId();
    if (profileId.isNotEmpty) {
      await _storage.saveProfileId(profileId);
      return UserSession(userId: session.userId, profileId: profileId, role: session.role, isPremium: session.isPremium);
    }

    return session;
  }

  // ──────────────────────────────────────────────
  // Registro candidato
  // ──────────────────────────────────────────────

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
    // 1. Registrar
    final profileData = await _api.post(
      '/auth/registro/candidato',
      {
        'email': email,
        'password': password,
        'full_name': fullName,
        'skills': skills,
        'experience_years': experienceYears,
        if (location != null && location.isNotEmpty) 'location': location,
        if (education != null && education.isNotEmpty) 'education': education,
      },
      auth: false,
    );
  }

  // ──────────────────────────────────────────────
  // Registro empresa
  // ──────────────────────────────────────────────

  @override
  Future<void> registerCompany({
    required String email,
    required String password,
  }) async {
    await _api.post(
      '/auth/registro/empresa',
      {
        'email': email,
        'password': password,
      },
      auth: false,
    );
  }

  // ──────────────────────────────────────────────
  // Recuperar contraseña
  // ──────────────────────────────────────────────

  @override
  Future<void> requestPasswordReset(String email) async {
    await _api.post(
      '/auth/recuperar-password',
      {'email': email},
      auth: false,
    );
  }

  // ──────────────────────────────────────────────
  // Logout
  // ──────────────────────────────────────────────

  @override
  Future<void> logout() => _storage.clearSession();

  // ──────────────────────────────────────────────
  // Restaurar sesión desde storage
  // ──────────────────────────────────────────────

  @override
  Future<UserSession?> restoreSession() async {
    if (!await _storage.hasSession()) return null;
    final userId    = await _storage.getUserId() ?? '';
    final profileId = await _storage.getProfileId() ?? '';
    final role      = await _storage.getRole() ?? 'candidate';
    final isPremium = await _storage.getIsPremium();
    return UserSession(userId: userId, profileId: profileId, role: role, isPremium: isPremium);
  }

  // ──────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────

  /// Llama a GET /perfiles/me para obtener el profile_id real del candidato.
  /// Retorna cadena vacía si falla o el usuario no es candidato.
  Future<String> _fetchProfileId() async {
    try {
      final data = await _api.get('/perfiles/me', auth: true);
      return (data['id'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Decodifica el payload del JWT (base64url) para extraer `sub` y `role`.
  /// No verifica la firma — solo lee los claims para uso interno en el cliente.
  UserSession _decodeJwtSession(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) throw const FormatException('JWT inválido');

      // Normalizar base64url a base64 estándar
      String payload = parts[1];
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final decoded = String.fromCharCodes(
        Uri.parse(
          'data:application/octet-stream;base64,$payload',
        ).data!.contentAsBytes(),
      );

      // El payload del JWT del backend incluye: sub (user_id), role, profile_id
      final claims = _parseSimpleJson(decoded);
      final userId    = claims['sub']?.toString() ?? '';
      final role      = claims['role']?.toString() ?? 'candidate';
      final profileId = claims['profile_id']?.toString() ?? '';
      
      final isPremiumStr = claims['is_premium']?.toString().toLowerCase();
      final isPremium = (isPremiumStr == 'true' || isPremiumStr == '1');

      return UserSession(userId: userId, profileId: profileId, role: role, isPremium: isPremium);
    } catch (_) {
      // Fallback: sesión vacía (el usuario verá su perfil en blanco)
      return const UserSession(userId: '', profileId: '', role: 'candidate', isPremium: false);
    }
  }

  /// Parser JSON simple para el payload JWT (evita importar dart:convert dos veces).
  Map<String, dynamic> _parseSimpleJson(String json) {
    final map = <String, dynamic>{};
    final cleaned = json.trim().replaceAll('{', '').replaceAll('}', '');
    for (final entry in cleaned.split(',')) {
      final parts = entry.split(':');
      if (parts.length >= 2) {
        final key = parts[0].trim().replaceAll('"', '');
        final value = parts.sublist(1).join(':').trim().replaceAll('"', '');
        map[key] = value;
      }
    }
    return map;
  }
}
