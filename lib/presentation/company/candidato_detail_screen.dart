import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../chat/chat_screen.dart';
import '../chat/widgets/schedule_interview_dialog.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/widgets/app_toast.dart';
import '../shared/widgets/bouncy_tap.dart';
import '../shared/widgets/match_badge.dart';
import '../videocall/video_call_screen.dart';

class CandidatoDetailScreen extends StatelessWidget {
  final Map<String, dynamic> candidato;

  const CandidatoDetailScreen({super.key, required this.candidato});

  @override
  Widget build(BuildContext context) {
    final int? matchScore = (candidato['match'] as num?)?.toInt();
    final List<String> skills = candidato['skills'] is List
        ? (candidato['skills'] as List).cast<String>()
        : <String>[];
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
                              if (matchScore != null && matchScore > 0)
                                MatchBadge(percent: matchScore, compact: false)
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: const Text('CV en revisión', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
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
                    const FadeInUp(delay: Duration(milliseconds: 300), child: Text('Acerca del Candidato', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy))),
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
                    
                    const FadeInUp(delay: Duration(milliseconds: 500), child: Text('Habilidades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy))),
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
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: BouncyTap(
              onPressed: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
                ),
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
          color: Colors.white.withValues(alpha: 0.9),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: kNavy.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: BouncyTap(
                onPressed: () {
                  AppToast.info(context, 'Candidato descartado');
                  Navigator.pop(context);
                },
                child: SizedBox(
                  height: 55,
                  child: OutlinedButton(
                    onPressed: () {
                      AppToast.info(context, 'Candidato descartado');
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Descartar', style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: BouncyTap(
                onPressed: () => _mostrarOpcionesEntrevista(context),
                child: SizedBox(
                  height: 55,
                  child: FilledButton.icon(
                    onPressed: () => _mostrarOpcionesEntrevista(context),
                    icon: const Icon(Icons.video_call_rounded, size: 22),
                    label: const Text('Agendar Entrevista', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: kBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarOpcionesEntrevista(BuildContext context) {
    final candidateName = candidato['nombre']?.toString() ?? 'Candidato';
    final callCode = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final meetingUrl = 'https://meet.jit.si/TalentMatch-Entrevista-$callCode#config.prejoinPageEnabled=false';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.videocam_rounded, color: Color(0xFF2563EB), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Entrevista Laboral Virtual',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Con $candidateName',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 1. Coordinar por Chat
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _abrirChat(context);
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  label: const Text('Enviar Mensaje por Chat', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 2. Programar Entrevista (Calendario)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final roomId = await _resolverRoomId(context);
                    if (roomId != null && context.mounted) {
                      final scheduled = await ScheduleInterviewDialog.show(
                        context,
                        roomId: roomId,
                        candidateName: candidateName,
                      );
                      if (scheduled == true && context.mounted) {
                        _abrirChat(context);
                      }
                    }
                  },
                  icon: const Icon(Icons.calendar_month_rounded, size: 20),
                  label: const Text('Programar Entrevista (Calendario)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 3. Iniciar Videollamada Inmediata
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoCallScreen(
                          meetingUrl: meetingUrl,
                          roomTitle: 'Entrevista con $candidateName',
                          candidateName: candidateName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.video_call_rounded, size: 22, color: Color(0xFF10B981)),
                  label: const Text('Iniciar Videollamada Inmediata', style: TextStyle(color: kNavy, fontWeight: FontWeight.w700, fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _resolverRoomId(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final session = auth.session;
    final candUserId = candidato['candidato_user_id']?.toString();
    if (session == null || candUserId == null || candUserId.isEmpty) return null;

    try {
      final client = ApiClient(SecureStorage());
      final res = await client.post('/chat/room', {
        'empresa_id': session.userId,
        'candidato_id': candUserId,
      }, auth: true);
      return res['id']?.toString() ?? '${session.userId}_$candUserId';
    } catch (_) {
      return '${session.userId}_$candUserId';
    }
  }

  Future<void> _abrirChat(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final session = auth.session;
    final candUserId = candidato['candidato_user_id']?.toString();
    final candName = candidato['nombre']?.toString() ?? 'Candidato';

    if (session == null || candUserId == null || candUserId.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            roomId: candidato['id']?.toString() ?? 'room_chat',
            otherUserName: candName,
            otherUserRole: 'Candidato',
          ),
        ),
      );
      return;
    }

    try {
      final client = ApiClient(SecureStorage());
      final res = await client.post('/chat/room', {
        'empresa_id': session.userId,
        'candidato_id': candUserId,
      }, auth: true);
      final roomId = res['id']?.toString() ?? '${session.userId}_$candUserId';
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              roomId: roomId,
              otherUserName: candName,
              otherUserRole: 'Candidato',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              roomId: '${session.userId}_$candUserId',
              otherUserName: candName,
              otherUserRole: 'Candidato',
            ),
          ),
        );
      }
    }
  }
}
