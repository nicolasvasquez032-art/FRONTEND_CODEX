import 'package:flutter_test/flutter_test.dart';
import 'package:talentmatch/core/utils/validators.dart';

void main() {
  group('Validators - Email', () {
    test('Acepta correos electrónicos válidos', () {
      expect(Validators.isValidEmail('candidato@test.com'), isTrue);
      expect(Validators.isValidEmail('empresa.talent@match.co'), isTrue);
      expect(Validators.isValidEmail('usuario+tag@sub.domain.org'), isTrue);
    });

    test('Rechaza correos inválidos o vacíos', () {
      expect(Validators.isValidEmail(''), isFalse);
      expect(Validators.isValidEmail(null), isFalse);
      expect(Validators.isValidEmail('correo_sin_arroba.com'), isFalse);
      expect(Validators.isValidEmail('correo@dominio_sin_extension'), isFalse);
      expect(Validators.isValidEmail('espacios en blanco@test.com'), isFalse);
    });
  });

  group('Validators - Fortaleza de Contraseña', () {
    test('Contraseña vacía retorna puntuación 0 y débil', () {
      final res = Validators.evaluatePassword('');
      expect(res.metCount, 0);
      expect(res.strength, PasswordStrength.weak);
      expect(res.isValid, isFalse);
    });

    test('Contraseña corta sin caracteres especiales es débil', () {
      final res = Validators.evaluatePassword('abc12');
      expect(res.hasMinLength, isFalse);
      expect(res.hasNumber, isTrue);
      expect(res.strength, PasswordStrength.weak);
      expect(res.isValid, isFalse);
    });

    test('Contraseña que cumple 3 requisitos es media', () {
      // 8 caracteres, mayúscula/minúscula, número, pero SIN especial
      final res = Validators.evaluatePassword('Abcdefg12');
      expect(res.hasMinLength, isTrue);
      expect(res.hasUpperAndLower, isTrue);
      expect(res.hasNumber, isTrue);
      expect(res.hasSpecialChar, isFalse);
      expect(res.metCount, 3);
      expect(res.strength, PasswordStrength.medium);
      expect(res.isValid, isFalse);
    });

    test('Contraseña completa que cumple todos los requisitos es fuerte y válida', () {
      final res = Validators.evaluatePassword('Password123*');
      expect(res.hasMinLength, isTrue);
      expect(res.hasUpperAndLower, isTrue);
      expect(res.hasNumber, isTrue);
      expect(res.hasSpecialChar, isTrue);
      expect(res.metCount, 4);
      expect(res.strength, PasswordStrength.strong);
      expect(res.isValid, isTrue);
    });
  });

  group('Validators - Coincidencia de Contraseñas', () {
    test('Coinciden exactamente', () {
      expect(Validators.passwordsMatch('Segura123!', 'Segura123!'), isTrue);
    });

    test('No coinciden cuando difieren en mayúsculas o caracteres', () {
      expect(Validators.passwordsMatch('Segura123!', 'segura123!'), isFalse);
      expect(Validators.passwordsMatch('Segura123!', 'Segura123'), isFalse);
      expect(Validators.passwordsMatch('', ''), isFalse);
      expect(Validators.passwordsMatch(null, 'pwd'), isFalse);
    });
  });
}
