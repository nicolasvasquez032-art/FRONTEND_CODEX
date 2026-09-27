import '../entities/user_session.dart';

/// Contrato de autenticación que la capa de presentación conoce.
/// La implementación concreta vive en data/repositories/.
abstract class AuthRepository {
  /// Inicia sesión. Persiste el token. Devuelve la sesión.
  Future<UserSession> login({
    required String email,
    required String password,
  });

  /// Registra un nuevo candidato. Persiste el token. Devuelve la sesión.
  Future<UserSession> registerCandidate({
    required String email,
    required String password,
    required String fullName,
    List<String> skills,
    int experienceYears,
    String? location,
    String? education,
  });

  /// Envía un correo de recuperación de contraseña.
  Future<void> requestPasswordReset(String email);

  /// Cierra sesión borrando los datos persistidos.
  Future<void> logout();

  /// Restaura la sesión desde storage si existe.
  Future<UserSession?> restoreSession();
}
