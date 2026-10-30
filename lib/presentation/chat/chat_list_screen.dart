import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/widgets/glass_background.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  // Lista simulada por ahora (luego la conectaremos al backend)
  final List<Map<String, dynamic>> _chats = [
    {
      'roomId': '00000000-0000-0000-0000-000000000000',
      'name': 'Google LLC',
      'role': 'Empresa',
      'lastMessage': '¡Hola! Nos impresionó tu perfil, ¿tienes tiempo para hablar?',
      'time': '10:42 AM',
      'unread': 2,
      'isOnline': true,
      'color': const Color(0xFFDB4437),
    },
    {
      'roomId': '11111111-1111-1111-1111-111111111111',
      'name': 'Microsoft Corp',
      'role': 'Empresa',
      'lastMessage': 'Tu prueba técnica fue excelente.',
      'time': 'Ayer',
      'unread': 0,
      'isOnline': false,
      'color': const Color(0xFF0F9D58),
    },
    {
      'roomId': '22222222-2222-2222-2222-222222222222',
      'name': 'Amazon Web Services',
      'role': 'Empresa',
      'lastMessage': 'Por favor envíanos tu portafolio actualizado.',
      'time': 'Lun',
      'unread': 0,
      'isOnline': true,
      'color': const Color(0xFFF4B400),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF1F5F9), // Fondo base
      body: Stack(
        children: [
          const GlassBackground(),
          
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar con Glassmorphism y Animaciones ──
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: Colors.white.withValues(alpha: 0.75),
                elevation: 0,
                scrolledUnderElevation: 0,
                shape: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 1.0,
                  ),
                ),
                leadingWidth: 70,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
                  child: FadeInLeft(
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: kNavy.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: kNavy, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.85),
                            Colors.white.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                      child: FlexibleSpaceBar(
                        titlePadding: const EdgeInsets.only(left: 24, bottom: 16, right: 24),
                        title: FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 200),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Mensajes',
                                style: TextStyle(
                                  color: kNavy,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Badge de notificaciones pulsante
                              Pulse(
                                infinite: true,
                                duration: const Duration(seconds: 2),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: const Text(
                                    '2 nuevos',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Barra de Búsqueda ──
              SliverToBoxAdapter(
                child: FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    child: GlassCard(
                      borderRadius: BorderRadius.circular(20),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar conversación...',
                          hintStyle: TextStyle(color: kMuted, fontSize: 15, fontWeight: FontWeight.w500),
                          prefixIcon: Icon(Icons.search, color: kMuted, size: 22),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Lista de Chats ──
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final chat = _chats[index];
                    return FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: Duration(milliseconds: 100 * index),
                      child: _ChatListItem(
                        chat: chat,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                roomId: chat['roomId'],
                                otherUserName: chat['name'],
                                otherUserRole: chat['role'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  childCount: _chats.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
        ],
      ),
    );
  }
}



class _ChatListItem extends StatelessWidget {
  final Map<String, dynamic> chat;
  final VoidCallback onTap;

  const _ChatListItem({required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final int unread = chat['unread'] ?? 0;
    final bool isOnline = chat['isOnline'] ?? false;
    final String initial = (chat['name'] as String).substring(0, 1);
    final Color bgColor = chat['color'] ?? kBlue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Avatar con indicador de estado
              Stack(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: bgColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: bgColor.withValues(alpha: 0.2), width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: bgColor,
                      ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E), // Verde vibrante
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 18),
              
              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            chat['name'],
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: kNavy,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          chat['time'],
                          style: TextStyle(
                            fontSize: 12,
                            color: unread > 0 ? kBlue : kMuted,
                            fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat['lastMessage'],
                            style: TextStyle(
                              fontSize: 14,
                              color: unread > 0 ? kNavy : kMuted.withValues(alpha: 0.8),
                              fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: kBlue,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: kBlue.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Text(
                              unread > 9 ? '9+' : unread.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
