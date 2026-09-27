import 'package:shared_preferences/shared_preferences.dart';

/// Persiste la sesión del candidato en SharedPreferences.
/// Claves almacenadas: auth_token, user_id, profile_id, user_role.
class SecureStorage {
  static const _keyToken     = 'auth_token';
  static const _keyUserId    = 'user_id';
  static const _keyProfileId = 'profile_id';
  static const _keyRole      = 'user_role';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ── Guardar sesión completa tras login / registro ──

  Future<void> saveSession({
    required String token,
    required String userId,
    required String profileId,
    required String role,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyProfileId, profileId);
    await prefs.setString(_keyRole, role);
  }

  // ── Lectura individual ──

  Future<String?> getToken()     async => (await _prefs).getString(_keyToken);
  Future<String?> getUserId()    async => (await _prefs).getString(_keyUserId);
  Future<String?> getProfileId() async => (await _prefs).getString(_keyProfileId);
  Future<String?> getRole()      async => (await _prefs).getString(_keyRole);

  /// Devuelve true si existe un token guardado (sesión activa).
  Future<bool> hasSession() async => (await getToken()) != null;

  // ── Logout: borra todo ──

  Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyProfileId);
    await prefs.remove(_keyRole);
  }
}
