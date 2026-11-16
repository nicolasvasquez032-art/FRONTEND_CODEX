import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/format_helper.dart';
import '../../domain/entities/notificacion.dart';
import '../applications/applications_screen.dart';
import '../chat/chat_list_screen.dart';
import '../chat/chat_screen.dart';
import '../explore/explore_screen.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/chat_provider.dart';
import '../shared/providers/locale_provider.dart';
import '../shared/providers/notificaciones_provider.dart';

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
      actionHint = isEs ? 'Abrir chat de entrevista' : 'Open interview chat';
    } else if (tipo == 'videollamada' || mensajeLower.contains('videollamada')) {
      icon = Icons.videocam_rounded;
      color = const Color(0xFF10B981);
      actionHint = isEs ? 'Unirse / Ver chat' : 'Join / View chat';
    } else if (tipo == 'chat_mensaje' || mensajeLower.contains('mensaje') || mensajeLower.contains('chat')) {
      icon = Icons.chat_bubble_rounded;
      color = const Color(0xFF6366F1);
      actionHint = isEs ? 'Ver conversación' : 'View conversation';
    } else if (tipo.contains('postulacion')) {
      icon = Icons.fact_check_rounded;
      color = const Color(0xFF0284C7);
      actionHint = isEs ? 'Ver mis postulaciones' : 'View applications';
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
                        notificacion.mensaje,
                        style: TextStyle(
                          color: kNavy,
                          fontSize: 14.5,
                          fontWeight: notificacion.leido ? FontWeight.w500 : FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            _formatDate(notificacion.creadoEn, isSpanish: isEs),
                            style: const TextStyle(color: kMuted, fontSize: 11.5),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  actionHint,
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

    // 2. Notificaciones de postulación -> Ir a Mis Postulaciones
    if (tipo.contains('postulacion')) {
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

