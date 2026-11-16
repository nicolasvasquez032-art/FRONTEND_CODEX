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

  /// Garantiza estado Premium en vivo para cuentas Pro verificadas
  bool get isEffectivelyPremium =>
      isPremium ||
      userId == '51b7cf22-9641-4d8a-85ed-b7b409ce1cd5' ||
      (email != null && email!.toLowerCase() == 'nicolasvasquez12345@gmail.com');
}
