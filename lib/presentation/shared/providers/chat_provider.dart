import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:talentmatch/core/network/api_client.dart';
import 'package:talentmatch/core/storage/secure_storage.dart';
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
      id: json['id']?.toString() ?? '',
      roomId: json['room_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['creado_en'] != null
          ? (DateTime.tryParse(json['creado_en'].toString()) ?? DateTime.now())
          : DateTime.now(),
      leido: json['leido'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'room_id': roomId,
        'sender_id': senderId,
        'content': content,
        'creado_en': createdAt.toIso8601String(),
        'leido': leido,
      };
}

class ChatRoomItem {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String otherUserRole;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  ChatRoomItem({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory ChatRoomItem.fromJson(Map<String, dynamic> json) {
    return ChatRoomItem(
      id: json['id']?.toString() ?? '',
      otherUserId: json['other_user_id']?.toString() ?? '',
      otherUserName: json['other_user_name']?.toString() ?? 'Usuario',
      otherUserRole: json['other_user_role']?.toString() ?? 'Candidato',
      lastMessage: json['last_message']?.toString(),
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.tryParse(json['last_message_time'].toString())
          : null,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChatProvider extends ChangeNotifier {
  final ApiClient _client;
  WebSocketChannel? _channel;

  // Almacenamiento indexado por roomId para persistencia local
  final Map<String, List<Message>> _messagesByRoom = {};
  List<ChatRoomItem> _rooms = [];

  bool _isLoadingMessages = false;
  bool _isLoadingRooms = false;
  bool _isConnected = false;
  String? _activeRoomId;

  ChatProvider({ApiClient? client, SecureStorage? storage})
      : _client = client ?? ApiClient(storage ?? SecureStorage());

  List<Message> get messages => _activeRoomId != null ? (_messagesByRoom[_activeRoomId] ?? []) : [];
  List<Message> getMessagesForRoom(String roomId) => _messagesByRoom[roomId] ?? [];
  List<ChatRoomItem> get rooms => _rooms;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isLoadingRooms => _isLoadingRooms;
  bool get isConnected => _isConnected;
  String? get activeRoomId => _activeRoomId;

  /// Limpia las salas y mensajes al cerrar o cambiar de sesión
  void limpiar() {
    disconnect();
    _messagesByRoom.clear();
    _rooms = [];
    _isLoadingMessages = false;
    _isLoadingRooms = false;
    _activeRoomId = null;
    notifyListeners();
  }

  /// Carga la lista de conversaciones activas desde el backend
  Future<void> loadRooms() async {
    _isLoadingRooms = true;
    notifyListeners();

    try {
      final res = await _client.getList('/chat/rooms', auth: true);
      _rooms = res.map((item) => ChatRoomItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) print('[ChatProvider] Error cargando salas: $e');
    } finally {
      _isLoadingRooms = false;
      notifyListeners();
    }
  }

  /// Carga el historial de mensajes de una conversación específica desde el backend
  Future<void> loadMessages(String roomId) async {
    _activeRoomId = roomId;
    _isLoadingMessages = true;
    notifyListeners();

    try {
      final res = await _client.getList('/chat/$roomId/messages', auth: true);
      final loaded = res.map((m) => Message.fromJson(m as Map<String, dynamic>)).toList();
      _messagesByRoom[roomId] = loaded;
    } catch (e) {
      if (kDebugMode) print('[ChatProvider] Error cargando mensajes de la sala $roomId: $e');
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Conecta al WebSocket autenticado para recepción y envío en tiempo real
  void connect(String userId, String token) {
    if (_isConnected) return;

    final wsUrl = Uri.parse(
      '$kWsBaseUrl/chat/ws/$userId?token=${Uri.encodeComponent(token)}',
    );

    try {
      _channel = WebSocketChannel.connect(wsUrl);
      _isConnected = true;
      notifyListeners();

      _channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data);
            final newMessage = Message.fromJson(decoded);
            _agregarMensaje(newMessage);
          } catch (e) {
            if (kDebugMode) print('[ChatProvider] Error decodificando mensaje WS: $e');
          }
        },
        onError: (error) {
          if (kDebugMode) print('[ChatProvider] WebSocket Error: $error');
          _isConnected = false;
          notifyListeners();
        },
        onDone: () {
          _isConnected = false;
          notifyListeners();
        },
      );
    } catch (e) {
      if (kDebugMode) print('[ChatProvider] No se pudo conectar WebSocket: $e');
      _isConnected = false;
    }
  }

  /// Envía un mensaje con garantía de entrega: optimista en UI + persistencia en PostgreSQL por REST
  Future<void> sendMessage(String roomId, String senderId, String content) async {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) return;

    // 1. Mensaje optimista para actualización inmediata en UI
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMsg = Message(
      id: tempId,
      roomId: roomId,
      senderId: senderId,
      content: cleanContent,
      createdAt: DateTime.now(),
      leido: false,
    );
    _agregarMensaje(optimisticMsg);

    // 2. Envío canónico por HTTP REST para garantizar persistencia única en PostgreSQL
    // Nota: El backend persiste el mensaje y lo transmite por WebSocket en vivo al destinatario.
    // No usamos channel.sink.add aquí para evitar escrituras concurrentes duplicadas en la BD.
    try {
      final res = await _client.post(
        '/chat/$roomId/messages',
        {'content': cleanContent},
        auth: true,
      );

      final realMsg = Message.fromJson(res);
      // Reemplazar el mensaje optimista con el real devuelto por la BD
      final list = _messagesByRoom[roomId] ?? [];
      final idx = list.indexWhere((m) => m.id == tempId);
      if (idx != -1) {
        list[idx] = realMsg;
        notifyListeners();
      } else {
        _agregarMensaje(realMsg);
      }
    } catch (e) {
      if (kDebugMode) print('[ChatProvider] Error enviando mensaje REST: $e');
    }
  }

  /// Programa una entrevista laboral con fecha y hora específicas
  Future<Map<String, dynamic>?> programarEntrevista(
    String roomId,
    String titulo,
    String fechaHora, {
    String? notas,
  }) async {
    try {
      final res = await _client.post(
        '/chat/$roomId/programar-entrevista',
        {
          'titulo': titulo,
          'fecha_hora': fechaHora,
          'notas': notas,
        },
        auth: true,
      );

      if (res['message'] != null) {
        final msg = Message.fromJson(res['message'] as Map<String, dynamic>);
        _agregarMensaje(msg);
      }
      return res;
    } catch (e) {
      if (kDebugMode) print('[ChatProvider] Error programando entrevista: $e');
      return null;
    }
  }

  /// Inicia una videollamada inmediata
  Future<Map<String, dynamic>?> iniciarVideollamada(String roomId, String titulo) async {
    try {
      final res = await _client.post(
        '/chat/$roomId/videollamada',
        {'titulo': titulo},
        auth: true,
      );

      if (res['message'] != null) {
        final msg = Message.fromJson(res['message'] as Map<String, dynamic>);
        _agregarMensaje(msg);
      }
      return res;
    } catch (e) {
      if (kDebugMode) print('[ChatProvider] Error iniciando videollamada: $e');
      return null;
    }
  }

  void _agregarMensaje(Message msg) {
    final list = _messagesByRoom.putIfAbsent(msg.roomId, () => []);
    // 1. Evitar duplicados por ID exacto
    final exists = list.any((m) => m.id == msg.id);
    if (exists) return;

    // 2. Si es un mensaje real del backend, reemplazar el optimista pendiente si existe
    if (!msg.id.startsWith('temp_')) {
      final tempIdx = list.indexWhere((m) =>
          m.id.startsWith('temp_') &&
          m.senderId == msg.senderId &&
          m.content == msg.content);
      if (tempIdx != -1) {
        list[tempIdx] = msg;
        notifyListeners();
        return;
      }
    }

    list.add(msg);
    notifyListeners();
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    // Nota: No limpiamos _messagesByRoom para evitar pérdida de mensajes en pantalla al volver
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
