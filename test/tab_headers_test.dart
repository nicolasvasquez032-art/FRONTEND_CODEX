import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:talentmatch/core/network/api_client.dart';
import 'package:talentmatch/core/storage/secure_storage.dart';
import 'package:talentmatch/data/repositories/auth_repository_impl.dart';
import 'package:talentmatch/data/repositories/notificacion_repository_impl.dart';
import 'package:talentmatch/data/repositories/perfil_repository_impl.dart';
import 'package:talentmatch/data/repositories/postulacion_repository_impl.dart';
import 'package:talentmatch/data/repositories/vacante_repository_impl.dart';
import 'package:talentmatch/presentation/applications/applications_screen.dart';
import 'package:talentmatch/presentation/explore/explore_screen.dart';
import 'package:talentmatch/presentation/profile/profile_screen.dart';
import 'package:talentmatch/presentation/shared/providers/auth_provider.dart';
import 'package:talentmatch/presentation/shared/providers/locale_provider.dart';
import 'package:talentmatch/presentation/shared/providers/notificaciones_provider.dart';
import 'package:talentmatch/presentation/shared/providers/perfil_provider.dart';
import 'package:talentmatch/presentation/shared/providers/postulaciones_provider.dart';
import 'package:talentmatch/presentation/shared/providers/vacantes_provider.dart';
import 'package:talentmatch/presentation/shared/widgets/brand_logo.dart';
import 'package:talentmatch/presentation/shared/widgets/talentmatch_top_header.dart';
import 'package:talentmatch/l10n/app_localizations.dart';

void main() {
  Widget createTabTestWidget(Widget child) {
    final storage = SecureStorage();
    final apiClient = ApiClient(storage);
    final authRepo = AuthRepositoryImpl(apiClient, storage);
    final vacanteRepo = VacanteRepositoryImpl(apiClient);
    final postRepo = PostulacionRepositoryImpl(apiClient);
    final notifRepo = NotificacionRepositoryImpl(apiClient);
    final perfilRepo = PerfilRepositoryImpl(apiClient);

    final authProvider = AuthProvider(authRepo);
    final localeProvider = LocaleProvider();
    localeProvider.setLocale(const Locale('es'));
    final vacantesProvider = VacantesProvider(vacanteRepo);
    final postProvider = PostulacionesProvider(postRepo);
    final notifProvider = NotificacionesProvider(notifRepo);
    final perfilProvider = PerfilProvider(perfilRepo);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: vacantesProvider),
        ChangeNotifierProvider.value(value: postProvider),
        ChangeNotifierProvider.value(value: notifProvider),
        ChangeNotifierProvider.value(value: perfilProvider),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  testWidgets('ExploreScreen renders TalentMatchTopHeader with BrandFull, language switch, chat and notification bell', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTabTestWidget(const ExploreScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TalentMatchTopHeader), findsOneWidget);
    expect(find.byType(BrandFull), findsOneWidget);
    expect(find.text('ES'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

    // Figma Explore Hero Section
    expect(find.text('Descubre nuevas oportunidades'), findsOneWidget);
    expect(find.textContaining('Explorar', findRichText: true), findsOneWidget);
    expect(find.textContaining('Empleos', findRichText: true), findsOneWidget);
    expect(find.byType(Image), findsWidgets); // 3D Animated Magnifier Hero

    // Search bar with filter button
    expect(find.text('Buscar empleo...'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

    // Count header & Figma cards
    expect(find.text('20 vacantes encontradas'), findsOneWidget);
    expect(find.text('Desarrollador Python Senior'), findsWidgets);
    expect(find.text('Remoto'), findsWidgets);
    expect(find.text('Backend'), findsWidgets);
    expect(find.text('\$ 3.000 – \$ 5.000 COP'), findsWidgets);

    // Floating map button
    expect(find.text('Ver Mapa'), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
  });

  testWidgets('ApplicationsScreen renders TalentMatchTopHeader with BrandFull, language switch, chat and notification bell', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTabTestWidget(const ApplicationsScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TalentMatchTopHeader), findsOneWidget);
    expect(find.byType(BrandFull), findsOneWidget);
    expect(find.text('ES'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
  });

  testWidgets('ProfileScreen renders TalentMatchTopHeader with BrandFull, language switch, chat and notification bell', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTabTestWidget(const ProfileScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TalentMatchTopHeader), findsOneWidget);
    expect(find.byType(BrandFull), findsOneWidget);
    expect(find.text('ES'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
  });
}
