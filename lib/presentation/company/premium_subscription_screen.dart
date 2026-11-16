import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/widgets/bouncy_tap.dart';

class PremiumSubscriptionScreen extends StatefulWidget {
  const PremiumSubscriptionScreen({super.key});

  @override
  State<PremiumSubscriptionScreen> createState() => _PremiumSubscriptionScreenState();
}

class _PremiumSubscriptionScreenState extends State<PremiumSubscriptionScreen> {
  int _selectedPlan = 1; // 0 = Free, 1 = Pro
  bool _isProcessing = false;

  Future<void> _iniciarPagoReal() async {
    setState(() => _isProcessing = true);
    try {
      final session = context.read<AuthProvider>().session;
      if (session == null) throw Exception("No hay sesión activa.");

      final body = {
        "empresa_id": session.userId,
        "email": session.email ?? "contacto@empresa.com",
      };

      final response = await ApiClient(SecureStorage()).post('/pagos/crear-preferencia-pro', body);
      
      if (response['init_point'] != null) {
        final url = Uri.parse(response['init_point']);
        // canLaunchUrl can give false negatives on newer Android versions or web.
        // It's better to just try launching it directly.
        final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
        if (!launched) {
          throw Exception("No se pudo abrir la pasarela de pagos.");
        }
        // Si quisieras, aquí podrías esperar a que el usuario vuelva a la app
        // y revisar en el servidor si su cuenta ya es PRO.
      } else {
        throw Exception("Error de respuesta del servidor.");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al iniciar pago: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ignore: unused_element
  void _showSuccessDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZoomIn(
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 50),
              ),
            ),
            const SizedBox(height: 24),
            const Text('¡Bienvenido al nivel PRO!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kNavy)),
            const SizedBox(height: 12),
            const Text(
              'Tu pago ha sido procesado exitosamente. Ahora tienes acceso a publicaciones ilimitadas y análisis con IA.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context); // Cierra modal
                  Navigator.pop(context); // Vuelve al perfil
                },
                style: FilledButton.styleFrom(
                  backgroundColor: kNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Comenzar a reclutar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isPremium = auth.session?.isEffectivelyPremium == true;

    if (isPremium) {
      return _buildActivePremiumView(context);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Fondo oscuro súper premium
      body: Stack(
        children: [
          // Fondo abstracto y gradientes luminosos
          Positioned(
            top: -100, 
            right: -100, 
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: kBlue.withValues(alpha: 0.15))),
            )
          ),
          Positioned(
            bottom: -50, 
            left: -100, 
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.amber.withValues(alpha: 0.1))),
            )
          ),

          SafeArea(
            child: Column(
              children: [
                // Header custom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      BouncyTap(
                        onPressed: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Títulos
                FadeInDown(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber.withValues(alpha: 0.5))),
                          child: const Text('TALENT MATCH PRO', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Encuentra al candidato perfecto, más rápido.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Desbloquea el poder de la IA y contacta talento sin límites.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Selector de Planes
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        FadeInUp(delay: const Duration(milliseconds: 200), child: _buildPlanCard(0, 'Plan Básico', '0', 'Ideal para startups pequeñas', ['2 Publicaciones al mes', 'Filtros básicos', 'Soporte estándar'])),
                        const SizedBox(height: 16),
                        FadeInUp(delay: const Duration(milliseconds: 300), child: _buildPlanCard(1, 'Plan PRO', '49', 'Recomendado para empresas', ['Publicaciones ilimitadas', 'Match Insights con IA', 'Contactos directos infinitos', 'Soporte prioritario 24/7'], isPopular: true)),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                
                // Área inferior de Pago
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Flexible(
                              child: Text('Total a pagar', style: TextStyle(color: Colors.white70, fontSize: 16)),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  _selectedPlan == 1 ? '\$49.00 USD/mes' : '\$0.00 USD',
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        BouncyTap(
                          onPressed: _selectedPlan == 1 ? (_isProcessing ? null : _iniciarPagoReal) : () => Navigator.pop(context),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            height: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: _selectedPlan == 1 
                                  ? const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]) // Azul brillante
                                  : LinearGradient(colors: [Colors.grey.shade800, Colors.grey.shade700]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _selectedPlan == 1 ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))] : [],
                            ),
                            child: _isProcessing
                                ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_selectedPlan == 1) const Icon(Icons.payment, color: Colors.white, size: 20),
                                      if (_selectedPlan == 1) const SizedBox(width: 10),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            _selectedPlan == 1 ? 'Pagar de forma segura' : 'Continuar con el plan Gratis',
                                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline, size: 14, color: Colors.white.withValues(alpha: 0.4)),
                            const SizedBox(width: 6),
                            Text('Pagos procesados por Mercado Pago', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPlanCard(int index, String title, String price, String subtitle, List<String> features, {bool isPopular = false}) {
    final bool isSelected = _selectedPlan == index;

    return BouncyTap(
      onPressed: () {
        setState(() => _selectedPlan = index);
      },
      scaleFactor: 0.98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? kBlue : Colors.white.withValues(alpha: 0.1), width: isSelected ? 2 : 1),
          boxShadow: isSelected ? [BoxShadow(color: kBlue.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5)] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                child: const Text('MÁS POPULAR', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? kBlue : Colors.white.withValues(alpha: 0.3), width: 2),
                    color: isSelected ? kBlue : Colors.transparent,
                  ),
                  child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$$price', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1)),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4, left: 4),
                    child: Text('/mes', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: Colors.white12, height: 1),
            ),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: isSelected ? Colors.amber : Colors.white24, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      f,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// Vista exclusiva para cuentas que ya son PRO / Premium
  Widget _buildActivePremiumView(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A), // Obsidian profunda
      body: Stack(
        children: [
          // Resplandores dorados difusos de lujo
          Positioned(
            top: -100,
            right: -80,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kGold.withValues(alpha: 0.22),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -80,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kGoldDark.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Barra superior
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BouncyTap(
                        onPressed: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 22),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kGold.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, color: kGoldLight, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'PLAN ACTIVO',
                              style: TextStyle(
                                color: kGoldLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Cabecera de estado
                        FadeInDown(
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [kGoldLight, kGoldDark],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kGold.withValues(alpha: 0.45),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.workspace_premium, color: Colors.white, size: 38),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Plan Empresa Pro Activo',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Suscripción corporativa activa con beneficios de IA sin límites.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 14),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Métricas del plan: Días restantes y Próxima renovación
                        FadeInUp(
                          delay: const Duration(milliseconds: 150),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131B2E),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: kGold.withValues(alpha: 0.35), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: kGold.withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Estado: Activo • Facturación recurrente',
                                        style: TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricTile(
                                        title: 'Días Restantes',
                                        value: '28 días',
                                        subtitle: 'Del ciclo actual',
                                        icon: Icons.hourglass_top_rounded,
                                        color: kGoldLight,
                                      ),
                                    ),
                                    Container(width: 1, height: 50, color: Colors.white12),
                                    Expanded(
                                      child: _buildMetricTile(
                                        title: 'Renovación',
                                        value: '16 Dic 2026',
                                        subtitle: '\$49.00 USD/mes',
                                        icon: Icons.event_repeat_rounded,
                                        color: Colors.blueAccent.shade100,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Beneficios incluidos
                        FadeInUp(
                          delay: const Duration(milliseconds: 300),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.auto_awesome, color: kGoldLight, size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Tus Beneficios Pro Incluidos',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _buildBenefitRow('Vacantes destacadas ilimitadas con insignia dorada ⭐'),
                                _buildBenefitRow('Filtrado inteligente y clasificación automática con IA'),
                                _buildBenefitRow('Descarga y visualización ilimitada de CVs en PDF'),
                                _buildBenefitRow('Salas de chat en tiempo real con candidatos y videollamadas'),
                                _buildBenefitRow('Soporte corporativo prioritario 24/7'),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Botón de retorno al panel
                        FadeInUp(
                          delay: const Duration(milliseconds: 400),
                          child: BouncyTap(
                            onPressed: () => Navigator.pop(context),
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: kPremiumGoldButtonGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: kGold.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Volver a Mi Panel de Empresa',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Center(
                          child: Text(
                            'Gestionado a través de Mercado Pago',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              subtitle,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: kGoldLight, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
