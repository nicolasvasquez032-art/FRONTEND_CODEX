import 'dart:convert';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/auth_repository.dart';

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
    await ApiClient.clearCache();
    await _storage.clearSession();

    // 1. Obtener token
    final tokenData = await _api.post(
      '/auth/login',
      {'email': email, 'password': password},
      auth: false,
    );
    final token = tokenData['access_token'] as String;
    final refreshToken = tokenData['refresh_token'] as String?;

    // 2. Guardar token temporalmente para poder llamar el endpoint de perfil
    await _storage.saveSession(
      token: token,
      userId: '',
      profileId: '',
      role: 'candidate',
      refreshToken: refreshToken,
      isPremium: false,
    );

    // 3. Decodificar JWT
    final session = _decodeJwtSession(token);
    final realProfileId = session.role == 'candidate' ? await _fetchProfileId() : '';
    final profileId = realProfileId.isNotEmpty ? realProfileId : session.profileId;

    await _storage.saveSession(
      token: token,
      userId: session.userId,
      profileId: profileId,
      role: session.role,
      refreshToken: refreshToken,
      isPremium: session.isPremium,
    );

    return UserSession(
      userId: session.userId,
      profileId: profileId,
      role: session.role,
      isPremium: session.isPremium,
      email: session.email,
    );
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
    await _api.post(
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
    String? nombre,
  }) async {
    await _api.post(
      '/auth/registro/empresa',
      {
        'email': email,
        'password': password,
        if (nombre != null && nombre.trim().isNotEmpty) 'nombre': nombre.trim(),
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
  Future<UserSession> loginWithSocial({
    required String provider,
    String? token,
    String? email,
    String? fullName,
  }) async {
    final tokenData = await _api.post(
      '/auth/oauth/social',
      {
        'provider': provider,
        'token': token ?? 'mock_${provider}_token',
        if (email != null && email.isNotEmpty) 'email': email,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      },
      auth: false,
    );
    final accessToken = tokenData['access_token'] as String;
    final refreshToken = tokenData['refresh_token'] as String?;
    final isNewUser = tokenData['is_new_user'] == true;
    final responseProfileId = tokenData['profile_id']?.toString();

    await ApiClient.clearCache();
    await _storage.clearSession();

    final session = _decodeJwtSession(accessToken);
    final effectiveProfileId = (responseProfileId != null && responseProfileId.isNotEmpty)
        ? responseProfileId
        : (session.profileId.isNotEmpty ? session.profileId : await _fetchProfileId());

    await _storage.saveSession(
      token: accessToken,
      userId: session.userId,
      profileId: effectiveProfileId,
      role: session.role,
      refreshToken: refreshToken,
      isPremium: session.isPremium,
    );

    return UserSession(
      userId: session.userId,
      profileId: effectiveProfileId,
      role: session.role,
      isPremium: session.isPremium,
      email: session.email,
      isNewUser: isNewUser,
    );
  }

  @override
  Future<UserSession> handleSocialAuthToken({
    required String token,
    required String refreshToken,
    bool isNewUser = false,
  }) async {
    await ApiClient.clearCache();
    await _storage.clearSession();

    final session = _decodeJwtSession(token);
    final profileId = session.profileId.isNotEmpty
        ? session.profileId
        : await _fetchProfileId();

    await _storage.saveSession(
      token: token,
      userId: session.userId,
      profileId: profileId,
      role: session.role,
      refreshToken: refreshToken,
      isPremium: session.isPremium,
    );

    return UserSession(
      userId: session.userId,
      profileId: profileId,
      role: session.role,
      isPremium: session.isPremium,
      email: session.email,
      isNewUser: isNewUser,
    );
  }

  @override
  Future<void> logout() async {
    await ApiClient.clearCache();
    await _storage.clearSession();
  }

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
  /// Usa dart:convert jsonDecode para parsear correctamente JSON con cualquier tipo de valor.
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

      final decoded = utf8.decode(base64Decode(payload));

      // Parsear con jsonDecode estándar — soporta cualquier valor JSON válido
      final claims = jsonDecode(decoded) as Map<String, dynamic>;
      final userId    = claims['sub']?.toString() ?? '';
      final role      = claims['role']?.toString() ?? 'candidate';
      final profileId = claims['profile_id']?.toString() ?? '';
      final email     = claims['email']?.toString();

      final isPremiumRaw = claims['is_premium'];
      final isPremium = isPremiumRaw == true || isPremiumRaw.toString().toLowerCase() == 'true';

      return UserSession(
        userId: userId,
        profileId: profileId,
        role: role,
        isPremium: isPremium,
        email: email,
      );
    } catch (_) {
      // Fallback: sesión vacía (el usuario verá su perfil en blanco)
      return const UserSession(userId: '', profileId: '', role: 'candidate', isPremium: false);
    }
  }
}

