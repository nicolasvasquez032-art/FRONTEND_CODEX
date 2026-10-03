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
          // 1. Cabecera Curva con Tarjeta Superpuesta (Estilo Mis Vacantes)
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
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
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
                                  FadeInDown(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('MI EMPRESA', style: TextStyle(color: Colors.blueAccent.shade100, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                        const SizedBox(height: 6),
                                        const Text('Global Tech', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.1)),
                                        const Text('Solutions', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.1)),
                                      ],
                                    ),
                                  ),
                                  FadeInDown(
                                    child: Pulse(
                                      infinite: true,
                                      duration: const Duration(seconds: 3),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(30),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                          child: Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                                              boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2)],
                                            ),
                                            child: const Icon(Icons.apartment, size: 28, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              FadeInDown(
                                delay: const Duration(milliseconds: 100),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15), 
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      final id = auth.session?.userId;
                                      final shortId = (id != null && id.length > 8) ? id.substring(0,8) : '001';
                                      return Text('ID: $shortId... • Premium Plan', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold));
                                    }
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.7),
                                    Colors.white.withValues(alpha: 0.4),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                                boxShadow: [
                                  BoxShadow(color: kNavy.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 15)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Rendimiento del mes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kNavy)),
                                          SizedBox(height: 4),
                                          Text('+15% vs mes anterior', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                                        ],
                                      ),
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildDonutChart('Contratos', '12', 0.85, kBlue, 600),
                                      _buildDonutChart('Respuesta', '92%', 0.92, const Color(0xFF10B981), 700),
                                      _buildDonutChart('Vistas', '4k', 0.65, Colors.orangeAccent, 800),
                                    ],
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
              ),
            ],
          ),
        ),
      ),
          
          // Título de Configuración (fuera de la lista para no iterar)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 12, top: 40),
              child: FadeInLeft(
                child: const Text('Configuración', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kMuted)),
              ),
            ),
          ),
                
          // Opciones animadas on-scroll
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Definimos las opciones de configuración
                  final List<Map<String, dynamic>> configOptions = [
                    {'icon': Icons.bar_chart, 'title': 'Reportes y Exportación', 'isPremium': false, 'onTap': () {}},
                    {'icon': Icons.payment, 'title': 'Planes y Facturación', 'isPremium': true, 'onTap': () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumSubscriptionScreen()));
                    }},
                    {'icon': Icons.people_outline, 'title': 'Equipo y Permisos', 'isPremium': false, 'onTap': () {}},
                    {'icon': Icons.settings_outlined, 'title': 'Preferencias de Cuenta', 'isPremium': false, 'onTap': () {}},
                  ];

                  if (index < configOptions.length) {
                    final opt = configOptions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FadeInUp(
                        // Eliminamos el delay fijo grande, ahora se animan con un ligero retraso de entrada
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
                    );
                  }
                  return null;
                },
                childCount: 5, // 4 opciones + 1 botón salir
              ),
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
          Stack(
            alignment: Alignment.center,
            children: [
              // Efecto de sombra para volumen
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
                        // Fondo de la dona (gris claro transparente)
                        CircularProgressIndicator(value: 1.0, strokeWidth: 8, color: Colors.white.withValues(alpha: 0.5)),
                        // Progreso animado (líquido)
                        CircularProgressIndicator(value: val, strokeWidth: 8, color: color, strokeCap: StrokeCap.round),
                        // Texto central animado (Contador)
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
