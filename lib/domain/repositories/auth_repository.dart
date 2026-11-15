import '../entities/user_session.dart';

/// Contrato de autenticación que la capa de presentación conoce.
/// La implementación concreta vive en data/repositories/.
abstract class AuthRepository {
  /// Inicia sesión. Persiste el token. Devuelve la sesión.
  Future<UserSession> login({
    required String email,
    required String password,
  });

  Future<void> registerCandidate({
    required String email,
    required String password,
    required String fullName,
    List<String> skills,
    int experienceYears,
    String? location,
    String? education,
  });

  Future<void> registerCompany({
    required String email,
    required String password,
  });

  /// Envía un correo de recuperación de contraseña.
  Future<void> requestPasswordReset(String email);

  /// Inicia sesión o registra candidato con proveedor social (Google, Facebook, LinkedIn).
  Future<UserSession> loginWithSocial({
    required String provider,
    String? token,
    String? email,
    String? fullName,
  });

  /// Procesa y guarda los tokens de autenticación obtenidos vía OAuth social.
  Future<UserSession> handleSocialAuthToken({
    required String token,
    required String refreshToken,
  });

  /// Cierra sesión borrando los datos persistidos.
  Future<void> logout();

  /// Restaura la sesión desde storage si existe.
  Future<UserSession?> restoreSession();
}
