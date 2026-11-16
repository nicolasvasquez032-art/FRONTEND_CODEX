import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../shared/providers/chat_provider.dart';
import '../shared/providers/locale_provider.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/widgets/glass_background.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadRooms();
    });
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEs = context.watch<LocaleProvider>().isSpanish;
    final chatProvider = context.watch<ChatProvider>();
    final rooms = chatProvider.rooms;

    final filteredRooms = _searchQuery.isEmpty
        ? rooms
        : rooms.where((r) {
            return r.otherUserName.toLowerCase().contains(_searchQuery) ||
                (r.lastMessage ?? '').toLowerCase().contains(_searchQuery);
          }).toList();

    final totalUnread = rooms.fold<int>(0, (sum, r) => sum + r.unreadCount);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          const GlassBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar con Glassmorphism ──
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: Colors.white.withValues(alpha: 0.8),
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
                      icon: const Icon(Icons.arrow_back_ios_new, color: kNavy, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  expandedTitleScale: 1.0,
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isEs ? 'Mensajes' : 'Messages',
                        style: const TextStyle(
                          color: kNavy,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (totalUnread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF08C8DF)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$totalUnread ${isEs ? 'nuevos' : 'new'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Barra de Búsqueda ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: GlassCard(
                    borderRadius: BorderRadius.circular(20),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: isEs ? 'Buscar conversación...' : 'Search conversation...',
                        hintStyle: const TextStyle(color: kMuted, fontSize: 14, fontWeight: FontWeight.w500),
                        prefixIcon: const Icon(Icons.search, color: kMuted, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: kMuted),
                                onPressed: () => _searchCtrl.clear(),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Contenido de Conversaciones ──
              if (chatProvider.isLoadingRooms && rooms.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (filteredRooms.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: kBlue.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: kBlue),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isEs ? 'No tienes conversaciones activas' : 'No active conversations',
                            style: const TextStyle(
                              color: kNavy,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isEs
                                ? 'Cuando una empresa te contacte o te comuniques con un candidato, la conversación aparecerá aquí.'
                                : 'When a company contacts you or you reach out to a candidate, your conversations will show up here.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: kMuted, fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final room = filteredRooms[index];
                      return _ChatListItem(
                        room: room,
                        isEs: isEs,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                roomId: room.id,
                                otherUserName: room.otherUserName,
                                otherUserRole: room.otherUserRole,
                              ),
                            ),
                          ).then((_) {
                            if (context.mounted) {
                              context.read<ChatProvider>().loadRooms();
                            }
                          });
                        },
                      );
                    },
                    childCount: filteredRooms.length,
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
  final ChatRoomItem room;
  final bool isEs;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.room,
    required this.isEs,
    required this.onTap,
  });

  static final _emojiRegex = RegExp(
    r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2300}-\u{23FF}\u{2B50}\u{FE0F}]+',
    unicode: true,
  );

  static String _cleanEmojis(String text) {
    return text.replaceAll(_emojiRegex, '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final int unread = room.unreadCount;
    final String initial = room.otherUserName.isNotEmpty ? room.otherUserName.substring(0, 1).toUpperCase() : 'U';

    String timeStr = '';
    if (room.lastMessageTime != null) {
      final now = DateTime.now();
      final diff = now.difference(room.lastMessageTime!);
      if (diff.inDays == 0) {
        timeStr = DateFormat('hh:mm a').format(room.lastMessageTime!);
      } else if (diff.inDays == 1) {
        timeStr = isEs ? 'Ayer' : 'Yesterday';
      } else {
        timeStr = DateFormat('d MMM').format(room.lastMessageTime!);
      }
    }

    final isEmpresaRole = room.otherUserRole.toLowerCase().contains('empresa') ||
        room.otherUserRole.toLowerCase().contains('company');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GlassCard(
        borderRadius: BorderRadius.circular(18),
        padding: const EdgeInsets.all(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isEmpresaRole
                        ? [const Color(0xFF2563EB), const Color(0xFF1D4ED8)]
                        : [const Color(0xFF0D9488), const Color(0xFF08C8DF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isEmpresaRole ? const Color(0xFF2563EB) : const Color(0xFF0D9488)).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Detalles
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            room.otherUserName,
                            style: const TextStyle(
                              color: kNavy,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeStr.isNotEmpty)
                          Text(
                            timeStr,
                            style: TextStyle(
                              color: unread > 0 ? kBlue : kMuted,
                              fontSize: 11,
                              fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isEmpresaRole
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            room.otherUserRole,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isEmpresaRole ? kBlue : const Color(0xFF059669),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _cleanEmojis(room.lastMessage ?? (isEs ? 'Conversación creada' : 'Conversation created')),
                            style: TextStyle(
                              color: unread > 0 ? kNavy : kMuted,
                              fontSize: 13,
                              fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unread > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: kBlue,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
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
      ),
    );
  }
}
