import 'package:flutter_test/flutter_test.dart';
import 'package:talentmatch/core/network/api_client.dart';
import 'package:talentmatch/core/storage/secure_storage.dart';
import 'package:talentmatch/presentation/shared/providers/chat_provider.dart';

class MockApiClient extends ApiClient {
  MockApiClient() : super(SecureStorage());

  List<dynamic> mockRoomsResponse = [
    {
      'id': 'room-1',
      'other_user_id': 'user-cand-1',
      'other_user_name': 'Nicolas Vasquez',
      'other_user_role': 'Candidato',
      'last_message': 'Hola',
      'last_message_time': '2026-11-15T20:00:00Z',
      'unread_count': 1,
    }
  ];

  List<dynamic> mockMessagesResponse = [
    {
      'id': 'msg-1',
      'room_id': 'room-1',
      'sender_id': 'user-emp-1',
      'content': 'Hola, te invitamos a una entrevista',
      'creado_en': '2026-11-15T20:01:00Z',
      'leido': true,
    }
  ];

  @override
  Future<List<dynamic>> getList(
    String path, {
    bool auth = true,
    Map<String, String>? queryParams,
  }) async {
    if (path.contains('/chat/rooms')) {
      return mockRoomsResponse;
    }
    if (path.contains('/messages')) {
      return mockMessagesResponse;
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    if (path.contains('/programar-entrevista')) {
      return {
        'meeting_url': 'https://meet.jit.si/TalentMatch-Entrevista-123',
        'titulo': body['titulo'],
        'fecha_hora': body['fecha_hora'],
        'message': {
          'id': 'msg-interview-1',
          'room_id': 'room-1',
          'sender_id': 'user-emp-1',
          'content': '[INTERVIEW_SCHEDULED]:https://meet.jit.si/TalentMatch-Entrevista-123|${body['titulo']}|${body['fecha_hora']}|${body['notas'] ?? ''}',
          'creado_en': '2026-11-15T20:05:00Z',
          'leido': false,
        }
      };
    }
    if (path.contains('/messages')) {
      return {
        'id': 'msg-new-1',
        'room_id': 'room-1',
        'sender_id': 'user-emp-1',
        'content': body['content'],
        'creado_en': '2026-11-15T20:02:00Z',
        'leido': false,
      };
    }
    return {};
  }
}

void main() {
  group('ChatProvider & Real-time / REST Persistence Tests', () {
    late MockApiClient mockClient;
    late ChatProvider chatProvider;

    setUp(() {
      mockClient = MockApiClient();
      chatProvider = ChatProvider(client: mockClient);
    });

    test('loadRooms recupera las conversaciones activas del usuario con nombres y roles', () async {
      await chatProvider.loadRooms();

      expect(chatProvider.rooms.length, 1);
      final room = chatProvider.rooms.first;
      expect(room.id, 'room-1');
      expect(room.otherUserName, 'Nicolas Vasquez');
      expect(room.otherUserRole, 'Candidato');
      expect(room.lastMessage, 'Hola');
      expect(room.unreadCount, 1);
    });

    test('loadMessages carga el historial de mensajes de la base de datos', () async {
      await chatProvider.loadMessages('room-1');

      final msgs = chatProvider.getMessagesForRoom('room-1');
      expect(msgs.length, 1);
      expect(msgs.first.id, 'msg-1');
      expect(msgs.first.content, 'Hola, te invitamos a una entrevista');
      expect(msgs.first.leido, isTrue);
    });

    test('sendMessage agrega optimísticamente y persiste por REST', () async {
      await chatProvider.loadMessages('room-1');
      await chatProvider.sendMessage('room-1', 'user-emp-1', '¿Cómo estás?');

      final msgs = chatProvider.getMessagesForRoom('room-1');
      expect(msgs.length, 2);
      expect(msgs.last.content, '¿Cómo estás?');
      expect(msgs.last.id, 'msg-new-1');
    });

    test('programarEntrevista genera mensaje interactivo con fecha, hora y enlace', () async {
      await chatProvider.loadMessages('room-1');
      final res = await chatProvider.programarEntrevista(
        'room-1',
        'Entrevista Técnica Flutter',
        'Lunes 18 de Noviembre - 10:00 AM',
        notas: 'Tener a mano portafolio',
      );

      expect(res, isNotNull);
      expect(res!['meeting_url'], contains('meet.jit.si'));
      final msgs = chatProvider.getMessagesForRoom('room-1');
      expect(msgs.any((m) => m.content.startsWith('[INTERVIEW_SCHEDULED]:')), isTrue);
    });
  });
}
