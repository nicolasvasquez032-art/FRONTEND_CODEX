import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persiste la sesión del candidato en SecureStorage (OWASP M2 Compliance).
/// Claves almacenadas: auth_token, user_id, profile_id, user_role.
class SecureStorage {
  static const _keyToken     = 'auth_token';
  static const _keyUserId    = 'user_id';
  static const _keyProfileId = 'profile_id';
  static const _keyRole      = 'user_role';
  static const _keyPremium   = 'is_premium';

  final _storage = const FlutterSecureStorage();

  // ── Guardar sesión completa tras login / registro ──

  Future<void> saveSession({
    required String token,
    required String userId,
    required String profileId,
    required String role,
    bool isPremium = false,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyProfileId, value: profileId);
    await _storage.write(key: _keyRole, value: role);
    await _storage.write(key: _keyPremium, value: isPremium.toString());
  }

  // ── Lectura individual ──

  Future<String?> getToken()     async => await _storage.read(key: _keyToken);
  Future<String?> getUserId()    async => await _storage.read(key: _keyUserId);
  Future<String?> getProfileId() async => await _storage.read(key: _keyProfileId);
  Future<String?> getRole()      async => await _storage.read(key: _keyRole);
  Future<bool>    getIsPremium() async {
    final val = await _storage.read(key: _keyPremium);
    return val == 'true';
  }

  Future<void> saveProfileId(String profileId) async =>
      await _storage.write(key: _keyProfileId, value: profileId);

  /// Devuelve true si existe un token guardado (sesión activa).
  Future<bool> hasSession() async => (await getToken()) != null;

  // ── Logout: borra todo ──

  Future<void> clearSession() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyProfileId);
    await _storage.delete(key: _keyRole);
    await _storage.delete(key: _keyPremium);
  }
}
