import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/widgets/bouncy_tap.dart';
import 'premium_subscription_screen.dart';

class CompanyProfileScreen extends StatelessWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // 1. Cabecera Hero Elástica
          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            stretch: true, // Efecto rebote elástico al tirar hacia abajo
            backgroundColor: kBlue,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradiente de fondo
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Ondas decorativas
                  Positioned(
                    right: -50,
                    top: -50,
                    child: FadeIn(duration: const Duration(seconds: 2), child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)))),
                  ),
                  Positioned(
                    left: -30,
                    bottom: 20,
                    child: FadeIn(duration: const Duration(seconds: 2), child: Container(width: 140, height: 140, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.03)))),
                  ),
                  // Contenido central del Hero
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      // Logotipo Glassmorphism animado
                      ZoomIn(
                        duration: const Duration(milliseconds: 600),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(55),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
                              ),
                              child: const Icon(Icons.apartment, size: 45, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Nombre y Tag
                      FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: const Text('Global Tech Solutions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                      ),
                      const SizedBox(height: 8),
                      FadeInUp(
                        delay: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                          child: Text('ID: ${auth.session?.userId ?? "001"} • Premium Plan', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // 2. Contenido
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20), // Padding extra para separarlo de la barra
                
                // Tarjeta de Analíticas (Dona)
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28), // Más espacio interno para respirar
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: kNavy.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 15))],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Rendimiento del mes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy)),
                              Icon(Icons.show_chart, color: kBlue),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDonutChart('Contratos', '12', 0.85, kBlue, 600),
                              _buildDonutChart('Respuesta', '92%', 0.92, const Color(0xFF10B981), 700),
                              _buildDonutChart('Vistas', '4k', 0.65, Colors.amber, 800),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Opciones de Configuración
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInLeft(
                        delay: const Duration(milliseconds: 600),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 12),
                          child: Text('Configuración', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kMuted)),
                        ),
                      ),
                      FadeInUp(delay: const Duration(milliseconds: 700), child: _buildConfigTile(Icons.bar_chart, 'Reportes y Exportación', onTap: () {})),
                      const SizedBox(height: 12),
                      FadeInUp(
                        delay: const Duration(milliseconds: 800), 
                        child: _buildConfigTile(Icons.payment, 'Planes y Facturación', isPremium: true, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumSubscriptionScreen()));
                        }),
                      ),
                      const SizedBox(height: 12),
                      FadeInUp(delay: const Duration(milliseconds: 900), child: _buildConfigTile(Icons.people_outline, 'Equipo y Permisos', onTap: () {})),
                      const SizedBox(height: 12),
                      FadeInUp(delay: const Duration(milliseconds: 1000), child: _buildConfigTile(Icons.settings_outlined, 'Preferencias de Cuenta', onTap: () {})),
                      
                      const SizedBox(height: 40),
                      
                      // Botón Salir
                      FadeInUp(
                        delay: const Duration(milliseconds: 1100),
                        child: SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.logout, color: Colors.redAccent),
                            label: const Text('Cerrar Sesión Segura', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3), width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              backgroundColor: Colors.redAccent.withValues(alpha: 0.05),
                            ),
                            onPressed: () => auth.logout(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 100), // Padding inferior
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget para la dona analítica
  Widget _buildDonutChart(String label, String value, double percent, Color color, int delayMs) {
    return ElasticIn(
      delay: Duration(milliseconds: delayMs),
      child: Column(
        children: [
          SizedBox(
            height: 65,
            width: 65,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: percent),
              duration: const Duration(milliseconds: 2000),
              curve: Curves.elasticOut,
              builder: (context, val, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Fondo de la dona
                    CircularProgressIndicator(value: 1.0, strokeWidth: 7, color: color.withValues(alpha: 0.15)),
                    // Progreso animado
                    CircularProgressIndicator(value: val, strokeWidth: 7, color: color, strokeCap: StrokeCap.round),
                    // Texto central animado (Contador)
                    Text('${(val * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kNavy)),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: kNavy)),
          Text(label, style: const TextStyle(color: kMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // Tarjetas de Opciones interactivas con efecto de pulsación y escala física
  Widget _buildConfigTile(IconData icon, String title, {bool isPremium = false, required VoidCallback onTap}) {
    return BouncyTap(
      onPressed: onTap,
      scaleFactor: 0.95, // 5% de hundimiento
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
