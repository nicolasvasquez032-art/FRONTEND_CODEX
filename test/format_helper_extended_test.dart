import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:talentmatch/core/utils/format_helper.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
    await initializeDateFormatting('en', null);
  });

  group('FormatHelper Extended Tests', () {
    test('formatNumber maneja enteros y decimales', () {
      expect(FormatHelper.formatNumber(1250, isSpanish: true), '1.250');
      expect(FormatHelper.formatNumber(1250, isSpanish: false), '1,250');
      expect(FormatHelper.formatNumber(1250.5, isSpanish: true, decimals: 2), '1.250,50');
      expect(FormatHelper.formatNumber(1250.5, isSpanish: false, decimals: 2), '1,250.50');
    });

    test('resolveCurrencyCode y formatCurrency', () {
      expect(FormatHelper.resolveCurrencyCode(contextText: 'Salario en EUR para Europa'), 'EUR');
      expect(FormatHelper.resolveCurrencyCode(contextText: 'Pago en USD'), 'USD');
      expect(FormatHelper.resolveCurrencyCode(contextText: 'Pago en COP'), 'COP');
      expect(FormatHelper.resolveCurrencyCode(contextText: '', isSpanish: true), 'COP');
      expect(FormatHelper.resolveCurrencyCode(contextText: '', isSpanish: false), 'USD');

      expect(FormatHelper.formatCurrency(5000, isSpanish: true, showCurrencyCode: true), '\$ 5.000 COP');
      expect(FormatHelper.formatCurrency(5000, isSpanish: false, showCurrencyCode: true), '\$5,000 USD');
      expect(FormatHelper.formatCurrency(5000, isSpanish: true, showCurrencyCode: false), '\$ 5.000');
      expect(FormatHelper.formatCurrency(5000, isSpanish: false, showCurrencyCode: false), '\$5,000');
    });

    test('formatSalaryRange para todos los escenarios', () {
      expect(FormatHelper.formatSalaryRange(min: null, max: null, isSpanish: true), 'Salario a convenir');
      expect(FormatHelper.formatSalaryRange(min: null, max: null, isSpanish: false), 'Salary negotiable');

      expect(FormatHelper.formatSalaryRange(min: 3000, max: null, isSpanish: true), 'Desde \$ 3.000 COP');
      expect(FormatHelper.formatSalaryRange(min: 3000, max: null, isSpanish: false), 'From \$3,000 USD');

      expect(FormatHelper.formatSalaryRange(min: null, max: 7000, isSpanish: true), 'Hasta \$ 7.000 COP');
      expect(FormatHelper.formatSalaryRange(min: null, max: 7000, isSpanish: false), 'Up to \$7,000 USD');

      expect(FormatHelper.formatSalaryRange(min: 3000, max: 7000, isSpanish: true, showCurrencyCode: false), '\$ 3.000 – \$ 7.000');
    });

    test('formatDate corto y completo', () {
      final date = DateTime(2026, 10, 15);
      expect(FormatHelper.formatDate(date, isSpanish: true, full: false), isNotEmpty);
      expect(FormatHelper.formatDate(date, isSpanish: true, full: true), contains('2026'));
      expect(FormatHelper.formatDate(date, isSpanish: false, full: false), isNotEmpty);
      expect(FormatHelper.formatDate(date, isSpanish: false, full: true), contains('2026'));
    });

    test('formatRelativeTime para diferentes duraciones', () {
      final now = DateTime.now();

      final justNow = now.subtract(const Duration(seconds: 30));
      expect(FormatHelper.formatRelativeTime(justNow, isSpanish: true), 'Justo ahora');
      expect(FormatHelper.formatRelativeTime(justNow, isSpanish: false), 'Just now');

      final minutesAgo = now.subtract(const Duration(minutes: 20));
      expect(FormatHelper.formatRelativeTime(minutesAgo, isSpanish: true), 'Hace 20 min');
      expect(FormatHelper.formatRelativeTime(minutesAgo, isSpanish: false), '20m ago');

      final hoursAgo = now.subtract(const Duration(hours: 5));
      expect(FormatHelper.formatRelativeTime(hoursAgo, isSpanish: true), 'Hace 5 h');
      expect(FormatHelper.formatRelativeTime(hoursAgo, isSpanish: false), '5h ago');

      final yesterday = now.subtract(const Duration(days: 1));
      expect(FormatHelper.formatRelativeTime(yesterday, isSpanish: true), 'Ayer');
      expect(FormatHelper.formatRelativeTime(yesterday, isSpanish: false), 'Yesterday');

      final daysAgo = now.subtract(const Duration(days: 4));
      expect(FormatHelper.formatRelativeTime(daysAgo, isSpanish: true), 'Hace 4 días');
      expect(FormatHelper.formatRelativeTime(daysAgo, isSpanish: false), '4d ago');

      final longAgo = now.subtract(const Duration(days: 20));
      expect(FormatHelper.formatRelativeTime(longAgo, isSpanish: true), isNotEmpty);
      expect(FormatHelper.formatRelativeTime(longAgo, isSpanish: false), isNotEmpty);
    });
  });
}
