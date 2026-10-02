import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/notificacion.dart';
import '../shared/providers/auth_provider.dart';
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
    final IconData icon;
    final Color color;

    switch (notificacion.tipo) {
      case 'postulacion':
        icon = Icons.fact_check;
        color = kBlue;
        break;
      case 'recomendacion':
        icon = Icons.auto_awesome;
        color = kGreen;
        break;
      default:
        icon = Icons.notifications;
        color = kPurple;
    }

    return GestureDetector(
      onTap: () {
        if (!notificacion.leido) {
          context.read<NotificacionesProvider>().marcarLeida(notificacion.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notificacion.mensaje,
                    style: TextStyle(
                      color: kNavy,
                      fontSize: 15,
                      fontWeight: notificacion.leido ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(notificacion.creadoEn),
                    style: const TextStyle(color: kMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (!notificacion.leido)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: kBlue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} h';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} d';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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
                  decoration: BoxDecoration(
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

