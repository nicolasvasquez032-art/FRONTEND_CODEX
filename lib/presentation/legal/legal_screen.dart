import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:talentmatch/core/constants/app_colors.dart';
import 'package:talentmatch/presentation/legal/legal_content.dart';
import 'package:talentmatch/presentation/shared/providers/locale_provider.dart';
import 'package:talentmatch/presentation/shared/widgets/brand_logo.dart';

class LegalScreen extends StatefulWidget {
  final int initialTab;
  final VoidCallback? onAccept;
  final bool isModal;

  const LegalScreen({
    super.key,
    this.initialTab = 0,
    this.onAccept,
    this.isModal = false,
  });

  /// Abre la vista legal como un modal estilizado de pantalla completa / hoja deslizable.
  static Future<bool?> showModal(
    BuildContext context, {
    int initialTab = 0,
    VoidCallback? onAccept,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.93,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: LegalScreen(
            initialTab: initialTab,
            onAccept: onAccept,
            isModal: true,
          ),
        ),
      ),
    );
  }

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEs = context.watch<LocaleProvider>().isSpanish;

    final termsList = isEs ? LegalContentData.termsSectionsEs : LegalContentData.termsSectionsEn;
    final privacyList = isEs ? LegalContentData.privacySectionsEs : LegalContentData.privacySectionsEn;
    final cookiesList = isEs ? LegalContentData.cookiesSectionsEs : LegalContentData.cookiesSectionsEn;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        top: !widget.isModal,
        bottom: false,
        child: Column(
          children: [
            // ── Barra superior y encabezado ──
            _buildHeader(context, isEs),

            // ── Barra de búsqueda rápida ──
            _buildSearchBar(isEs),

            // ── Selector de Pestañas (Tabs) ──
            _buildTabBar(isEs),

            // ── Contenido de las secciones ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSectionListView(termsList, isEs),
                  _buildSectionListView(privacyList, isEs),
                  _buildSectionListView(cookiesList, isEs),
                ],
              ),
            ),

            // ── Barra de acción inferior ──
            _buildBottomBar(context, isEs),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isEs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: kLine, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isModal)
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          Row(
            children: [
              const Flexible(
                child: BrandFull(iconSize: 26),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kBlue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user, color: kBlue, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      isEs ? 'Ley 1581 / 2012' : 'Compliant',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: kBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.close, color: kNavy, size: 22),
                tooltip: isEs ? 'Cerrar' : 'Close',
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isEs ? 'Marco Legal y Políticas de Privacidad' : 'Legal Terms & Privacy Policy',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: kNavy,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isEs
                ? 'Conforme a la legislación colombiana de protección de datos (Habeas Data) y comercio electrónico.'
                : 'Governed by Colombian data privacy regulations and electronic commerce laws.',
            style: GoogleFonts.inter(fontSize: 12, color: kMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isEs) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: _searchCtrl,
        style: GoogleFonts.inter(fontSize: 13, color: kText),
        decoration: InputDecoration(
          isDense: true,
          hintText: isEs ? 'Buscar en los términos (ej. Habeas Data, Gratuidad)...' : 'Search legal terms...',
          hintStyle: GoogleFonts.inter(fontSize: 12, color: kMuted),
          prefixIcon: const Icon(Icons.search, size: 18, color: kMuted),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16, color: kMuted),
                  onPressed: () => _searchCtrl.clear(),
                )
              : null,
          filled: true,
          fillColor: kBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kLine),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBlue, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isEs) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        labelColor: kBlue,
        unselectedLabelColor: kMuted,
        indicatorColor: kBlue,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: [
          Tab(
            icon: const Icon(Icons.description_outlined, size: 18),
            text: isEs ? 'Términos' : 'Terms',
          ),
          Tab(
            icon: const Icon(Icons.shield_outlined, size: 18),
            text: isEs ? 'Privacidad' : 'Privacy',
          ),
          Tab(
            icon: const Icon(Icons.cookie_outlined, size: 18),
            text: isEs ? 'Cookies' : 'Cookies',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionListView(List<LegalSectionItem> allSections, bool isEs) {
    // Filtrar si hay búsqueda activa
    final filtered = _searchQuery.isEmpty
        ? allSections
        : allSections.where((s) {
            final t = s.title.toLowerCase();
            final c = s.content.toLowerCase();
            final b = s.bullets.join(' ').toLowerCase();
            return t.contains(_searchQuery) || c.contains(_searchQuery) || b.contains(_searchQuery);
          }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                isEs ? 'No se encontraron resultados para "$_searchQuery"' : 'No results found for "$_searchQuery"',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: kMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return _buildSectionCard(item, isEs);
      },
    );
  }

  Widget _buildSectionCard(LegalSectionItem item, bool isEs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la cláusula
          Text(
            item.title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: kNavy,
            ),
          ),
          const SizedBox(height: 10),

          // Texto principal
          Text(
            item.content,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF334155),
              height: 1.55,
            ),
          ),

          // Viñetas si existen
          if (item.bullets.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...item.bullets.map((bullet) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: kBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          bullet,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0xFF475569),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          // Alerta destacada si existe
          if (item.alertNotice != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: kBlue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.alertNotice!,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E40AF),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isEs) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kLine, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kLine),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                isEs ? 'Entendido' : 'Understood',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kNavy,
                ),
              ),
            ),
          ),
          if (widget.onAccept != null) ...[
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onAccept?.call();
                  Navigator.of(context).pop(true);
                },
                icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                label: Text(
                  isEs ? 'Aceptar y continuar' : 'Accept & continue',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
