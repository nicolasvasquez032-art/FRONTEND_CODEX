import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
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
          // ── Orbes de colores líquidos en el fondo ──
          Positioned(
            top: -50,
            left: -100,
            child: _AnimatedLiquidOrb(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.6), // Azul eléctrico
              size: 350,
              duration: const Duration(seconds: 10),
            ),
          ),
          Positioned(
            top: 250,
            right: -120,
            child: _AnimatedLiquidOrb(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.5), // Morado profundo
              size: 400,
              duration: const Duration(seconds: 15),
            ),
          ),
          Positioned(
            bottom: -50,
            left: 20,
            child: _AnimatedLiquidOrb(
              color: const Color(0xFF10B981).withValues(alpha: 0.4), // Verde esmeralda
              size: 250,
              duration: const Duration(seconds: 12),
            ),
          ),
          
          // Filtro para mezclar los orbes suavemente con el fondo
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), // Mezcla extrema tipo mesh gradient
              child: Container(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
          
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar con Glassmorphism y Animaciones ──
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leadingWidth: 70,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
                  child: FadeInLeft(
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: kNavy.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: kNavy, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.8),
                            Colors.white.withValues(alpha: 0.1),
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
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5), // Altamente translúcido
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Buscar conversación...',
                              hintStyle: const TextStyle(color: kMuted, fontSize: 15, fontWeight: FontWeight.w500),
                              prefixIcon: const Icon(Icons.search, color: kMuted, size: 22),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                          ),
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

// ────────────────────────────────────────────────────────
// Animación de orbes para el fondo líquido
// ────────────────────────────────────────────────────────
class _AnimatedLiquidOrb extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const _AnimatedLiquidOrb({required this.color, required this.size, required this.duration});

  @override
  State<_AnimatedLiquidOrb> createState() => _AnimatedLiquidOrbState();
}

class _AnimatedLiquidOrbState extends State<_AnimatedLiquidOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            20 * _controller.value, // Movimiento sutil en X
            30 * (1 - _controller.value), // Movimiento sutil en Y
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        );
      },
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35), // Máxima transparencia de Liquid Glass
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: kNavy.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Desenfoque de lente fuerte
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              highlightColor: bgColor.withValues(alpha: 0.05),
              splashColor: bgColor.withValues(alpha: 0.1),
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
          ),
        ),
      ),
    );
  }
}
