import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../chat/chat_list_screen.dart';
import '../../profile/notifications_screen.dart';
import '../providers/locale_provider.dart';
import '../providers/notificaciones_provider.dart';
import 'brand_logo.dart';
import 'language_switch_button.dart';

/// Encabezado superior oficial de TalentMatch idéntico al diseño de Figma.
/// Incluye:
/// - A la izquierda: Logotipo completo [BrandFull] (icono + texto TalentMatch).
/// - A la derecha: Selector de idioma [ES | EN], botón circular de mensajes y botón circular de notificaciones con badge.
class TalentMatchTopHeader extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const TalentMatchTopHeader({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final isEs = context.watch<LocaleProvider>().isSpanish;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Logotipo oficial TalentMatch
          const Flexible(
            child: BrandFull(iconSize: 28),
          ),
          const SizedBox(width: 8),

          // 2. Acciones superiores a la derecha
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selector de Idioma (ES / EN)
              const LanguageSwitchButton(compact: true),
              const SizedBox(width: 8),

              // Botón de Mensajes / Chat
              HeaderCircleButton(
                icon: Icons.chat_bubble_outline_rounded,
                iconSize: 20,
                tooltip: isEs ? 'Mensajes' : 'Messages',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChatListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),

              // Botón de Notificaciones (Campanita) con badge reactivo
              Consumer<NotificacionesProvider>(
                builder: (context, np, _) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      HeaderCircleButton(
                        icon: Icons.notifications_none_rounded,
                        iconSize: 22,
                        tooltip: isEs ? 'Notificaciones' : 'Notifications',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      if (np.noLeidasCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 17,
                              minHeight: 17,
                            ),
                            child: Text(
                              np.noLeidasCount > 9 ? '+9' : '${np.noLeidasCount}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Botón circular blanco con sombra suave y micro-interacción para los encabezados.
class HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final VoidCallback onPressed;
  final String tooltip;

  const HeaderCircleButton({
    super.key,
    required this.icon,
    this.iconSize = 20,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }
}
