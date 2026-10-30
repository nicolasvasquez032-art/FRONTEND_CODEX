import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:talentmatch/core/network/api_client.dart';
import 'package:talentmatch/core/storage/secure_storage.dart';
import 'package:talentmatch/data/repositories/auth_repository_impl.dart';
import 'package:talentmatch/presentation/auth/login_screen.dart';
import 'package:talentmatch/presentation/shared/providers/auth_provider.dart';
import 'package:talentmatch/presentation/shared/providers/locale_provider.dart';
import 'package:talentmatch/presentation/shared/widgets/brand_logo.dart';

void main() {
  Widget createTestWidget({Locale initialLocale = const Locale('es')}) {
    final storage = SecureStorage();
    final apiClient = ApiClient(storage);
    final authRepo = AuthRepositoryImpl(apiClient, storage);
    final authProvider = AuthProvider(authRepo);
    final localeProvider = LocaleProvider();
    localeProvider.setLocale(initialLocale);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: MaterialApp(
        locale: initialLocale,
        home: const LoginScreen(),
      ),
    );
  }

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('renders TalentMatch login screen with all Figma design elements', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget(initialLocale: const Locale('es')));
    await tester.pump(const Duration(milliseconds: 100));

    // 1. Top bar
    expect(find.byType(BrandFull), findsOneWidget);
    expect(find.text('ES'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);

    // 2. Headlines
    expect(find.text('Tu talento merece\nun gran empleo.'), findsOneWidget);
    expect(find.text('Conecta con tu próxima oportunidad.'), findsOneWidget);

    // 3. Form elements
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('o continúa con'), findsOneWidget);

    // 4. Social buttons
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('LinkedIn'), findsOneWidget);

    // 5. Footer
    expect(find.text('¿Aún no tienes cuenta? '), findsOneWidget);
    expect(find.text('Regístrate'), findsOneWidget);
  });

  testWidgets('validates required fields on submit with empty form', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget(initialLocale: const Locale('es')));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Ingresa tu correo electrónico'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });

  testWidgets('switches language between ES and EN dynamically', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget(initialLocale: const Locale('es')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Tu talento merece\nun gran empleo.'), findsOneWidget);

    // Switch to EN
    await tester.tap(find.text('EN'));
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Your talent deserves\na great career.'), findsOneWidget);
    expect(find.text('Connect with your next opportunity.'), findsOneWidget);
    expect(find.text('Sign In'), findsNWidgets(2)); // Card title and button label
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot your password?'), findsOneWidget);
    expect(find.text('or continue with'), findsOneWidget);
    expect(find.text("Don't have an account? "), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);

    // Switch back to ES
    await tester.tap(find.text('ES'));
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Tu talento merece\nun gran empleo.'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
