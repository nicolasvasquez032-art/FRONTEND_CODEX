/// Utilidades y validaciones reactivas para formularios de autenticación y datos de usuario.
enum PasswordStrength {
  weak,
  medium,
  strong,
}

class PasswordValidationResult {
  final bool hasMinLength;
  final bool hasUpperAndLower;
  final bool hasNumber;
  final bool hasSpecialChar;

  const PasswordValidationResult({
    required this.hasMinLength,
    required this.hasUpperAndLower,
    required this.hasNumber,
    required this.hasSpecialChar,
  });

  int get metCount =>
      (hasMinLength ? 1 : 0) +
      (hasUpperAndLower ? 1 : 0) +
      (hasNumber ? 1 : 0) +
      (hasSpecialChar ? 1 : 0);

  double get fraction => metCount / 4.0;

  PasswordStrength get strength {
    if (metCount <= 2) return PasswordStrength.weak;
    if (metCount == 3) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  bool get isValid => metCount == 4;
}

class Validators {
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  static final RegExp _upperRegExp = RegExp(r'[A-Z]');
  static final RegExp _lowerRegExp = RegExp(r'[a-z]');
  static final RegExp _numberRegExp = RegExp(r'[0-9]');
  static final RegExp _specialRegExp =
      RegExp(r'[!@#\$%\^&\*(),.?":{}|<>\-_\+=;\[\]~`\\]');

  /// Valida si el formato de correo electrónico es sintácticamente correcto.
  static bool isValidEmail(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    return _emailRegExp.hasMatch(email.trim());
  }

  /// Evalúa los requisitos de seguridad de una contraseña.
  static PasswordValidationResult evaluatePassword(String password) {
    return PasswordValidationResult(
      hasMinLength: password.length >= 8,
      hasUpperAndLower:
          _upperRegExp.hasMatch(password) && _lowerRegExp.hasMatch(password),
      hasNumber: _numberRegExp.hasMatch(password),
      hasSpecialChar: _specialRegExp.hasMatch(password),
    );
  }

  /// Valida si dos contraseñas coinciden exactamente.
  static bool passwordsMatch(String? pwd1, String? pwd2) {
    if (pwd1 == null || pwd2 == null) return false;
    return pwd1 == pwd2 && pwd1.isNotEmpty;
  }
}
