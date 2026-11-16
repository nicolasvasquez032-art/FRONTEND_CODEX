import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../domain/entities/postulacion.dart';
import '../../domain/entities/vacante.dart';
import '../chat/chat_screen.dart';
import '../chat/widgets/schedule_interview_dialog.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/locale_provider.dart';
import '../shared/providers/postulaciones_provider.dart';
import '../shared/widgets/app_toast.dart';
import '../shared/widgets/bouncy_tap.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/widgets/match_badge.dart';
import '../shared/widgets/shimmer_cards.dart';
import '../videocall/video_call_screen.dart';
import 'candidato_detail_screen.dart';

class CandidatosVacanteScreen extends StatefulWidget {
  final Vacante vacante;
  const CandidatosVacanteScreen({super.key, required this.vacante});

  @override
  State<CandidatosVacanteScreen> createState() => _CandidatosVacanteScreenState();
}

class _CandidatosVacanteScreenState extends State<CandidatosVacanteScreen> {
  bool _isLoading = true;
  bool _sortByMatch = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _candidatos = [];

  List<Map<String, dynamic>> get _sortedCandidatos {
    final list = List<Map<String, dynamic>>.from(_candidatos);
    if (_sortByMatch) {
      list.sort((a, b) {
        final aScore = (a['match'] as num?) ?? -1;
        final bScore = (b['match'] as num?) ?? -1;
        return bScore.compareTo(aScore);
      });
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _cargarPostulaciones();
  }

  Future<void> _cargarPostulaciones() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repo = context.read<PostulacionesProvider>();
      final postulaciones = await repo.listarPorVacante(widget.vacante.id);

      _candidatos = postulaciones.map((p) {
        final nombre = (p.candidatoNombre != null && p.candidatoNombre!.trim().isNotEmpty)
            ? p.candidatoNombre!.trim()
            : 'Candidato ${p.candidatoId.length > 6 ? p.candidatoId.substring(0, 6) : p.candidatoId}';

        final skills = (p.candidatoSkills != null && p.candidatoSkills!.isNotEmpty)
            ? p.candidatoSkills!
            : ['Perfil Profesional'];

        final profesion = (p.candidatoJobTitle != null && p.candidatoJobTitle!.trim().isNotEmpty)
            ? p.candidatoJobTitle!.trim()
            : (skills.isNotEmpty ? skills.first : 'Desarrollador de Software');

        double? matchScore;
        if (p.scoreMatch != null && p.scoreMatch! > 0) {
          matchScore = p.scoreMatch! <= 1.0 ? p.scoreMatch! * 100 : p.scoreMatch!;
        }

        return {
          'id': p.id,
          'candidato_id': p.candidatoId,
          'candidato_user_id': p.candidatoUserId,
          'nombre': nombre,
          'profesion': profesion,
          'match': matchScore,
          'imagen': 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(nombre)}&background=2563EB&color=fff&size=200',
          'skills': skills,
          'estado': p.estado.label,
          'raw_estado': p.estado,
          'email': p.candidatoEmail,
          'location': p.candidatoLocation ?? 'Colombia',
          'experiencia': p.candidatoExperienceYears ?? 0,
          'phone': p.candidatoPhone,
          'candidato_cv_url': p.candidatoCvUrl,
          'candidato_cv_text': p.candidatoCvText,
        };
      }).toList();
    } catch (e) {
      _candidatos = [];
      _errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _resolverRoomId(Map<String, dynamic> cand) async {
    final auth = context.read<AuthProvider>();
    final session = auth.session;
    final candUserId = cand['candidato_user_id']?.toString();
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

  Future<void> _abrirChat(Map<String, dynamic> cand) async {
    final candName = cand['nombre']?.toString() ?? 'Candidato';
    final roomId = await _resolverRoomId(cand);

    if (roomId == null) {
      if (mounted) AppToast.error(context, 'No se pudo vincular la sala de chat');
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            roomId: roomId,
            otherUserName: candName,
            otherUserRole: 'Candidato',
            vacancyTitle: widget.vacante.titulo,
          ),
        ),
      );
    }
  }

  void _contactarPerfil(Map<String, dynamic> cand) {
    final candidateName = cand['nombre']?.toString() ?? 'Candidato';
    final isEs = context.read<LocaleProvider>().isSpanish;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: kBlue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.contact_mail_rounded, color: kBlue, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEs ? 'Contactar Candidato' : 'Contact Candidate',
                          style: const TextStyle(
                            color: kNavy,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          candidateName,
                          style: const TextStyle(
                            color: kMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 1. Enviar mensaje por Chat
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _abrirChat(cand);
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  label: Text(
                    isEs ? 'Enviar Mensaje por Chat' : 'Send Message via Chat',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Programar Entrevista (Calendario)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final roomId = await _resolverRoomId(cand);
                    if (roomId != null && mounted) {
                      final scheduled = await ScheduleInterviewDialog.show(
                        context,
                        roomId: roomId,
                        candidateName: candidateName,
                        vacancyTitle: widget.vacante.tituloLocalized(isEs),
                      );
                      if (scheduled == true && mounted) {
                        _abrirChat(cand);
                      }
                    }
                  },
                  icon: const Icon(Icons.calendar_month_rounded, size: 20),
                  label: Text(
                    isEs ? 'Programar Entrevista (Calendario)' : 'Schedule Interview (Calendar)',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488), // Teal corporativo
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3. Videollamada Inmediata
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final callCode = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
                    final meetingUrl = 'https://meet.jit.si/TalentMatch-Entrevista-$callCode#config.prejoinPageEnabled=false';
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
                  label: Text(
                    isEs ? 'Iniciar Videollamada Inmediata' : 'Start Instant Video Call',
                    style: const TextStyle(color: kNavy, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
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

  Future<void> _descartarCandidato(Map<String, dynamic> cand) async {
    final isEs = context.read<LocaleProvider>().isSpanish;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEs ? 'Descartar Candidato' : 'Reject Candidate'),
        content: Text(isEs
            ? '¿Estás seguro de que deseas marcar como descartado a este candidato?'
            : 'Are you sure you want to mark this candidate as rejected?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isEs ? 'Cancelar' : 'Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isEs ? 'Descartar' : 'Reject', style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final client = ApiClient(SecureStorage());
        final postulacionId = cand['id']?.toString();
        if (postulacionId != null) {
          await client.patch(
            '/postulaciones/$postulacionId/estado',
            {'estado': 'rechazado'},
          );
        }
        if (mounted) {
          AppToast.info(context, isEs ? 'Candidato descartado' : 'Candidate marked as rejected');
          _cargarPostulaciones();
        }
      } catch (_) {
        if (mounted) {
          AppToast.info(context, isEs ? 'Candidato descartado' : 'Candidate rejected');
          setState(() {
            cand['estado'] = 'Rechazado';
          });
        }
      }
    }
  }

  String? _normalizarCvUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final trimmed = rawUrl.trim();
    if (trimmed.startsWith('http://localhost') || trimmed.startsWith('http://127.0.0.1')) {
      final uri = Uri.parse(trimmed);
      return '$kBaseUrl${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
    }
    if (trimmed.startsWith('/')) {
      return '$kBaseUrl$trimmed';
    }
    if (trimmed.startsWith('cvs/')) {
      final fileName = trimmed.split('/').last;
      return '$kBaseUrl/api/v1/cvs/download/$fileName';
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return null;
  }

  Future<void> _descargarCvCandidato(Map<String, dynamic> cand) async {
    final candName = cand['candidato_nombre']?.toString() ??
        cand['nombre']?.toString() ??
        'Candidato';
    final candidateId = cand['candidato_id']?.toString() ?? cand['id']?.toString();

    // Resolver URL directa si ya viene en el payload
    String? cvUrl = _normalizarCvUrl(cand['candidato_cv_url']?.toString() ?? cand['cv_url']?.toString());
    String? cvText = cand['candidato_cv_text']?.toString() ?? cand['cv_text']?.toString();

    // Si aún no tenemos la URL completa de descarga o el extracto, consultamos el backend
    if ((cvUrl == null || cvText == null) && candidateId != null && candidateId.isNotEmpty) {
      try {
        final client = ApiClient(SecureStorage());
        final res = await client.get('/perfiles/$candidateId/cv-url');
        final fetchedUrl = _normalizarCvUrl(res['cv_url']?.toString());
        final fetchedText = res['cv_text']?.toString();
        if (fetchedUrl != null && fetchedUrl.isNotEmpty) cvUrl = fetchedUrl;
        if (fetchedText != null && fetchedText.isNotEmpty) cvText = fetchedText;
      } catch (e) {
        debugPrint('Error al consultar CV del candidato: $e');
      }
    }

    if (!mounted) return;

    _mostrarModalOpcionesCv(
      candidateName: candName,
      cvUrl: cvUrl,
      cvText: cvText,
    );
  }

  void _mostrarModalOpcionesCv({
    required String candidateName,
    required String? cvUrl,
    required String? cvText,
  }) {
    final isEs = context.read<LocaleProvider>().isSpanish;
    final hasPdf = cvUrl != null && cvUrl.isNotEmpty;
    final hasText = cvText != null && cvText.trim().isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: kBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.description_rounded, color: kBlue, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEs ? 'Currículum Vitae' : 'Curriculum Vitae',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: kNavy),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          candidateName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: kMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Opción 1: Descargar archivo PDF
              InkWell(
                onTap: hasPdf
                    ? () async {
                        Navigator.pop(ctx);
                        final uri = Uri.parse(cvUrl);
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                          if (mounted) {
                            AppToast.success(
                              context,
                              isEs ? 'Abriendo documento PDF...' : 'Opening PDF document...',
                            );
                          }
                        } catch (_) {
                          if (mounted) {
                            AppToast.error(
                              context,
                              isEs ? 'No se pudo abrir el enlace de descarga' : 'Could not open download link',
                            );
                          }
                        }
                      }
                    : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: hasPdf ? kBlue.withValues(alpha: 0.06) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasPdf ? kBlue.withValues(alpha: 0.3) : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: hasPdf ? kBlue : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.file_download_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEs ? 'Descargar Documento PDF' : 'Download PDF Document',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: hasPdf ? kNavy : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hasPdf
                                  ? (isEs
                                      ? 'Abrir o descargar el archivo original en tu celular'
                                      : 'Open or download the original file on your phone')
                                  : (isEs
                                      ? 'El candidato no adjuntó archivo PDF descargable'
                                      : 'Candidate did not attach a downloadable PDF'),
                              style: TextStyle(
                                fontSize: 12,
                                color: hasPdf ? kMuted : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: hasPdf ? kBlue : Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Opción 2: Ver extracto de texto parseado por IA
              InkWell(
                onTap: hasText
                    ? () {
                        Navigator.pop(ctx);
                        _mostrarModalCvTexto(candidateName, cvText, cvUrl);
                      }
                    : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: hasText ? const Color(0xFFF8FAFC) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasText ? kLine : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: hasText ? const Color(0xFF6366F1) : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEs ? 'Ver Extracto de Texto IA' : 'View AI Text Summary',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: hasText ? kNavy : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hasText
                                  ? (isEs
                                      ? 'Leer el texto analizado por la Inteligencia Artificial'
                                      : 'Read the text parsed by Artificial Intelligence')
                                  : (isEs
                                      ? 'Sin extracto de texto disponible'
                                      : 'No text summary available'),
                              style: TextStyle(
                                fontSize: 12,
                                color: hasText ? kMuted : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: hasText ? const Color(0xFF6366F1) : Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),

              if (hasPdf) ...[
                const SizedBox(height: 12),
                // Opción 3: Copiar enlace
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: cvUrl));
                    Navigator.pop(ctx);
                    AppToast.success(
                      context,
                      isEs ? 'Enlace del CV copiado al portapapeles' : 'CV link copied to clipboard',
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kLine),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link_rounded, color: kNavy, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isEs ? 'Copiar enlace directo de descarga' : 'Copy direct download link',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kNavy),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarModalCvTexto(String candidateName, String cvText, [String? cvUrl]) {
    final isEs = context.read<LocaleProvider>().isSpanish;
    final hasPdf = cvUrl != null && cvUrl.isNotEmpty;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.description_rounded, color: kBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEs ? 'Currículum Vitae (Extracto IA)' : 'Curriculum Vitae (AI Summary)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kNavy),
                        ),
                        Text(
                          candidateName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: kMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              if (hasPdf) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(cvUrl);
                      try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                        if (mounted) {
                          AppToast.success(
                            context,
                            isEs ? 'Abriendo documento PDF...' : 'Opening PDF document...',
                          );
                        }
                      } catch (_) {
                        if (mounted) {
                          AppToast.error(
                            context,
                            isEs ? 'No se pudo abrir el enlace de descarga' : 'Could not open download link',
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.file_download_outlined, size: 20),
                    label: Text(
                      isEs ? 'Descargar Archivo PDF Original' : 'Download Original PDF File',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SelectableText(
                    cvText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF334155),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEs = context.watch<LocaleProvider>().isSpanish;
    final isPremium = context.watch<AuthProvider>().session?.isEffectivelyPremium == true;

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _cargarPostulaciones,
            color: kBlue,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                expandedHeight: 220,
                pinned: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: isPremium
                          ? kPremiumBannerGradient
                          : const LinearGradient(
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
                              FadeInDown(child: Text(isEs ? 'Candidatos para:' : 'Candidates for:', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold))),
                              const SizedBox(height: 4),
                              FadeInLeft(
                                delay: const Duration(milliseconds: 200),
                                child: Text(
                                  widget.vacante.tituloLocalized(isEs),
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
                                  decoration: BoxDecoration(
                                    color: isPremium
                                        ? kGold.withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: isPremium
                                        ? Border.all(color: kGoldLight.withValues(alpha: 0.5))
                                        : null,
                                  ),
                                  child: Text(
                                    _isLoading
                                        ? (isEs ? 'Cargando...' : 'Loading...')
                                        : '${_candidatos.length} ${isEs ? 'postulantes en total' : 'total applicants'}',
                                    style: TextStyle(
                                      color: isPremium ? kGoldLight : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
              if (!_isLoading && _candidatos.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isPremium ? kGold.withValues(alpha: 0.3) : kLine),
                        boxShadow: [
                          BoxShadow(
                            color: (isPremium ? kGold : kNavy).withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => setState(() => _sortByMatch = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: _sortByMatch
                                      ? (isPremium ? kGold.withValues(alpha: 0.2) : kBlue.withValues(alpha: 0.1))
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _sortByMatch
                                        ? (isPremium ? kGold : kBlue)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 15,
                                      color: _sortByMatch ? (isPremium ? kGoldDark : kBlue) : kMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isEs ? 'Mayor Afinidad IA' : 'Highest AI Match',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: _sortByMatch ? FontWeight.w800 : FontWeight.w500,
                                        color: _sortByMatch ? (isPremium ? kGoldDark : kBlue) : kNavy,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => setState(() => _sortByMatch = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: !_sortByMatch
                                      ? (isPremium ? kGold.withValues(alpha: 0.2) : kBlue.withValues(alpha: 0.1))
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: !_sortByMatch
                                        ? (isPremium ? kGold : kBlue)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 15,
                                      color: !_sortByMatch ? (isPremium ? kGoldDark : kBlue) : kMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isEs ? 'Más Recientes' : 'Most Recent',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: !_sortByMatch ? FontWeight.w800 : FontWeight.w500,
                                        color: !_sortByMatch ? (isPremium ? kGoldDark : kBlue) : kNavy,
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
                ),
              if (_isLoading)
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: CandidatoShimmerCard(),
                      ),
                      childCount: 2,
                    ),
                  ),
                )
              else if (_candidatos.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: (_errorMessage != null ? Colors.redAccent : kBlue).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _errorMessage != null ? Icons.error_outline_rounded : Icons.people_outline,
                              size: 56,
                              color: _errorMessage != null ? Colors.redAccent : kBlue,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _errorMessage != null
                                ? (isEs ? 'Error al cargar candidatos' : 'Error loading candidates')
                                : (isEs ? 'Aún no hay postulaciones' : 'No applications yet'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage != null
                                ? (isEs
                                    ? 'No se pudo sincronizar la lista de candidatos. Desliza hacia abajo o presiona el botón para reintentar.'
                                    : 'Could not sync candidate list. Pull down or tap the button to retry.')
                                : (isEs
                                    ? 'Los candidatos que se postulen a esta vacante aparecerán aquí con sus datos y compatibilidad.'
                                    : 'Candidates who apply to this vacancy will appear here with profile and match info.'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: kMuted, height: 1.4),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _cargarPostulaciones,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text(isEs ? 'Reintentar' : 'Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final cand = _sortedCandidatos[index];
                        return FadeInUp(
                          duration: const Duration(milliseconds: 500),
                          delay: Duration(milliseconds: 80 * index.clamp(0, 10)),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _CandidatoCard(
                              candidato: cand,
                              vacanteRequisitos: widget.vacante.requisitos,
                              isPremium: isPremium,
                              onContactar: () => _contactarPerfil(cand),
                              onDescartar: () => _descartarCandidato(cand),
                              onDescargarCv: () => _descargarCvCandidato(cand),
                            ),
                          ),
                        );
                      },
                      childCount: _sortedCandidatos.length,
                    ),
                  ),
                ),
            ],
          ),
          ),

          Positioned(
            top: 50,
            left: 20,
            child: FadeInDown(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: BouncyTap(
                    onPressed: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
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
          ),
        ],
      ),
    );
  }
}

class _CandidatoCard extends StatelessWidget {
  final Map<String, dynamic> candidato;
  final List<String> vacanteRequisitos;
  final bool isPremium;
  final VoidCallback onContactar;
  final VoidCallback onDescartar;
  final VoidCallback? onDescargarCv;

  const _CandidatoCard({
    required this.candidato,
    this.vacanteRequisitos = const [],
    this.isPremium = false,
    required this.onContactar,
    required this.onDescartar,
    this.onDescargarCv,
  });

  @override
  Widget build(BuildContext context) {
    final int? matchScore = (candidato['match'] as num?)?.toInt();
    final List<String> skills = candidato['skills'] is List
        ? (candidato['skills'] as List).cast<String>()
        : <String>[];
    final String estado = candidato['estado']?.toString() ?? 'Postulado';
    final isEs = context.watch<LocaleProvider>().isSpanish;

    // Desglose de Requisitos Cumplidos vs Pendientes por la IA
    final candSkillsLower = skills.map((s) => s.toLowerCase().trim()).toSet();
    final List<String> cumple = [];
    final List<String> falta = [];

    for (final r in vacanteRequisitos) {
      final rTrim = r.trim();
      if (rTrim.isEmpty) continue;
      final rLower = rTrim.toLowerCase();
      final match = candSkillsLower.any((s) => s.contains(rLower) || rLower.contains(s));
      if (match) {
        cumple.add(rTrim);
      } else {
        falta.add(rTrim);
      }
    }

    final bool isTopMatch = matchScore != null && matchScore >= 85;

    Color estadoColor = Colors.blueAccent;
    if (estado.toLowerCase().contains('nuevo') || estado.toLowerCase().contains('postulado')) {
      estadoColor = const Color(0xFF10B981);
    }
    if (estado.toLowerCase().contains('rechazado')) {
      estadoColor = Colors.redAccent;
    }

    return BouncyTap(
      scaleFactor: 0.98,
      onPressed: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, _, _) => CandidatoDetailScreen(candidato: candidato),
            transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 24,
        customBorder: (isPremium && isTopMatch)
            ? Border.all(color: kGold.withValues(alpha: 0.6), width: 1.6)
            : null,
        child: Column(
          children: [
            // Insignia Top Candidato IA para empresas premium
            if (isPremium && isTopMatch)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                decoration: const BoxDecoration(
                  gradient: kGoldGradient,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      isEs
                          ? 'CANDIDATO TOP IA (AFINIDAD $matchScore%)'
                          : 'TOP AI MATCH CANDIDATE ($matchScore%)',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

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
                        border: (isPremium && isTopMatch)
                            ? Border.all(color: kGoldLight, width: 2)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: (isPremium && isTopMatch)
                                ? kGold.withValues(alpha: 0.35)
                                : kBlue.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Hero(
                          tag: 'candidato_avatar_${candidato['nombre']}',
                          child: Image.network(
                            candidato['imagen'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              final name = candidato['nombre']?.toString() ?? 'C';
                              return Container(
                                color: kNavy,
                                alignment: Alignment.center,
                                child: Text(
                                  name.isNotEmpty ? name[0] : 'C',
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
                                candidato['nombre'] ?? '',
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
                        Text(
                          candidato['profesion'] ?? '',
                          style: const TextStyle(fontSize: 13, color: kMuted, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (matchScore != null && matchScore > 0)
                              ElasticIn(
                                delay: const Duration(milliseconds: 800),
                                child: MatchBadge(percent: matchScore, compact: true),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'CV en revisión',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Desglose de Compatibilidad IA (Requisitos Cumplidos / Por Evaluar)
            if (cumple.isNotEmpty || falta.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isPremium ? const Color(0xFFFAF5EC) : const Color(0xFFF8FAFC),
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: isPremium ? kGold.withValues(alpha: 0.25) : kLine.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          size: 14,
                          color: isPremium ? kGoldDark : kBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isEs ? 'Desglose de Compatibilidad IA:' : 'AI Fit Breakdown:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isPremium ? kGoldDark : kNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (cumple.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isEs ? 'Cumple:' : 'Meets:',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                            ),
                          ),
                          ...cumple.take(4).map(
                                (c) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFA7F3D0)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check, size: 10, color: Color(0xFF059669)),
                                      const SizedBox(width: 3),
                                      Text(
                                        c,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                      ),
                    if (cumple.isNotEmpty && falta.isNotEmpty) const SizedBox(height: 4),
                    if (falta.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isEs ? 'Por evaluar:' : 'To assess:',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                            ),
                          ),
                          ...falta.take(3).map(
                                (f) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.help_outline_rounded, size: 10, color: Color(0xFFD97706)),
                                      const SizedBox(width: 3),
                                      Text(
                                        f,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                      ),
                  ],
                ),
              ),

            // Skills chips
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

            // Botón Ver / Descargar CV
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
              child: OutlinedButton(
                onPressed: onDescargarCv,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  side: BorderSide(color: kBlue.withValues(alpha: 0.4), width: 1.2),
                  backgroundColor: kBlue.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.file_download_outlined, size: 20, color: kBlue),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isEs ? 'Ver / Descargar CV del Candidato' : 'View / Download Candidate CV',
                        style: const TextStyle(
                          color: kBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Acciones de contacto
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: BouncyTap(
                      onPressed: onDescartar,
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: onDescartar,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              isEs ? 'Descartar' : 'Reject',
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: BouncyTap(
                      onPressed: onContactar,
                      child: SizedBox(
                        height: 44,
                        child: Container(
                          decoration: isPremium
                              ? BoxDecoration(
                                  gradient: kPremiumGoldButtonGradient,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kGold.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                )
                              : null,
                          child: FilledButton.icon(
                            onPressed: onContactar,
                            icon: const Icon(Icons.mail_outline, size: 18),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                isEs ? 'Contactar Perfil' : 'Contact Profile',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: isPremium ? Colors.transparent : kBlue,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              disabledBackgroundColor: isPremium ? Colors.transparent : kBlue,
                              disabledForegroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
