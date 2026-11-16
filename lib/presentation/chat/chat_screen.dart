import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../core/storage/secure_storage.dart';
import '../shared/providers/chat_provider.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/locale_provider.dart';
import '../shared/widgets/app_toast.dart';
import '../shared/widgets/glass_background.dart';
import '../videocall/video_call_screen.dart';
import 'widgets/schedule_interview_dialog.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String otherUserName;
  final String otherUserRole; // e.g. "Empresa" o "Candidato"
  final String vacancyTitle;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.otherUserName,
    required this.otherUserRole,
    this.vacancyTitle = '',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // 1. Cargar historial de mensajes desde la base de datos (REST)
    // 2. Conectar al WebSocket autenticado para tiempo real
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final chat = context.read<ChatProvider>();

      // Sincronizar salas para datos de interlocutor actualizados
      chat.loadRooms();

      // Cargar mensajes existentes de la BD
      await chat.loadMessages(widget.roomId);
      _scrollToBottom();

      // Conectar WebSocket si hay sesión activa
      if (auth.session != null) {
        final storage = SecureStorage();
        final token = await storage.getToken() ?? '';
        if (token.isNotEmpty) {
          chat.connect(auth.session!.userId, token);
        }
      }
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    if (auth.session == null) return;

    setState(() => _isSending = true);
    _messageCtrl.clear();

    try {
      await chat.sendMessage(
        widget.roomId,
        auth.session!.userId,
        text,
      );
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _abrirProgramadorEntrevista() async {
    final scheduled = await ScheduleInterviewDialog.show(
      context,
      roomId: widget.roomId,
      candidateName: widget.otherUserName,
      vacancyTitle: widget.vacancyTitle,
    );

    if (scheduled == true) {
      _scrollToBottom();
    }
  }

  Future<void> _iniciarVideollamada() async {
    final isEs = context.read<LocaleProvider>().isSpanish;
    final chat = context.read<ChatProvider>();

    final title = isEs
        ? 'Entrevista con ${widget.otherUserName}'
        : 'Interview with ${widget.otherUserName}';

    final res = await chat.iniciarVideollamada(widget.roomId, title);
    if (res != null && mounted) {
      final meetingUrl = res['meeting_url']?.toString() ?? '';
      AppToast.success(context, isEs ? '¡Videollamada iniciada!' : 'Video call started!');
      _scrollToBottom();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            meetingUrl: meetingUrl,
            roomTitle: title,
            candidateName: widget.otherUserRole == 'Candidato' ? widget.otherUserName : null,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEs = context.watch<LocaleProvider>().isSpanish;
    final chat = context.watch<ChatProvider>();
    final auth = context.watch<AuthProvider>();
    final myId = auth.session?.userId ?? '';

    final role = auth.session?.role.toLowerCase() ?? '';
    final isEmpresa = role == 'company' || role == 'empresa';

    final roomMessages = chat.getMessagesForRoom(widget.roomId);

    final matchingRoom = chat.rooms.where((r) => r.id == widget.roomId).firstOrNull;
    String headerName = (matchingRoom != null && matchingRoom.otherUserName.isNotEmpty)
        ? matchingRoom.otherUserName
        : widget.otherUserName;

    // Si por alguna razón contiene formato de correo, limpiarlo a formato nombre
    if (headerName.contains('@')) {
      final prefix = headerName.split('@').first;
      final clean = prefix.replaceAll(RegExp(r'[0-9_\.\-]+'), ' ').trim();
      if (clean.isNotEmpty) {
        headerName = clean
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: BackButton(
          color: kNavy,
          onPressed: () {
            context.read<ChatProvider>().disconnect();
            Navigator.pop(context);
          },
        ),
        actions: [
          if (isEmpresa) ...[
            // Botón: Programar entrevista con calendario
            IconButton(
              icon: const Icon(Icons.event_available_rounded, color: kBlue, size: 24),
              tooltip: isEs ? 'Programar fecha de entrevista' : 'Schedule interview',
              onPressed: _abrirProgramadorEntrevista,
            ),
            // Botón: Videollamada inmediata
            IconButton(
              icon: const Icon(Icons.videocam_rounded, color: Color(0xFF10B981), size: 26),
              tooltip: isEs ? 'Iniciar videollamada ahora' : 'Start video call now',
              onPressed: _iniciarVideollamada,
            ),
            const SizedBox(width: 4),
          ],
        ],
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        elevation: 0,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.85),
            width: 1.0,
          ),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Column(
          children: [
            Text(
              headerName,
              style: const TextStyle(color: kNavy, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              chat.isConnected
                  ? (isEs ? 'En línea' : 'Online')
                  : (isEs ? 'Conectado' : 'Connected'),
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          const GlassBackground(),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: chat.isLoadingMessages && roomMessages.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : roomMessages.isEmpty
                          ? Center(
                              child: FadeInUp(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: kBlue.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.chat_bubble_outline_rounded, color: kBlue, size: 36),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      isEs ? 'Conversación iniciada' : 'Conversation started',
                                      style: const TextStyle(
                                        color: kNavy,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isEs
                                          ? 'Escribe un mensaje o programa una entrevista'
                                          : 'Send a message or schedule an interview',
                                      style: const TextStyle(color: kMuted, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              itemCount: roomMessages.length,
                              itemBuilder: (context, index) {
                                final msg = roomMessages[index];
                                final isMe = msg.senderId == myId;

                                return _MessageBubble(
                                  text: msg.content,
                                  isMe: isMe,
                                  time:
                                      "${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}",
                                );
                              },
                            ),
                ),

                // Input Bar (Glassmorphism)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.5))),
                  ),
                  child: Row(
                    children: [
                      if (isEmpresa)
                        IconButton(
                          icon: const Icon(Icons.calendar_today_rounded, color: kBlue, size: 20),
                          tooltip: isEs ? 'Programar fecha' : 'Schedule date',
                          onPressed: _abrirProgramadorEntrevista,
                        ),
                      Expanded(
                        child: TextField(
                          controller: _messageCtrl,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: isEs ? 'Escribe un mensaje...' : 'Type a message...',
                            hintStyle: const TextStyle(fontSize: 13, color: kMuted),
                            filled: true,
                            fillColor: kBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: kLine),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            gradient: kButtonGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    // ── 1. Tarjeta Especial: Entrevista Programada con Fecha y Hora ──
    if (text.startsWith('[INTERVIEW_SCHEDULED]:')) {
      final raw = text.substring('[INTERVIEW_SCHEDULED]:'.length);
      final parts = raw.split('|');
      final meetingUrl = parts.isNotEmpty ? parts[0].trim() : '';
      final title = parts.length > 1 && parts[1].isNotEmpty ? parts[1].trim() : 'Entrevista Laboral';
      final fechaHora = parts.length > 2 && parts[2].isNotEmpty ? parts[2].trim() : 'Por confirmar';
      final notas = parts.length > 3 ? parts[3].trim() : '';

      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Color(0xFFF0FDF4),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF34D399).withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Entrevista Programada',
                              style: TextStyle(
                                color: Color(0xFF065F46),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Color(0xFF374151),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Badge de fecha y hora
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_filled, color: Color(0xFF16A34A), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fechaHora,
                            style: const TextStyle(
                              color: Color(0xFF14532D),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (notas.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Nota: $notas',
                      style: const TextStyle(color: Color(0xFF4B5563), fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],

                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoCallScreen(
                              meetingUrl: meetingUrl,
                              roomTitle: title,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.video_camera_front_rounded, size: 18),
                      label: const Text(
                        'Unirse a la Entrevista',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      time,
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── 2. Tarjeta Especial: Videollamada Inmediata ──
    if (text.startsWith('[VIDEOCALL]:')) {
      final raw = text.substring('[VIDEOCALL]:'.length);
      final parts = raw.split('|');
      final meetingUrl = parts.isNotEmpty ? parts[0].trim() : '';
      final title = parts.length > 1 ? parts[1].trim() : 'Entrevista Laboral TalentMatch';

      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Color(0xFFEFF6FF),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                  width: 1.4,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.videocam_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Entrevista en Vivo',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoCallScreen(
                              meetingUrl: meetingUrl,
                              roomTitle: title,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.video_call_rounded, size: 18),
                      label: const Text(
                        'Unirse a la Videollamada',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── 3. Mensaje de Texto Normal ──
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? kBlue : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isMe ? null : Border.all(color: Colors.white, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : kNavy,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isMe ? Colors.white.withValues(alpha: 0.7) : kMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
