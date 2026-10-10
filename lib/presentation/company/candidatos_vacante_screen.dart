import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/vacante.dart';
import '../shared/widgets/match_badge.dart';
import '../shared/widgets/bouncy_tap.dart';
import '../shared/widgets/shimmer_cards.dart';
import 'candidato_detail_screen.dart';

class CandidatosVacanteScreen extends StatefulWidget {
  final Vacante vacante;
  const CandidatosVacanteScreen({super.key, required this.vacante});

  @override
  State<CandidatosVacanteScreen> createState() => _CandidatosVacanteScreenState();
}

class _CandidatosVacanteScreenState extends State<CandidatosVacanteScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simula la carga premium con Skeleton Loaders
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> mockCandidatos = [
      {
        'nombre': 'Andrea Gómez',
        'profesion': 'Senior Software Engineer',
        'match': 98.5,
        'imagen': 'https://randomuser.me/api/portraits/women/44.jpg',
        'skills': ['Python', 'AWS', 'Docker'],
        'estado': 'Nuevo'
      },
      {
        'nombre': 'Carlos Torres',
        'profesion': 'Desarrollador Backend',
        'match': 92.0,
        'imagen': 'https://randomuser.me/api/portraits/men/32.jpg',
        'skills': ['Java', 'Spring', 'SQL'],
        'estado': 'En revisión'
      },
      {
        'nombre': 'Lucía Méndez',
        'profesion': 'Full Stack Developer',
        'match': 87.3,
        'imagen': 'https://randomuser.me/api/portraits/women/68.jpg',
        'skills': ['React', 'Node.js', 'MongoDB'],
        'estado': 'Nuevo'
      },
      {
        'nombre': 'Miguel Ángel Ríos',
        'profesion': 'Ingeniero de Software',
        'match': 76.5,
        'imagen': 'https://randomuser.me/api/portraits/men/46.jpg',
        'skills': ['Dart', 'Flutter', 'Firebase'],
        'estado': 'Rechazado'
      },
    ];

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05))),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 90, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FadeInDown(child: const Text('Candidatos para:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold))),
                              const SizedBox(height: 4),
                              FadeInLeft(
                                delay: const Duration(milliseconds: 200),
                                child: Text(
                                  widget.vacante.titulo,
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.1),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ZoomIn(
                                delay: const Duration(milliseconds: 400),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                                  child: Text('${mockCandidatos.length} postulantes en total', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (_isLoading) {
                        return const CandidatoShimmerCard();
                      }

                      final cand = mockCandidatos[index];
                      return FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: Duration(milliseconds: 150 * index),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _CandidatoCard(candidato: cand),
                        ),
                      );
                    },
                    childCount: _isLoading ? 3 : mockCandidatos.length,
                  ),
                ),
              ),
            ],
          ),
          
          Positioned(
            top: 50,
            left: 20,
            child: FadeInDown(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: BouncyTap(
                    onPressed: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidatoCard extends StatelessWidget {
  final Map<String, dynamic> candidato;

  const _CandidatoCard({required this.candidato});

  @override
  Widget build(BuildContext context) {
    final int matchScore = (candidato['match'] as num).toInt();
    final List<String> skills = candidato['skills'];
    final String estado = candidato['estado'];

    Color estadoColor = Colors.blueAccent;
    if (estado == 'Nuevo') estadoColor = const Color(0xFF10B981);
    if (estado == 'Rechazado') estadoColor = Colors.redAccent;

    return BouncyTap(
      scaleFactor: 0.98,
      onPressed: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, _, _) => CandidatoDetailScreen(candidato: candidato),
            transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
          )
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kLine.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(color: kNavy.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10))
          ]
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ZoomIn(
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: kBlue.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: ClipOval(
                        child: Hero(
                          tag: 'candidato_avatar_${candidato['nombre']}',
                          child: Image.network(
                            candidato['imagen'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: kNavy,
                                alignment: Alignment.center,
                                child: Text(
                                  candidato['nombre'][0],
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                candidato['nombre'],
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy, height: 1.1),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: estadoColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(estado.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: estadoColor)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(candidato['profesion'], style: const TextStyle(fontSize: 13, color: kMuted, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ElasticIn(
                              delay: const Duration(milliseconds: 800),
                              child: MatchBadge(percent: matchScore, compact: true),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kBg.withValues(alpha: 0.5),
                border: Border.symmetric(horizontal: BorderSide(color: kLine.withValues(alpha: 0.5))),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: skills.asMap().entries.map((entry) {
                  final int idx = entry.key;
                  final String s = entry.value;
                  return FadeInRight(
                    delay: Duration(milliseconds: 600 + (idx * 150)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: kLine)),
                      child: Text(s, style: const TextStyle(fontSize: 11, color: kNavy, fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: BouncyTap(
                      onPressed: () {},
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: null, // Delegado al BouncyTap
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Descartar', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: BouncyTap(
                      onPressed: () {},
                      child: SizedBox(
                        height: 44,
                        child: FilledButton.icon(
                          onPressed: null, // Delegado al BouncyTap
                          icon: const Icon(Icons.mail_outline, size: 18),
                          label: const Text('Contactar Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: FilledButton.styleFrom(
                            backgroundColor: kBlue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            disabledBackgroundColor: kBlue, // Mantiene el color al deshabilitar el nativo
                            disabledForegroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
