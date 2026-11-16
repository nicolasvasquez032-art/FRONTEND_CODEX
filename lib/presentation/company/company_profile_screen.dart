import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../domain/entities/vacante.dart';
import '../../l10n/app_localizations.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/locale_provider.dart';
import '../shared/providers/vacantes_provider.dart';
import '../shared/widgets/app_toast.dart';
import '../shared/widgets/bouncy_tap.dart';
import '../shared/widgets/colombia_location_picker.dart';
import '../shared/widgets/language_switch_button.dart';
import '../shared/widgets/glass_card.dart';
import '../legal/legal_screen.dart';
import 'premium_subscription_screen.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  String _companyName = '';
  String _companySector = 'Tecnología';
  String _companyLocation = 'Colombia';
  String _companyPlan = 'Plan Gratuito';
  String _companyLogo = '';
  int _companyColorIndex = 0;

  final List<Color> _brandColors = const [
    Color(0xFF2563EB), // Azul Royal
    Color(0xFF0D9488), // Teal
    Color(0xFF7C3AED), // Púrpura
    Color(0xFF0284C7), // Cian
    Color(0xFF059669), // Esmeralda
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosEmpresa();
  }

  Future<void> _cargarDatosEmpresa() async {
    final session = context.read<AuthProvider>().session;
    final prefs = await SharedPreferences.getInstance();
    final uid = session?.userId ?? session?.email ?? '';

    String name = prefs.getString('company_name_$uid') ??
        prefs.getString('company_name_active') ??
        '';

    final userEmail = session?.email;
    if (name.isEmpty && userEmail != null && userEmail.isNotEmpty) {
      final emailPrefix = userEmail.contains('@') ? userEmail.split('@').first : userEmail;
      final clean = emailPrefix.replaceAll(RegExp(r'[0-9_\.]'), ' ').trim();
      name = clean.isNotEmpty
          ? clean.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ')
          : 'Mi Empresa';
    }

    if (mounted) {
      setState(() {
        _companyName = name.isNotEmpty ? name : 'Mi Empresa';
        _companySector = prefs.getString('company_sector_$uid') ?? 'Tecnología';
        _companyLocation = prefs.getString('company_location_$uid') ?? 'Colombia';
        _companyPlan = prefs.getString('company_plan_$uid') ?? 'Plan Gratuito';
        _companyLogo = prefs.getString('company_logo_$uid') ?? '';
        _companyColorIndex = prefs.getInt('company_color_$uid') ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();
    final isEs = localeProvider.isSpanish;
    final vacantesProv = context.watch<VacantesProvider>();

    final misVacantes = vacantesProv.vacantes
        .where((v) => v.empresaId == auth.session?.userId)
        .toList();

    final activas = misVacantes.where((v) => v.estado == VacanteEstado.activa).length;
    final totalPostulaciones = misVacantes.fold<int>(0, (sum, v) => sum + v.totalPostulaciones);

    final double pctVacantes = misVacantes.isEmpty ? 0.0 : 1.0;
    final double pctPostulados = totalPostulaciones == 0 ? 0.0 : (totalPostulaciones >= 10 ? 1.0 : totalPostulaciones / 10.0);
    final double pctActivas = misVacantes.isEmpty ? 0.0 : (activas / misVacantes.length);

    final brandColor = _companyColorIndex < _brandColors.length
        ? _brandColors[_companyColorIndex]
        : _brandColors.first;

    final isPremium = auth.session?.isEffectivelyPremium == true;

    final initial = _companyName.isNotEmpty ? _companyName[0].toUpperCase() : 'E';

    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // 1. Cabecera Curva con Tarjeta Superpuesta
          SliverToBoxAdapter(
            child: SizedBox(
              height: 520, // 280 (cabecera azul) + 240 (altura expuesta de la tarjeta)
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Fondo curvo
                  Container(
                    height: 280,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: isPremium
                          ? kPremiumBannerGradient
                          : const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Ondas decorativas animadas
                        Positioned(
                          right: -60,
                          top: -40,
                          child: Pulse(
                            infinite: true,
                            duration: const Duration(seconds: 4),
                            child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)))),
                          ),
                        ),
                        Positioned(
                          left: -40,
                          bottom: -20,
                          child: Pulse(
                            infinite: true,
                            duration: const Duration(seconds: 6),
                            child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.03)))),
                          ),
                        ),
                        Positioned(
                          left: 100,
                          top: 40,
                          child: Pulse(
                            infinite: true, 
                            duration: const Duration(seconds: 5), 
                            child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.cyanAccent.withValues(alpha: 0.1)))),
                          ),
                        ),
                        // Contenido de Cabecera Alineado a la Izquierda
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: FadeInDown(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isEs ? 'MI EMPRESA' : 'MY COMPANY',
                                            style: TextStyle(color: Colors.blueAccent.shade100, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  _companyName,
                                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.15),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              GestureDetector(
                                                onTap: () => _showEditCompanyModal(context, isEs),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Icon(Icons.edit_outlined, size: 13, color: Colors.white70),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  _companySector,
                                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(Icons.location_on_outlined, size: 13, color: Colors.blueAccent.shade100),
                                              const SizedBox(width: 2),
                                              Flexible(
                                                child: Text(
                                                  _companyLocation,
                                                  style: TextStyle(color: Colors.blueAccent.shade100, fontSize: 11, fontWeight: FontWeight.w500),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Row(
                                    children: [
                                      const LanguageSwitchButton(),
                                      const SizedBox(width: 8),
                                      FadeInDown(
                                        child: GestureDetector(
                                          onTap: () => _showEditCompanyModal(context, isEs),
                                          child: Stack(
                                            children: [
                                              Container(
                                                width: 56,
                                                height: 56,
                                                decoration: BoxDecoration(
                                                  color: brandColor,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isPremium ? kGoldLight : Colors.white.withValues(alpha: 0.8),
                                                    width: isPremium ? 2.5 : 1.5,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: isPremium ? kGold.withValues(alpha: 0.45) : brandColor.withValues(alpha: 0.4),
                                                      blurRadius: isPremium ? 16 : 12,
                                                      spreadRadius: isPremium ? 2 : 1,
                                                    ),
                                                  ],
                                                ),
                                                alignment: Alignment.center,
                                                child: _companyLogo.isNotEmpty
                                                    ? ClipOval(
                                                        child: Image.network(
                                                          _companyLogo,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, _, _) => Text(
                                                            initial,
                                                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                                                          ),
                                                        ),
                                                      )
                                                    : Text(
                                                        initial,
                                                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                                                      ),
                                              ),
                                              Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.edit,
                                                    size: 11,
                                                    color: kBlue,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              FadeInDown(
                                delay: const Duration(milliseconds: 100),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isPremium
                                        ? kGold.withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isPremium
                                          ? kGoldLight.withValues(alpha: 0.6)
                                          : Colors.white.withValues(alpha: 0.2),
                                      width: isPremium ? 1.4 : 1.0,
                                    ),
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      final id = auth.session?.userId;
                                      final shortId = (id != null && id.length > 8) ? id.substring(0, 8) : '001';
                                      if (isPremium) {
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.stars_rounded, color: kGoldLight, size: 14),
                                            const SizedBox(width: 5),
                                            Text(
                                              'ID: $shortId... • PRO ✦ DESTACADA',
                                              style: const TextStyle(fontSize: 12, color: kGoldLight, fontWeight: FontWeight.w900),
                                            ),
                                          ],
                                        );
                                      }
                                      final planDisplay = auth.session?.isPremium == true
                                          ? 'Plan Pro'
                                          : _companyPlan;
                                      return Text('ID: $shortId... • $planDisplay', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold));
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tarjeta Superpuesta
                  Positioned(
                    top: 220, // Montado encima del borde curvo
                    left: 0,
                    right: 0,
                    child: FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Círculo decorativo líquido detrás (Cian)
                            Positioned(
                              top: -20,
                              left: -20,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.cyan.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                            // Círculo decorativo líquido detrás (Morado)
                            Positioned(
                              bottom: -20,
                              right: -20,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.purpleAccent.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                            // Tarjeta de Cristal
                            GlassCard(
                              width: double.infinity,
                              borderRadius: BorderRadius.circular(28),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                              customBorder: isPremium
                                  ? Border.all(color: kGold.withValues(alpha: 0.45), width: 1.5)
                                  : null,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isEs ? 'Rendimiento de publicaciones' : 'Listing Performance',
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kNavy),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              misVacantes.isEmpty
                                                  ? (isEs ? 'Sin vacantes publicadas aún' : 'No vacancies published yet')
                                                  : (isEs ? '$activas vacantes activas en curso' : '$activas active listings running'),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: misVacantes.isEmpty ? kMuted : const Color(0xFF10B981),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [BoxShadow(color: kBlue.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                                        ),
                                        child: const Icon(Icons.show_chart, color: kBlue, size: 20),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 28),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildDonutChart(isEs ? 'Vacantes' : 'Jobs', '${misVacantes.length}', pctVacantes, kBlue, 600),
                                        _buildDonutChart(isEs ? 'Postulados' : 'Applicants', '$totalPostulaciones', pctPostulados, const Color(0xFF10B981), 700),
                                        _buildDonutChart(isEs ? 'Activas' : 'Active', '$activas', pctActivas, Colors.orangeAccent, 800),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Título de Configuración
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 12, top: 40),
              child: FadeInLeft(
                child: Text(
                  isEs ? 'Configuración' : 'Settings',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kMuted),
                ),
              ),
            ),
          ),
                
          // Opciones animadas on-scroll
          Builder(
            builder: (context) {
              final List<Map<String, dynamic>> configOptions = [
                {
                  'icon': Icons.language,
                  'title': l10n.profileLanguage,
                  'isPremium': false,
                  'onTap': () => _showLanguageDialog(context, localeProvider, l10n),
                },
                {
                  'icon': Icons.bar_chart,
                  'title': isEs ? 'Reportes y Exportación' : 'Reports & Export',
                  'isPremium': false,
                  'onTap': () => _showReportsModal(context, isEs, misVacantes, totalPostulaciones),
                },
                {
                  'icon': Icons.payment,
                  'title': isEs ? 'Planes y Facturación' : 'Plans & Billing',
                  'isPremium': true,
                  'onTap': () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumSubscriptionScreen()));
                  },
                },
                {
                  'icon': Icons.people_outline,
                  'title': isEs ? 'Equipo y Permisos' : 'Team & Permissions',
                  'isPremium': false,
                  'onTap': () => _showTeamModal(context, isEs, auth.session?.email),
                },
                {
                  'icon': Icons.settings_outlined,
                  'title': isEs ? 'Preferencias de Cuenta' : 'Account Preferences',
                  'isPremium': false,
                  'onTap': () => _showEditCompanyModal(context, isEs),
                },
                {
                  'icon': Icons.gavel_outlined,
                  'title': isEs ? 'Marco Legal y Privacidad' : 'Legal Terms & Privacy',
                  'isPremium': false,
                  'onTap': () => LegalScreen.showModal(context),
                },
              ];

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < configOptions.length) {
                        final opt = configOptions[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FadeInUp(
                            delay: Duration(milliseconds: 100 * index),
                            duration: const Duration(milliseconds: 600),
                            from: 50,
                            child: _buildConfigTile(
                              opt['icon'] as IconData,
                              opt['title'] as String,
                              isPremium: opt['isPremium'] as bool,
                              onTap: opt['onTap'] as VoidCallback,
                            ),
                          ),
                        );
                      } else if (index == configOptions.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 28, bottom: 100),
                          child: FadeInUp(
                            delay: const Duration(milliseconds: 400),
                            from: 40,
                            child: SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.logout, color: Colors.redAccent),
                                label: Text(
                                  isEs ? 'Cerrar Sesión Segura' : 'Secure Logout',
                                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3), width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  backgroundColor: Colors.redAccent.withValues(alpha: 0.05),
                                ),
                                onPressed: () => auth.logout(),
                              ),
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                    childCount: configOptions.length + 1, // Todas las opciones + botón cerrar sesión
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditCompanyModal(BuildContext context, bool isEs) {
    final nameCtrl = TextEditingController(text: _companyName);
    final logoCtrl = TextEditingController(text: _companyLogo);
    String selectedSector = _companySector;
    String selectedLocation = _companyLocation;
    int selectedColorIndex = _companyColorIndex;

    final sectors = [
      'Tecnología',
      'Salud y Medicina',
      'Finanzas y Banca',
      'Educación',
      'Retail y Comercio',
      'Manufactura e Industria',
      'Servicios Profesionales',
      'Marketing y Medios',
      'Logística y Transporte',
      'Construcción e Inmobiliaria',
      'Otro',
    ];

    if (!sectors.contains(selectedSector)) {
      sectors.insert(0, selectedSector);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.business_center_rounded, color: kBlue, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isEs ? 'Perfil de la Empresa' : 'Company Profile',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kNavy),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: kMuted),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(
                          isEs ? 'Nombre de la Empresa' : 'Company Name',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kNavy),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            hintText: isEs ? 'Ej. Inversiones Andinas SAS' : 'E.g. Acme Corp',
                            filled: true,
                            fillColor: kBg,
                            prefixIcon: const Icon(Icons.apartment, color: kBlue, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kLine)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kLine)),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          isEs ? 'Sector Económico' : 'Industry / Sector',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kNavy),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: kBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kLine),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedSector,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, color: kBlue),
                              items: sectors.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14, color: kNavy)))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => selectedSector = val);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          isEs ? 'Ubicación (Ciudad / Departamento)' : 'Location',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kNavy),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final res = await showColombiaLocationPicker(context);
                            if (res != null) {
                              setModalState(() {
                                selectedLocation = res;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: kBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kLine),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: kBlue, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    selectedLocation.isNotEmpty ? selectedLocation : (isEs ? 'Seleccionar ciudad' : 'Select city'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: selectedLocation.isNotEmpty ? kNavy : kMuted,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.search, size: 18, color: kMuted),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          isEs ? 'URL del Logo (Opcional)' : 'Logo Image URL (Optional)',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kNavy),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: logoCtrl,
                          decoration: InputDecoration(
                            hintText: 'https://ejemplo.com/logo.png',
                            filled: true,
                            fillColor: kBg,
                            prefixIcon: const Icon(Icons.image_outlined, color: kBlue, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kLine)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kLine)),
                          ),
                          onChanged: (_) => setModalState(() {}),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          isEs ? 'Color de Identidad' : 'Brand Color Accent',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kNavy),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: List.generate(_brandColors.length, (idx) {
                            final c = _brandColors[idx];
                            final isSel = selectedColorIndex == idx;
                            return GestureDetector(
                              onTap: () => setModalState(() => selectedColorIndex = idx),
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSel ? kNavy : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: c.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: isSel ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save_rounded, color: Colors.white),
                        label: Text(
                          isEs ? 'Guardar Cambios' : 'Save Changes',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final newName = nameCtrl.text.trim();
                          if (newName.isEmpty) {
                            AppToast.show(context, message: isEs ? 'El nombre no puede estar vacío' : 'Name cannot be empty', type: ToastType.error);
                            return;
                          }
                          final auth = context.read<AuthProvider>();
                          final uid = auth.session?.userId ?? auth.session?.email ?? '';
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('company_name_$uid', newName);
                          await prefs.setString('company_name_active', newName);
                          await prefs.setString('company_sector_$uid', selectedSector);
                          await prefs.setString('company_location_$uid', selectedLocation);
                          await prefs.setString('company_logo_$uid', logoCtrl.text.trim());
                          await prefs.setInt('company_color_$uid', selectedColorIndex);

                          try {
                            final client = ApiClient(SecureStorage());
                            await client.patch(
                              '/auth/empresa/perfil',
                              {'nombre': newName},
                            );
                          } catch (_) {}

                          if (!mounted) return;
                          setState(() {
                            _companyName = newName;
                            _companySector = selectedSector;
                            _companyLocation = selectedLocation;
                            _companyLogo = logoCtrl.text.trim();
                            _companyColorIndex = selectedColorIndex;
                          });
                          if (modalCtx.mounted) {
                            Navigator.pop(modalCtx);
                          }
                          AppToast.show(this.context, message: isEs ? 'Perfil de empresa actualizado' : 'Company profile updated', type: ToastType.success);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReportsModal(BuildContext context, bool isEs, List<Vacante> misVacantes, int totalPostulaciones) {
    final activas = misVacantes.where((v) => v.estado == VacanteEstado.activa).length;
    final pausadas = misVacantes.where((v) => v.estado == VacanteEstado.pausada).length;
    final cerradas = misVacantes.where((v) => v.estado == VacanteEstado.cerrada).length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.bar_chart_rounded, color: kBlue, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isEs ? 'Reportes y Métricas' : 'Reports & Analytics',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kNavy),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: kMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      isEs ? 'Resumen Ejecutivo en Tiempo Real' : 'Real-time Executive Summary',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kNavy),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(isEs ? 'Total Vacantes' : 'Total Jobs', '${misVacantes.length}', Icons.work_outline, kBlue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(isEs ? 'Postulaciones' : 'Applicants', '$totalPostulaciones', Icons.people_outline, const Color(0xFF10B981)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(isEs ? 'Activas' : 'Active', '$activas', Icons.check_circle_outline, Colors.orangeAccent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(isEs ? 'Pausadas/Cerradas' : 'Paused/Closed', '${pausadas + cerradas}', Icons.pause_circle_outline, Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isEs ? 'Detalle por Vacante' : 'Breakdown by Job Opening',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kNavy),
                    ),
                    const SizedBox(height: 8),
                    if (misVacantes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            isEs ? 'Aún no tienes vacantes creadas.' : 'No jobs created yet.',
                            style: const TextStyle(color: kMuted, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ...misVacantes.map((v) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: kLine),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(v.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kNavy)),
                                    Text(v.ubicacion, style: const TextStyle(fontSize: 11, color: kMuted)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${v.totalPostulaciones} ${isEs ? 'candidatos' : 'candidates'}',
                                  style: const TextStyle(color: kBlue, fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.file_download_outlined, color: Colors.white),
                    label: Text(
                      isEs ? 'Copiar Reporte CSV al Portapapeles' : 'Copy CSV Report to Clipboard',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      final buffer = StringBuffer();
                      buffer.writeln('ID,Título,Ubicación,Estado,Postulados');
                      for (final v in misVacantes) {
                        buffer.writeln('"${v.id}","${v.titulo}","${v.ubicacion}","${v.estado.name}",${v.totalPostulaciones}');
                      }
                      Clipboard.setData(ClipboardData(text: buffer.toString()));
                      Navigator.pop(ctx);
                      AppToast.show(context, message: isEs ? 'Reporte CSV copiado al portapapeles' : 'CSV Report copied to clipboard', type: ToastType.success);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTeamModal(BuildContext context, bool isEs, String? ownerEmail) {
    final inviteCtrl = TextEditingController();
    String selectedRole = 'Reclutador';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.people_alt_rounded, color: kBlue, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isEs ? 'Equipo y Permisos' : 'Team & Permissions',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kNavy),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: kMuted),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(
                          isEs ? 'Miembros Activos' : 'Active Members',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kNavy),
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: kBlue.withValues(alpha: 0.1),
                            child: const Icon(Icons.person, color: kBlue),
                          ),
                          title: Text(ownerEmail ?? 'empresa@talentmatch.com', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kNavy)),
                          subtitle: Text(isEs ? 'Propietario de la cuenta' : 'Account Owner', style: const TextStyle(fontSize: 11, color: kMuted)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isEs ? 'Admin' : 'Owner',
                              style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ),
                        const Divider(height: 24),
                        Text(
                          isEs ? 'Invitar Nuevo Reclutador' : 'Invite Recruiter / Teammate',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kNavy),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: inviteCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'colega@empresa.com',
                            filled: true,
                            fillColor: kBg,
                            prefixIcon: const Icon(Icons.mail_outline, color: kBlue, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kLine)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kLine)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(isEs ? 'Rol: ' : 'Role: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kNavy)),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text(isEs ? 'Reclutador' : 'Recruiter'),
                              selected: selectedRole == 'Reclutador',
                              onSelected: (_) => setModalState(() => selectedRole = 'Reclutador'),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text(isEs ? 'Visualizador' : 'Viewer'),
                              selected: selectedRole == 'Visualizador',
                              onSelected: (_) => setModalState(() => selectedRole = 'Visualizador'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            label: Text(
                              isEs ? 'Enviar Invitación' : 'Send Invitation',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              final email = inviteCtrl.text.trim();
                              if (email.isEmpty || !email.contains('@')) {
                                AppToast.show(context, message: isEs ? 'Ingresa un correo electrónico válido' : 'Please enter a valid email', type: ToastType.error);
                                return;
                              }
                              Navigator.pop(ctx);
                              AppToast.show(
                                context,
                                message: isEs
                                    ? 'Invitación enviada a $email con permisos de $selectedRole'
                                    : 'Invitation sent to $email with $selectedRole permissions',
                                type: ToastType.success,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kNavy)),
              Text(label, style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LocaleProvider localeProvider, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final currentCode = localeProvider.locale.languageCode;
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.language, color: kBlue, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      l10n.profileSelectLanguageTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kNavy),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: const Text('🇪🇸', style: TextStyle(fontSize: 26)),
                  title: Text(
                    l10n.profileLanguageSpanish,
                    style: TextStyle(
                      fontWeight: currentCode == 'es' ? FontWeight.w800 : FontWeight.w500,
                      color: currentCode == 'es' ? kBlue : kNavy,
                    ),
                  ),
                  trailing: currentCode == 'es'
                      ? const Icon(Icons.check_circle, color: kBlue)
                      : const Icon(Icons.circle_outlined, color: Colors.grey),
                  onTap: () {
                    localeProvider.setLocale(const Locale('es'));
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: const Text('🇺🇸', style: TextStyle(fontSize: 26)),
                  title: Text(
                    l10n.profileLanguageEnglish,
                    style: TextStyle(
                      fontWeight: currentCode == 'en' ? FontWeight.w800 : FontWeight.w500,
                      color: currentCode == 'en' ? kBlue : kNavy,
                    ),
                  ),
                  trailing: currentCode == 'en'
                      ? const Icon(Icons.check_circle, color: kBlue)
                      : const Icon(Icons.circle_outlined, color: Colors.grey),
                  onTap: () {
                    localeProvider.setLocale(const Locale('en'));
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDonutChart(String label, String value, double percent, Color color, int delayMs) {
    return ElasticIn(
      delay: Duration(milliseconds: delayMs),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 55,
                width: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 0),
                  ],
                ),
              ),
              SizedBox(
                height: 75,
                width: 75,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: percent),
                  duration: const Duration(milliseconds: 2000),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(value: 1.0, strokeWidth: 8, color: Colors.white.withValues(alpha: 0.5)),
                        CircularProgressIndicator(value: val, strokeWidth: 8, color: color, strokeCap: StrokeCap.round),
                        Text('${(val * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: kNavy)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: kNavy, letterSpacing: -0.5)),
          Text(label, style: const TextStyle(color: kMuted, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildConfigTile(IconData icon, String title, {bool isPremium = false, required VoidCallback onTap}) {
    return BouncyTap(
      onPressed: onTap,
      scaleFactor: 0.95,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: kNavy.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: kLine.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: isPremium ? Colors.amber.withValues(alpha: 0.1) : kBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: isPremium ? Colors.amber[700] : kBlue, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kNavy))),
              if (isPremium) 
                Pulse(
                  infinite: true,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                    child: const Text('PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: kMuted),
            ],
          ),
        ),
      ),
    );
  }
}
