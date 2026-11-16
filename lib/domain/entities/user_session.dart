/// Sesión del usuario autenticado en memoria (no persiste directamente).
/// Los datos vienen de SecureStorage al iniciar la app.
class UserSession {
  final String userId;
  final String profileId;
  final String role; // 'candidate' | 'company' | 'admin'
  final bool isPremium;
  final String? email;
  final bool isNewUser;

  const UserSession({
    required this.userId,
    required this.profileId,
    required this.role,
    this.isPremium = false,
    this.email,
    this.isNewUser = false,
  });

  bool get isCandidate => role == 'candidate';
  bool get isCompany   => role == 'company';
  bool get isAdmin     => role == 'admin';
}
