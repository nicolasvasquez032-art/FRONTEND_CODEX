import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Message {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool leido;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.leido = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      roomId: json['room_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['creado_en'] != null ? DateTime.parse(json['creado_en']) : DateTime.now(),
      leido: json['leido'] ?? false,
    );
  }
}

class ChatProvider extends ChangeNotifier {
  WebSocketChannel? _channel;
  List<Message> _messages = [];
  bool _isConnected = false;

  List<Message> get messages => _messages;
  bool get isConnected => _isConnected;

  void connect(String userId) {
    if (_isConnected) return;
    
    // IP para AWS EC2 Production
    final wsUrl = Uri.parse('ws://18.191.162.235:8000/chat/ws/$userId');
    
    try {
      _channel = WebSocketChannel.connect(wsUrl);
      _isConnected = true;
      notifyListeners();

      _channel!.stream.listen(
        (data) {
          final decoded = jsonDecode(data);
          final newMessage = Message.fromJson(decoded);
          
          // Agregamos el mensaje nuevo (o lo actualizamos)
          _messages.add(newMessage);
          notifyListeners();
        },
        onError: (error) {
          if (kDebugMode) print('WebSocket Error: $error');
          _isConnected = false;
          notifyListeners();
        },
        onDone: () {
          _isConnected = false;
          notifyListeners();
        },
      );
    } catch (e) {
      if (kDebugMode) print('Could not connect: $e');
      _isConnected = false;
    }
  }

  void sendMessage(String roomId, String senderId, String content) {
    if (!_isConnected || _channel == null) return;
    
    final payload = {
      'room_id': roomId,
      'content': content,
    };
    
    _channel!.sink.add(jsonEncode(payload));
    
    // We can optimistically add the message to the UI here if we want,
    // but our backend logic echoes the message back to the sender, so we just wait.
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    _messages.clear();
    notifyListeners();
  }
  
  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
