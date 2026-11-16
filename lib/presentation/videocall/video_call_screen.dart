import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../auth/social_popup_helper.dart';
import '../shared/widgets/app_toast.dart';

/// Pantalla dedicada a la gestión y acceso de Entrevistas por Videollamada en TalentMatch.
class VideoCallScreen extends StatefulWidget {
  final String meetingUrl;
  final String roomTitle;
  final String? candidateName;
  final String? companyName;

  const VideoCallScreen({
    super.key,
    required this.meetingUrl,
    this.roomTitle = 'Entrevista Laboral TalentMatch',
    this.candidateName,
    this.companyName,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrarALaReunion() async {
    final uri = Uri.parse(widget.meetingUrl);

    try {
      if (kIsWeb) {
        SocialPopupHelper.openPopup(
          widget.meetingUrl,
          name: 'TalentMatch_Interview',
          width: 1024,
          height: 720,
        );
        AppToast.info(context, 'Abriendo sala de videoconferencia...');
      } else {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.inAppBrowserView,
          browserConfiguration: const BrowserConfiguration(showTitle: true),
        );
        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'No se pudo abrir la videollamada: $e');
      }
    }
  }

  void _copiarEnlace() {
    Clipboard.setData(ClipboardData(text: widget.meetingUrl));
    AppToast.success(context, 'Enlace de la videollamada copiado al portapapeles');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Sala de Entrevista',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Header Icon con Pulsación ──
              Center(
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseCtrl.value * 0.06);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.35 * _pulseCtrl.value + 0.15),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.videocam_rounded,
                          color: Colors.white,
                          size: 46,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // ── Título y Estado En Vivo ──
              Text(
                widget.roomTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Badge En Vivo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Sala Cifrada y Lista',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Tarjeta Glassmorphic de Detalles ──
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.95),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            icon: Icons.security_rounded,
                            iconColor: const Color(0xFF0EA5E9),
                            label: 'Cifrado',
                            value: 'Extremo a Extremo (WebRTC)',
                          ),
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _buildDetailRow(
                            icon: Icons.mic_none_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                            label: 'Calidad Audio/Video',
                            value: 'HD con cancelación de eco',
                          ),
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _buildDetailRow(
                            icon: Icons.screen_share_outlined,
                            iconColor: const Color(0xFFF59E0B),
                            label: 'Herramientas',
                            value: 'Compartir pantalla y chat interno',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Botón Principal: Entrar a la Videollamada ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _entrarALaReunion,
                  icon: const Icon(Icons.video_call_rounded, size: 24),
                  label: const Text(
                    'Entrar a la Videollamada',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: kBlue.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Botón Secundario: Copiar Enlace ──
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _copiarEnlace,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text(
                    'Copiar enlace de invitación',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.8),
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Consejos Rápidos ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates_outlined, color: Color(0xFF64748B), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recomendación: Permite el acceso a tu cámara y micrófono cuando el navegador lo solicite para una experiencia óptima.',
                      style: TextStyle(
                        color: const Color(0xFF64748B).withValues(alpha: 0.9),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
