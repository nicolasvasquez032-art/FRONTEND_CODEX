import 'package:intl/intl.dart';

/// Utilidad adaptativa de formateo de Moneda, Rango Salarial y Fechas (`intl`).
///
/// Soporta estándares de localización:
/// - Español (`es`): `$ 4.500 – $ 7.000 COP` / `12 de oct.` / `Hace 3 días`
/// - Inglés  (`en`): `$4,500 – $7,000 USD` / `Oct 12` / `3d ago`
class FormatHelper {
  // ── Formateo Numérico y de Moneda ──────────────────────────────────────────

  /// Formatea un número entero o decimal según la configuración regional:
  /// - Español: separador de miles con punto (.) -> 4.500
  /// - Inglés:  separador de miles con coma  (,) -> 4,500
  static String formatNumber(num value, {bool isSpanish = true, int decimals = 0}) {
    final pattern = decimals > 0 ? '#,##0.${'0' * decimals}' : '#,##0';
    final formatter = NumberFormat(pattern, isSpanish ? 'es_CO' : 'en_US');
    return formatter.format(value);
  }

  /// Resuelve la divisa adecuada según el contexto:
  /// Si el texto indica explícitamente USD o COP, lo respeta.
  /// Si no, infiere por mercado/idioma (COP en español, USD en inglés).
  static String resolveCurrencyCode({String? contextText, bool isSpanish = true}) {
    if (contextText != null && contextText.isNotEmpty) {
      final reg = RegExp(r'\b(USD|COP|EUR)\b', caseSensitive: false);
      final match = reg.firstMatch(contextText);
      if (match != null) {
        return match.group(1)!.toUpperCase();
      }
    }
    return isSpanish ? 'COP' : 'USD';
  }

  /// Formatea un valor monetario individual:
  /// - Español: `$ 4.500 COP`
  /// - Inglés:  `$4,500 USD`
  static String formatCurrency(
    num value, {
    bool isSpanish = true,
    String? currencyCode,
    String? contextText,
    bool showCurrencyCode = true,
  }) {
    final code = currencyCode ?? resolveCurrencyCode(contextText: contextText, isSpanish: isSpanish);
    final formattedNumber = formatNumber(value, isSpanish: isSpanish);
    final symbol = isSpanish ? '\$ ' : '\$';
    
    if (showCurrencyCode) {
      return '$symbol$formattedNumber $code';
    }
    return '$symbol$formattedNumber';
  }

  /// Formatea un rango salarial (mínimo y máximo):
  /// - Español: `$ 4.500 – $ 7.000 COP`
  /// - Inglés:  `$4,500 – $7,000 USD`
  /// - Casos de un solo límite: `Desde $ 4.500 COP` / `From $4,500 USD`
  /// - Sin salario: `Salario a convenir` / `Salary negotiable`
  static String formatSalaryRange({
    double? min,
    double? max,
    bool isSpanish = true,
    String? currencyCode,
    String? contextText,
    bool showCurrencyCode = true,
  }) {
    if (min == null && max == null) {
      return isSpanish ? 'Salario a convenir' : 'Salary negotiable';
    }

    final code = currencyCode ?? resolveCurrencyCode(contextText: contextText, isSpanish: isSpanish);
    final codeSuffix = showCurrencyCode ? ' $code' : '';

    if (min != null && max != null) {
      final minFormatted = formatNumber(min, isSpanish: isSpanish);
      final maxFormatted = formatNumber(max, isSpanish: isSpanish);
      final symbol = isSpanish ? '\$ ' : '\$';
      return '$symbol$minFormatted – $symbol$maxFormatted$codeSuffix';
    }

    if (min != null) {
      final minFormatted = formatNumber(min, isSpanish: isSpanish);
      final prefix = isSpanish ? 'Desde \$ ' : 'From \$';
      return '$prefix$minFormatted$codeSuffix';
    }

    final maxFormatted = formatNumber(max!, isSpanish: isSpanish);
    final prefix = isSpanish ? 'Hasta \$ ' : 'Up to \$';
    return '$prefix$maxFormatted$codeSuffix';
  }

  // ── Formateo de Fechas Adaptativo ──────────────────────────────────────────

  /// Formatea una fecha según el idioma:
  /// - Corto (`full == false`):
  ///   - Español: `12 de oct.`
  ///   - Inglés:  `Oct 12`
  /// - Completo (`full == true`):
  ///   - Español: `12 de octubre de 2026`
  ///   - Inglés:  `October 12, 2026`
  static String formatDate(DateTime date, {bool isSpanish = true, bool full = false}) {
    try {
      if (full) {
        return isSpanish
            ? DateFormat("d 'de' MMMM 'de' y", 'es').format(date)
            : DateFormat("MMMM d, y", 'en').format(date);
      } else {
        return isSpanish
            ? DateFormat("d 'de' MMM", 'es').format(date)
            : DateFormat("MMM d", 'en').format(date);
      }
    } catch (_) {
      // Fallback seguro sin intl symbols
      final monthsEs = ['ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.', 'jul.', 'ago.', 'sep.', 'oct.', 'nov.', 'dic.'];
      final monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final mIdx = (date.month - 1).clamp(0, 11);
      if (isSpanish) {
        return '${date.day} de ${monthsEs[mIdx]}';
      } else {
        return '${monthsEn[mIdx]} ${date.day}';
      }
    }
  }

  /// Formatea tiempo relativo inteligente:
  /// - Hace < 1h: `Hace 15 min` / `15m ago`
  /// - Hace < 24h: `Hace 3 h` / `3h ago`
  /// - 1 día: `Ayer` / `Yesterday`
  /// - Menor a 7 días: `Hace 4 días` / `4d ago`
  /// - Mayor a 7 días: `12 de oct.` / `Oct 12`
  static String formatRelativeTime(DateTime date, {bool isSpanish = true}) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return isSpanish ? 'Justo ahora' : 'Just now';
    }
    if (diff.inMinutes < 60) {
      return isSpanish ? 'Hace ${diff.inMinutes} min' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return isSpanish ? 'Hace ${diff.inHours} h' : '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) {
      return isSpanish ? 'Ayer' : 'Yesterday';
    }
    if (diff.inDays < 7) {
      return isSpanish ? 'Hace ${diff.inDays} días' : '${diff.inDays}d ago';
    }
    return formatDate(date, isSpanish: isSpanish, full: false);
  }
}
