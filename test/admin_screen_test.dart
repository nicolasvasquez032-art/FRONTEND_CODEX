import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:talentmatch/presentation/admin/admin_dashboard_screen.dart';
import 'package:talentmatch/presentation/shared/providers/admin_provider.dart';
import 'package:talentmatch/presentation/shared/providers/auth_provider.dart';
import 'package:talentmatch/presentation/shared/providers/locale_provider.dart';
import 'admin_provider_test.dart';

class FakeAuthForAdmin extends Fake implements AuthProvider {
  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('renders AdminDashboardScreen with KPIs, Tabs, and Moderation', (tester) async {
    final fakeRepo = FakeAdminRepo();
    final adminProvider = AdminProvider(fakeRepo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
          ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthForAdmin()),
          ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
        ],
        child: const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      ),
    );

    // Initial loading or post-frame callback
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Brand / Admin Badge
    expect(find.text('ADMIN'), findsOneWidget);
    expect(find.text('Métricas & IA'), findsOneWidget);
    expect(find.text('Moderación'), findsOneWidget);

    // Verify KPI Cards
    expect(find.text('Candidatos'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('Vacantes Activas'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('Efectividad Matching Semántico'), findsOneWidget);

    // Switch to Moderation tab
    await tester.tap(find.text('Moderación'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify moderation filter chips
    expect(find.text('Todas (3)'), findsOneWidget);
    expect(find.text('Activas (1)'), findsOneWidget);
    expect(find.text('Pausadas (1)'), findsOneWidget);
    expect(find.text('Cerradas (1)'), findsOneWidget);

    // Verify vacantes in moderation list
    expect(find.text('Desarrollador Flutter'), findsOneWidget);
    expect(find.text('Asesor Comercial'), findsOneWidget);
    expect(find.text('Contador Senior'), findsOneWidget);

    // Verify action buttons
    expect(find.text('Pausar'), findsOneWidget); // For v1 (activa)
    expect(find.text('Activar'), findsNWidgets(2)); // For v2 (pausada) and v3 (cerrada)
  });
}
