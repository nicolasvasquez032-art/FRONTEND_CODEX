import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:talentmatch/core/utils/format_helper.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
    await initializeDateFormatting('en', null);
  });

  group('FormatHelper - Moneda y Rango Salarial', () {
    test('Formato en español usa punto (.) como separador de miles y sufijo COP', () {
      final range = FormatHelper.formatSalaryRange(
        min: 4500,
        max: 7000,
        isSpanish: true,
      );
      expect(range, '\$ 4.500 – \$ 7.000 COP');
    });

    test('Formato en inglés usa coma (,) como separador de miles y sufijo USD', () {
      final range = FormatHelper.formatSalaryRange(
        min: 4500,
        max: 7000,
        isSpanish: false,
      );
      expect(range, '\$4,500 – \$7,000 USD');
    });

    test('Límite inferior único (Desde / From)', () {
      final es = FormatHelper.formatSalaryRange(min: 4500, isSpanish: true);
      final en = FormatHelper.formatSalaryRange(min: 4500, isSpanish: false);
      expect(es, 'Desde \$ 4.500 COP');
      expect(en, 'From \$4,500 USD');
    });

    test('Salario no indicado / a convenir', () {
      final es = FormatHelper.formatSalaryRange(isSpanish: true);
      final en = FormatHelper.formatSalaryRange(isSpanish: false);
      expect(es, 'Salario a convenir');
      expect(en, 'Salary negotiable');
    });

    test('Detección de divisa explícita desde la descripción', () {
      const desc = 'Puesto remoto. *Salario expresado en USD* competitivo.';
      final range = FormatHelper.formatSalaryRange(
        min: 3000,
        max: 5000,
        isSpanish: true,
        contextText: desc,
      );
      expect(range, '\$ 3.000 – \$ 5.000 USD');
    });
  });

  group('FormatHelper - Fechas Adaptativas (intl)', () {
    final fixedDate = DateTime(2026, 10, 12);

    test('Fecha corta en español e inglés', () {
      final es = FormatHelper.formatDate(fixedDate, isSpanish: true, full: false);
      final en = FormatHelper.formatDate(fixedDate, isSpanish: false, full: false);

      // En español debe contener '12' y 'oct'
      expect(es.toLowerCase(), contains('12'));
      expect(es.toLowerCase(), contains('oct'));

      // En inglés debe ser 'Oct 12'
      expect(en, 'Oct 12');
    });

    test('Fecha completa en español e inglés', () {
      final es = FormatHelper.formatDate(fixedDate, isSpanish: true, full: true);
      final en = FormatHelper.formatDate(fixedDate, isSpanish: false, full: true);

      expect(es.toLowerCase(), contains('12 de octubre de 2026'));
      expect(en, 'October 12, 2026');
    });
  });
}
