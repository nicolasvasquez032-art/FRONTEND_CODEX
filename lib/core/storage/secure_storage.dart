import 'package:shared_preferences/shared_preferences.dart';

/// Persiste la sesión del candidato en SharedPreferences.
/// Claves almacenadas: auth_token, user_id, profile_id, user_role.
class SecureStorage {
  static const _keyToken     = 'auth_token';
  static const _keyUserId    = 'user_id';
  static const _keyProfileId = 'profile_id';
  static const _keyRole      = 'user_role';
  static const _keyPremium   = 'is_premium';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ── Guardar sesión completa tras login / registro ──

  Future<void> saveSession({
    required String token,
    required String userId,
    required String profileId,
    required String role,
    bool isPremium = false,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyProfileId, profileId);
    await prefs.setString(_keyRole, role);
    await prefs.setBool(_keyPremium, isPremium);
  }

  // ── Lectura individual ──

  Future<String?> getToken()     async => (await _prefs).getString(_keyToken);
  Future<String?> getUserId()    async => (await _prefs).getString(_keyUserId);
  Future<String?> getProfileId() async => (await _prefs).getString(_keyProfileId);
  Future<String?> getRole()      async => (await _prefs).getString(_keyRole);
  Future<bool>    getIsPremium() async => (await _prefs).getBool(_keyPremium) ?? false;

  Future<void> saveProfileId(String profileId) async =>
      (await _prefs).setString(_keyProfileId, profileId);

  /// Devuelve true si existe un token guardado (sesión activa).
  Future<bool> hasSession() async => (await getToken()) != null;

  // ── Logout: borra todo ──

  Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyProfileId);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyPremium);
  }
}
