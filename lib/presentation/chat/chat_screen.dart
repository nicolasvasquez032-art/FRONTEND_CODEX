import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../shared/providers/chat_provider.dart';
import '../shared/providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String otherUserName;
  final String otherUserRole; // e.g. "Empresa" o "Candidato"

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.otherUserName,
    required this.otherUserRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Connect to WebSocket using current user's ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final chat = context.read<ChatProvider>();
      if (auth.session != null) {
        chat.connect(auth.session!.userId);
      }
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageCtrl.text.trim().isEmpty) return;
    
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    
    if (auth.session == null) return;

    chat.sendMessage(
      widget.roomId,
      auth.session!.userId,
      _messageCtrl.text.trim(),
    );

    _messageCtrl.clear();
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final auth = context.watch<AuthProvider>();
    final myId = auth.session?.userId ?? '';

    // Filtramos los mensajes que corresponden a esta sala (en caso de que el provider maneje varias)
    final roomMessages = chat.messages.where((m) => m.roomId == widget.roomId).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: BackButton(
          color: kNavy,
          onPressed: () {
            // Desconectar al salir para no dejar sockets abiertos innecesariamente
            context.read<ChatProvider>().disconnect();
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.white.withOpacity(0.7),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Column(
          children: [
            Text(
              widget.otherUserName,
              style: const TextStyle(color: kNavy, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              chat.isConnected ? 'En línea' : 'Desconectado',
              style: TextStyle(
                color: chat.isConnected ? Colors.green : kMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kBlue.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPurple.withOpacity(0.15),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: roomMessages.isEmpty
                      ? Center(
                          child: FadeInUp(
                            child: Text(
                              'Envía el primer mensaje...',
                              style: TextStyle(color: kNavy.withOpacity(0.5), fontSize: 15),
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

                            return FadeInUp(
                              duration: const Duration(milliseconds: 300),
                              child: _MessageBubble(
                                text: msg.content,
                                isMe: isMe,
                                time: "${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}",
                              ),
                            );
                          },
                        ),
                ),
                
                // Input Bar (Glassmorphism)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.5))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageCtrl,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: 'Escribe un mensaje...',
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: kNavy.withOpacity(0.05)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? kBlue : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
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
                color: isMe ? Colors.white.withOpacity(0.7) : kMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
