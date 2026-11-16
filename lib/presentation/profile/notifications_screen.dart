import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/utils/format_helper.dart';
import '../../domain/entities/notificacion.dart';
import '../applications/applications_screen.dart';
import '../chat/chat_list_screen.dart';
import '../chat/chat_screen.dart';
import '../company/mis_vacantes_screen.dart';
import '../explore/explore_screen.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/chat_provider.dart';
import '../shared/providers/locale_provider.dart';
import '../shared/providers/notificaciones_provider.dart';
import '../shared/widgets/app_toast.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().session?.userId ?? '';
      if (userId.isNotEmpty) {
        context.read<NotificacionesProvider>().cargar(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final np = context.watch<NotificacionesProvider>();
    final session = context.watch<AuthProvider>().session;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Notificaciones',
            style: TextStyle(color: kNavy, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kNavy),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final userId = session?.userId ?? '';
          if (userId.isNotEmpty) {
            await context.read<NotificacionesProvider>().cargar(userId);
          }
        },
        child: _buildBody(np),
      ),
    );
  }

  Widget _buildBody(NotificacionesProvider np) {
    if (np.status == NotificacionesStatus.loading && np.notificaciones.isEmpty) {
      return const _NotificationsSkeleton();
    }

    if (np.status == NotificacionesStatus.error && np.notificaciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: kMuted),
            const SizedBox(height: 16),
            Text(np.error ?? 'Error al cargar', style: const TextStyle(color: kMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final userId = context.read<AuthProvider>().session?.userId ?? '';
                if (userId.isNotEmpty) {
                  context.read<NotificacionesProvider>().cargar(userId);
                }
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (np.notificaciones.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: kMuted),
            SizedBox(height: 16),
            Text('No tienes notificaciones',
                style: TextStyle(color: kNavy, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Te avisaremos cuando haya novedades', style: TextStyle(color: kMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: np.notificaciones.length,
      itemBuilder: (context, index) {
        final notificacion = np.notificaciones[index];
        return FadeInUp(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: 50 * index.clamp(0, 10)),
          child: _NotificationCard(notificacion: notificacion),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Notificacion notificacion;

  const _NotificationCard({required this.notificacion});

  static final _emojiRegex = RegExp(
    r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2300}-\u{23FF}\u{2B50}\u{FE0F}]+',
    unicode: true,
  );

  static String _cleanEmojis(String text) {
    var cleaned = text.replaceAll(_emojiRegex, '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\[CANDIDATO_ID:[^\]]+\]'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\[VACANTE_ID:[^\]]+\]'), '').trim();
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final isEs = context.watch<LocaleProvider>().isSpanish;
    final String tipo = notificacion.tipo.toLowerCase();
    final String mensajeLower = notificacion.mensaje.toLowerCase();

    final IconData icon;
    final Color color;
    final String actionHint;

    if (tipo == 'entrevista_programada' || mensajeLower.contains('entrevista programada')) {
      icon = Icons.event_available_rounded;
      color = const Color(0xFF2563EB);
      actionHint = isEs ? 'Ver entrevista' : 'View interview';
    } else if (tipo == 'videollamada' || mensajeLower.contains('videollamada')) {
      icon = Icons.videocam_rounded;
      color = const Color(0xFF10B981);
      actionHint = isEs ? 'Unirse a llamada' : 'Join call';
    } else if (tipo == 'chat_mensaje' || mensajeLower.contains('mensaje') || mensajeLower.contains('chat')) {
      icon = Icons.chat_bubble_rounded;
      color = const Color(0xFF6366F1);
      actionHint = isEs ? 'Ver conversación' : 'View conversation';
    } else if (tipo.contains('postulacion')) {
      icon = Icons.fact_check_rounded;
      color = const Color(0xFF0284C7);
      final isCompany = context.watch<AuthProvider>().session?.isCompany == true;
      actionHint = isCompany
          ? (isEs ? 'Ver / Descargar CV' : 'View / Download CV')
          : (isEs ? 'Ver postulación' : 'View application');
    } else if (tipo == 'nueva_vacante' || tipo == 'recomendacion' || mensajeLower.contains('vacante')) {
      icon = Icons.auto_awesome_rounded;
      color = const Color(0xFFF59E0B);
      actionHint = isEs ? 'Explorar vacantes' : 'Explore jobs';
    } else {
      icon = Icons.notifications_rounded;
      color = kPurple;
      actionHint = isEs ? 'Ver detalles' : 'View details';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notificacion.leido ? Colors.white : const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notificacion.leido ? kLine : kBlue.withValues(alpha: 0.3),
        ),
        boxShadow: notificacion.leido
            ? null
            : [
                BoxShadow(
                  color: kBlue.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            HapticFeedback.lightImpact();
            if (!notificacion.leido) {
              context.read<NotificacionesProvider>().marcarLeida(notificacion.id);
            }
            await _handleNotificationNavigation(context, notificacion);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _cleanEmojis(notificacion.mensaje),
                        style: TextStyle(
                          color: kNavy,
                          fontSize: 14.5,
                          fontWeight: notificacion.leido ? FontWeight.w500 : FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _formatDate(notificacion.creadoEn, isSpanish: isEs),
                            style: const TextStyle(color: kMuted, fontSize: 11.5),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  actionHint,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: color),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!notificacion.leido)
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: kBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleNotificationNavigation(
    BuildContext context,
    Notificacion notificacion,
  ) async {
    final tipo = notificacion.tipo.toLowerCase();
    final mensaje = notificacion.mensaje.toLowerCase();

    // 1. Notificaciones de chat, videollamada o entrevista programada -> Abrir sala de Chat
    if (tipo.contains('chat') ||
        tipo.contains('video') ||
        tipo.contains('entrevista') ||
        mensaje.contains('videollamada') ||
        mensaje.contains('entrevista') ||
        mensaje.contains('mensaje') ||
        mensaje.contains('chat')) {
      final chatProv = context.read<ChatProvider>();

      if (chatProv.rooms.isEmpty) {
        await chatProv.loadRooms();
      }

      if (!context.mounted) return;

      if (chatProv.rooms.isNotEmpty) {
        // Buscar la sala del interlocutor correspondiente o usar la primera/más reciente
        ChatRoomItem targetRoom = chatProv.rooms.first;
        for (final r in chatProv.rooms) {
          if (notificacion.mensaje.toLowerCase().contains(r.otherUserName.toLowerCase()) ||
              r.otherUserName.toLowerCase().contains(notificacion.mensaje.toLowerCase())) {
            targetRoom = r;
            break;
          }
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              roomId: targetRoom.id,
              otherUserName: targetRoom.otherUserName,
              otherUserRole: targetRoom.otherUserRole,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ChatListScreen(),
          ),
        );
      }
      return;
    }

    // 2. Notificaciones de postulación
    if (tipo.contains('postulacion')) {
      final isCompany = context.read<AuthProvider>().session?.isCompany == true;
      if (isCompany) {
        final candMatch = RegExp(r'\[CANDIDATO_ID:([^\]]+)\]').firstMatch(notificacion.mensaje);
        final candId = candMatch?.group(1);
        final isEs = context.read<LocaleProvider>().isSpanish;

        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.description_rounded, color: Color(0xFF0284C7), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEs ? 'Detalle de Postulación' : 'Application Details',
                              style: const TextStyle(
                                color: kNavy,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              isEs ? 'Candidato postulado a tu vacante' : 'Candidate applied to your job',
                              style: const TextStyle(color: kMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _cleanEmojis(notificacion.mensaje),
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (candId != null && candId.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _descargarCvDesdeNotificacion(context, candId);
                        },
                        icon: const Icon(Icons.file_download_outlined, size: 22),
                        label: Text(
                          isEs ? 'Descargar / Ver CV del Candidato' : 'Download / View Candidate CV',
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
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MisVacantesScreen()),
                        );
                      },
                      icon: const Icon(Icons.work_outline_rounded, size: 20, color: kNavy),
                      label: Text(
                        isEs ? 'Ver Mis Vacantes y Candidatos' : 'View My Jobs & Candidates',
                        style: const TextStyle(color: kNavy, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kLine, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ApplicationsScreen(),
        ),
      );
      return;
    }

    // 3. Notificaciones de vacantes o recomendaciones -> Ir a Explorar
    if (tipo.contains('vacante') || tipo.contains('recomendacion')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ExploreScreen(),
        ),
      );
      return;
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

  Future<void> _descargarCvDesdeNotificacion(BuildContext context, String candidateId) async {
    final isEs = context.read<LocaleProvider>().isSpanish;
    try {
      final client = ApiClient(SecureStorage());
      final res = await client.get('/perfiles/$candidateId/cv-url');
      final fetchedUrl = _normalizarCvUrl(res['cv_url']?.toString());
      final fetchedText = res['cv_text']?.toString();
      final candName = res['full_name']?.toString() ?? 'Candidato';

      if (fetchedUrl != null && fetchedUrl.isNotEmpty) {
        final uri = Uri.parse(fetchedUrl);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (context.mounted) {
            AppToast.success(
              context,
              isEs ? 'Abriendo documento PDF...' : 'Opening PDF document...',
            );
          }
          return;
        } catch (_) {
          // Si falla abrir directo, muestra el modal con el texto y la opción de descarga
        }
      }

      if (fetchedText != null && fetchedText.trim().isNotEmpty) {
        if (context.mounted) {
          _mostrarModalCvTexto(context, candName, fetchedText, fetchedUrl);
        }
        return;
      }

      if (context.mounted) {
        AppToast.info(
          context,
          isEs
              ? 'El candidato tiene su perfil digital verificado pero no adjuntó archivo PDF descargable.'
              : 'Candidate has verified digital profile but no attached downloadable PDF.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        AppToast.error(
          context,
          isEs ? 'No se pudo obtener el CV del candidato' : 'Could not retrieve candidate CV',
        );
      }
    }
  }

  void _mostrarModalCvTexto(BuildContext context, String candidateName, String cvText, [String? cvUrl]) {
    final isEs = context.read<LocaleProvider>().isSpanish;
    final hasPdf = cvUrl != null && cvUrl.isNotEmpty;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.45,
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
                        if (context.mounted) {
                          AppToast.success(
                            context,
                            isEs ? 'Abriendo documento PDF...' : 'Opening PDF document...',
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
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

  String _formatDate(DateTime date, {bool isSpanish = true}) {
    return FormatHelper.formatRelativeTime(date, isSpanish: isSpanish);
  }
}

// ────────────────────────────────────────────────────────
// Widget Custom: Skeleton de Notificaciones
// ────────────────────────────────────────────────────────

class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade50,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 150, height: 16, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: double.infinity, height: 12, color: Colors.white),
                      const SizedBox(height: 4),
                      Container(width: double.infinity, height: 12, color: Colors.white),
                      const SizedBox(height: 10),
                      Container(width: 80, height: 10, color: Colors.white),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

