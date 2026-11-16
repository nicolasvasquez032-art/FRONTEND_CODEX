import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:talentmatch/presentation/legal/legal_screen.dart';
import 'package:talentmatch/presentation/shared/providers/locale_provider.dart';

void main() {
  Widget buildTestWidget({
    int initialTab = 0,
    VoidCallback? onAccept,
    bool isModal = false,
  }) {
    final localeProvider = LocaleProvider();
    localeProvider.setLocale(const Locale('es'));
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        home: LegalScreen(
          initialTab: initialTab,
          onAccept: onAccept,
          isModal: isModal,
        ),
      ),
    );
  }

  testWidgets('renders LegalScreen with Colombian legal compliance elements', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // 1. Header & Badges
    expect(find.text('Ley 1581 / 2012'), findsOneWidget);
    expect(find.text('Marco Legal y Políticas de Privacidad'), findsOneWidget);

    // 2. Tabs
    expect(find.text('Términos'), findsOneWidget);
    expect(find.text('Privacidad'), findsOneWidget);
    expect(find.text('Cookies'), findsOneWidget);

    // 3. Colombian labor law terms in tab 0
    expect(find.text('1. Objeto y Aceptación de los Términos'), findsOneWidget);
    expect(find.text('2. Naturaleza del Servicio de Intermediación Digital'), findsOneWidget);
  });

  testWidgets('switches to Privacidad tab and displays Habeas Data Ley 1581', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget(initialTab: 1));
    await tester.pumpAndSettle();

    // Should display Privacy content
    expect(find.text('1. Marco Legal y Compromiso de Protección de Datos'), findsOneWidget);
    expect(find.textContaining('Ley Estatutaria 1581 de 2012'), findsWidgets);
    expect(find.textContaining('Superintendencia de Industria y Comercio'), findsWidgets);
  });

  testWidgets('filters sections dynamically via search bar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Type "Gratuidad" in search bar
    await tester.enterText(find.byType(TextField), 'Gratuidad');
    await tester.pumpAndSettle();

    // Only matching section is shown
    expect(find.text('3. Principio de Gratuidad Estricta para Candidatos'), findsOneWidget);
    expect(find.text('1. Objeto y Aceptación de los Términos'), findsNothing);
  });

  testWidgets('triggers onAccept callback when Aceptar button is clicked', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    bool accepted = false;
    await tester.pumpWidget(buildTestWidget(
      onAccept: () => accepted = true,
    ));
    await tester.pumpAndSettle();

    final acceptBtn = find.text('Aceptar y continuar');
    expect(acceptBtn, findsOneWidget);

    await tester.tap(acceptBtn);
    await tester.pumpAndSettle();

    expect(accepted, isTrue);
  });
}
