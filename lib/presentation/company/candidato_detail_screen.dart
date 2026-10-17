import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../shared/widgets/match_badge.dart';
import '../shared/widgets/bouncy_tap.dart';

class CandidatoDetailScreen extends StatelessWidget {
  final Map<String, dynamic> candidato;

  const CandidatoDetailScreen({super.key, required this.candidato});

  @override
  Widget build(BuildContext context) {
    final int matchScore = (candidato['match'] as num).toInt();
    final List<String> skills = candidato['skills'];
    final String heroTag = 'candidato_avatar_${candidato['nombre']}'; // Tag único para la animación Hero

    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Cabecera Hero con la imagen del candidato volando
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            stretch: true,
            backgroundColor: kNavy,
            elevation: 0,
            automaticallyImplyLeading: false, // Ocultar botón por defecto
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen de fondo expandida con el Hero
                  Hero(
                    tag: heroTag,
                    child: Image.network(
                      candidato['imagen'],
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, _, _) => Container(
                        color: kBlue,
                        alignment: Alignment.center,
                        child: Text(
                          candidato['nombre'][0],
                          style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  // Gradiente inferior para oscurecer y leer los textos
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.1),
                            kNavy.withValues(alpha: 0.9),
                            kNavy,
                          ],
                          stops: const [0.0, 0.4, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Información superpuesta en el Header
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInUp(
                          child: Text(
                            candidato['nombre'],
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.1),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeInUp(
                          delay: const Duration(milliseconds: 100),
                          child: Text(
                            candidato['profesion'],
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          delay: const Duration(milliseconds: 200),
                          child: Row(
                            children: [
                              MatchBadge(percent: matchScore, compact: false),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: Text(candidato['estado'].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Contenido de la pantalla
          SliverToBoxAdapter(
            child: Container(
              color: kNavy, // Conectar visualmente con el SliverAppBar
              child: Container(
                decoration: const BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    FadeInUp(delay: const Duration(milliseconds: 300), child: const Text('Acerca del Candidato', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy))),
                    const SizedBox(height: 12),
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: Text(
                        'Profesional con gran experiencia en el desarrollo de soluciones a nivel empresarial. '
                        'Ha demostrado un historial constante de cumplimiento de plazos y adopción de mejores prácticas. '
                        'Busca integrarse a un equipo dinámico que ofrezca retos arquitectónicos.',
                        style: TextStyle(color: kNavy.withValues(alpha: 0.7), fontSize: 15, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    FadeInUp(delay: const Duration(milliseconds: 500), child: const Text('Habilidades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy))),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: skills.asMap().entries.map((entry) {
                        final int idx = entry.key;
                        final String s = entry.value;
                        return FadeInLeft(
                          delay: Duration(milliseconds: 600 + (idx * 100)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: kLine), boxShadow: [BoxShadow(color: kNavy.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                            child: Text(s, style: const TextStyle(fontSize: 14, color: kNavy, fontWeight: FontWeight.w700)),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 100), // Espacio para el footer flotante
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      
      // Botón Back Flotante
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: BouncyTap(
              onPressed: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ),
      
      // Action Bar inferior
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: kNavy.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: BouncyTap(
                onPressed: () => Navigator.pop(context),
                child: SizedBox(
                  height: 55,
                  child: OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5), width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('Descartar', style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: BouncyTap(
                onPressed: () {},
                child: SizedBox(
                  height: 55,
                  child: FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Agendar Entrevista', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(backgroundColor: kBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), disabledBackgroundColor: kBlue, disabledForegroundColor: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
