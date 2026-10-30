import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:talentmatch/core/network/api_client.dart';
import 'package:talentmatch/core/storage/secure_storage.dart';
import 'package:talentmatch/data/repositories/auth_repository_impl.dart';
import 'package:talentmatch/presentation/auth/register_screen.dart';
import 'package:talentmatch/presentation/shared/providers/auth_provider.dart';
import 'package:talentmatch/presentation/shared/providers/locale_provider.dart';

import 'package:talentmatch/l10n/app_localizations.dart';
import 'package:talentmatch/presentation/shared/widgets/brand_logo.dart';

void main() {
  Widget createTestWidget() {
    final storage = SecureStorage();
    final apiClient = ApiClient(storage);
    final authRepo = AuthRepositoryImpl(apiClient, storage);
    final authProvider = AuthProvider(authRepo);
    final localeProvider = LocaleProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('es'),
        home: RegisterScreen(),
      ),
    );
  }

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('renders TalentMatch register screen with Figma design and elements', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget());
    await tester.pump(const Duration(milliseconds: 200));

    // 1. Top bar logo
    expect(find.byType(BrandFull), findsOneWidget);

    // 2. Hero Headline
    expect(find.text('Conecta con tu futuro.'), findsOneWidget);

    // 3. Card Title and Stepper
    expect(find.text('Crear cuenta'), findsWidgets);
    expect(find.text('PASO 1 DE 3'), findsOneWidget);
    expect(find.text('Cuenta'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Preferencias'), findsOneWidget);

    // 4. Role Selector
    expect(find.text('Candidato'), findsOneWidget);
    expect(find.text('Busco empleo'), findsOneWidget);
    expect(find.text('Empresa'), findsOneWidget);
    expect(find.text('Busco talento'), findsOneWidget);

    // 5. Input Fields
    expect(find.text('Nombre completo'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Confirmar contraseña'), findsOneWidget);

    // 6. Password checklist
    expect(find.text('La contraseña debe tener:'), findsOneWidget);
    expect(find.text('Mínimo 8 caracteres'), findsOneWidget);
    expect(find.text('Una mayúscula y una minúscula'), findsOneWidget);
    expect(find.text('Al menos un número'), findsOneWidget);
    expect(find.text('Un carácter especial'), findsOneWidget);

    // 7. Social buttons & footer
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('LinkedIn'), findsOneWidget);
    expect(find.textContaining('¿Ya tienes cuenta?'), findsOneWidget);
    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(find.text('Tu talento, en un espacio seguro.'), findsOneWidget);
  });

  testWidgets('switches to Empresa role hiding candidate specific fields', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget());
    await tester.pump(const Duration(milliseconds: 200));

    // Tap Empresa card
    await tester.tap(find.text('Empresa'));
    await tester.pump(const Duration(milliseconds: 300));

    // In company mode, "PASO 1 DE 1" and Nombre completo is hidden
    expect(find.text('PASO 1 DE 1'), findsOneWidget);
    expect(find.text('Nombre completo'), findsNothing);
  });
}
