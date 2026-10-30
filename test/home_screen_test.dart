import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:talentmatch/core/network/api_client.dart';
import 'package:talentmatch/core/storage/secure_storage.dart';
import 'package:talentmatch/data/repositories/auth_repository_impl.dart';
import 'package:talentmatch/data/repositories/notificacion_repository_impl.dart';
import 'package:talentmatch/data/repositories/postulacion_repository_impl.dart';
import 'package:talentmatch/data/repositories/recomendacion_repository_impl.dart';
import 'package:talentmatch/data/repositories/vacante_repository_impl.dart';
import 'package:talentmatch/presentation/home/home_screen.dart';
import 'package:talentmatch/presentation/shared/providers/auth_provider.dart';
import 'package:talentmatch/presentation/shared/providers/locale_provider.dart';
import 'package:talentmatch/presentation/shared/providers/notificaciones_provider.dart';
import 'package:talentmatch/presentation/shared/providers/postulaciones_provider.dart';
import 'package:talentmatch/presentation/shared/providers/recomendaciones_provider.dart';
import 'package:talentmatch/presentation/shared/providers/vacantes_provider.dart';
import 'package:talentmatch/presentation/shared/widgets/brand_logo.dart';

void main() {
  Widget createHomeScreenTestWidget() {
    final storage = SecureStorage();
    final apiClient = ApiClient(storage);
    final authRepo = AuthRepositoryImpl(apiClient, storage);
    final vacanteRepo = VacanteRepositoryImpl(apiClient);
    final postRepo = PostulacionRepositoryImpl(apiClient);
    final recRepo = RecomendacionRepositoryImpl(apiClient);
    final notifRepo = NotificacionRepositoryImpl(apiClient);

    final authProvider = AuthProvider(authRepo);
    final localeProvider = LocaleProvider();
    localeProvider.setLocale(const Locale('es'));
    final vacantesProvider = VacantesProvider(vacanteRepo);
    final postProvider = PostulacionesProvider(postRepo);
    final recProvider = RecomendacionesProvider(recRepo);
    final notifProvider = NotificacionesProvider(notifRepo);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: vacantesProvider),
        ChangeNotifierProvider.value(value: postProvider),
        ChangeNotifierProvider.value(value: recProvider),
        ChangeNotifierProvider.value(value: notifProvider),
      ],
      child: MaterialApp(
        home: HomeScreen(onExplore: () {}),
      ),
    );
  }

  testWidgets('renders Figma HomeScreen with header, animated hero, search, chips and jobs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createHomeScreenTestWidget());
    await tester.pump(const Duration(milliseconds: 100));

    // 1. Top bar: BrandFull logo, language switch, messages and notifications buttons
    expect(find.byType(BrandFull), findsOneWidget);
    expect(find.text('ES'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

    // 2. Hero Section: Subtitle & Title & 3D briefcase
    expect(find.text('TU TALENTO, MÁS LEJOS'), findsOneWidget);
    expect(find.textContaining('Tu próximo reto', findRichText: true), findsOneWidget);
    expect(find.textContaining('empieza aquí', findRichText: true), findsOneWidget);
    expect(find.byType(Image), findsWidgets);

    // 3. Search Bar
    expect(find.text('Cargo, habilidad o empresa...'), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

    // 4. Filter Chips
    expect(find.text('Remoto'), findsWidgets);
    expect(find.text('Tecnología'), findsOneWidget);
    expect(find.text('Colombia'), findsOneWidget);

    // 5. Section Header
    expect(find.text('Recomendadas para ti'), findsOneWidget);
    expect(find.text('Oportunidades que conectan con tu perfil'), findsOneWidget);
    expect(find.text('Ver todas '), findsOneWidget);

    // 6. Job Cards from Figma
    expect(find.text('Desarrollador Python Senior'), findsOneWidget);
    expect(find.text('Desarrollador Python Junior'), findsOneWidget);
    expect(find.text('\$ 3.000 – \$ 5.000 COP'), findsOneWidget);
    expect(find.text('\$ 1.500 – \$ 2.500 COP'), findsOneWidget);
    expect(find.text('98% match'), findsOneWidget);
    expect(find.text('94% match'), findsOneWidget);
  });
}
