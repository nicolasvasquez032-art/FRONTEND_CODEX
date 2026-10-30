import 'package:flutter_test/flutter_test.dart';
import 'package:talentmatch/core/network/api_client.dart';
import 'package:talentmatch/data/repositories/notificacion_repository_impl.dart';
import 'package:talentmatch/data/repositories/perfil_repository_impl.dart';
import 'package:talentmatch/data/repositories/postulacion_repository_impl.dart';
import 'package:talentmatch/data/repositories/recomendacion_repository_impl.dart';
import 'package:talentmatch/data/repositories/vacante_repository_impl.dart';
import 'package:talentmatch/domain/entities/postulacion.dart';
import 'package:talentmatch/domain/entities/vacante.dart';

class FakeApiClient implements ApiClient {
  Map<String, dynamic> lastPostData = {};
  Map<String, dynamic> lastPutData = {};
  Map<String, dynamic>? lastQueryParams;
  String lastPath = '';

  @override
  Future<Map<String, dynamic>> get(String path, {bool auth = true, Map<String, String>? queryParams}) async {
    lastPath = path;
    lastQueryParams = queryParams;

    if (path.startsWith('/perfiles/')) {
      return {
        'id': 'prof-123',
        'user_id': 'usr-123',
        'full_name': 'Dev Tester',
        'skills': ['Flutter', 'Dart'],
        'experience_years': 3,
        'location': 'Bogotá',
      };
    }
    if (path.startsWith('/vacantes/')) {
      return {
        'id': 'vac-1',
        'empresa_id': 'emp-1',
        'titulo': 'Ingeniero Flutter',
        'descripcion': 'Buscamos desarrollador',
        'requisitos': ['Flutter'],
        'ubicacion': 'Bogotá',
        'estado': 'activa',
        'creado_en': DateTime.now().toIso8601String(),
      };
    }
    return {};
  }

  @override
  Future<List<dynamic>> getList(String path, {bool auth = true, Map<String, String>? queryParams}) async {
    lastPath = path;
    lastQueryParams = queryParams;

    if (path.startsWith('/recomendaciones/candidato/')) {
      return [
        {
          'vacante_id': 'v-rec-1',
          'titulo': 'Dev Python',
          'empresa_id': 'emp-1',
          'score_similitud': 0.95,
          'explicacion': 'Match de skills',
        }
      ];
    }
    if (path.startsWith('/notificaciones/usuario/')) {
      return [
        {
          'id': 'notif-1',
          'usuario_id': 'usr-1',
          'titulo': 'Nueva oferta',
          'mensaje': 'Tienes una vacante',
          'tipo': 'nueva_vacante',
          'leida': false,
          'fecha': DateTime.now().toIso8601String(),
        }
      ];
    }
    if (path.startsWith('/postulaciones/candidato/')) {
      return [
        {
          'id': 'post-1',
          'candidato_id': 'usr-1',
          'vacante_id': 'v-1',
          'estado': 'postulado',
          'fecha': DateTime.now().toIso8601String(),
        }
      ];
    }
    if (path.startsWith('/vacantes')) {
      return [
        {
          'id': 'v-1',
          'empresa_id': 'e-1',
          'titulo': 'Dev Flutter',
          'descripcion': 'Vacante activa',
          'requisitos': ['Dart'],
          'ubicacion': 'Remoto',
          'estado': 'activa',
          'creado_en': DateTime.now().toIso8601String(),
        }
      ];
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    lastPath = path;
    lastPostData = body;

    if (path == '/postulaciones') {
      return {
        'id': 'new-post-1',
        'candidato_id': 'c-1',
        'vacante_id': body['vacante_id'],
        'estado': 'postulado',
        'fecha': DateTime.now().toIso8601String(),
      };
    }
    if (path == '/vacantes') {
      return {
        'id': 'new-vac-1',
        'empresa_id': 'e-1',
        'titulo': body['titulo'],
        'descripcion': body['descripcion'],
        'requisitos': body['requisitos'],
        'ubicacion': body['ubicacion'],
        'estado': 'activa',
        'creado_en': DateTime.now().toIso8601String(),
      };
    }
    if (path == '/notificaciones/token-dispositivo') {
      return {'status': 'ok'};
    }
    return body;
  }

  @override
  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    lastPath = path;
    lastPutData = body;

    return {
      'id': 'prof-123',
      'user_id': 'usr-123',
      'full_name': body['full_name'] ?? 'Dev',
      'skills': body['skills'] ?? [],
      'experience_years': body['experience_years'] ?? 0,
      'location': body['location'],
      'education': body['education'],
      'phone': body['phone'],
      'portfolio_url': body['portfolio_url'],
      'about_me': body['about_me'],
      'job_title': body['job_title'],
    };
  }

  @override
  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    lastPath = path;
    return body;
  }

  @override
  Future<void> delete(String path, {bool auth = true}) async {
    lastPath = path;
  }

  @override
  Future<Map<String, dynamic>> postMultipart(String path, List<int> fileBytes, String fileName, String mimeType) async {
    lastPath = path;
    return {
      'profile_id': 'prof-123',
      'message': 'CV subido',
      'cv_preview': 'Texto extraído del CV',
    };
  }
}

void main() {
  late FakeApiClient api;

  setUp(() {
    api = FakeApiClient();
  });

  group('RecomendacionRepositoryImpl', () {
    test('getRecomendaciones retorna lista mapeada correctamente', () async {
      final repo = RecomendacionRepositoryImpl(api);
      final recs = await repo.getRecomendaciones('cand-1');

      expect(recs.length, 1);
      expect(recs.first.vacanteId, 'v-rec-1');
      expect(recs.first.scorePercent, 95);
      expect(api.lastPath, '/recomendaciones/candidato/cand-1');
    });
  });

  group('NotificacionRepositoryImpl', () {
    test('getNotificaciones pasa limit y offset y mapea entidades', () async {
      final repo = NotificacionRepositoryImpl(api);
      final notifs = await repo.getNotificaciones('usr-1', limit: 20, offset: 5);

      expect(notifs.length, 1);
      expect(notifs.first.id, 'notif-1');
      expect(api.lastQueryParams?['limit'], '20');
      expect(api.lastQueryParams?['offset'], '5');
    });

    test('marcarLeida y registrarToken invocan endpoints correctos', () async {
      final repo = NotificacionRepositoryImpl(api);
      await repo.marcarLeida('notif-99');
      expect(api.lastPath, '/notificaciones/notif-99/leida');

      await repo.registrarToken('fcm-token-123', dispositivoInfo: 'Pixel 8');
      expect(api.lastPath, '/notificaciones/token-dispositivo');
      expect(api.lastPostData['token'], 'fcm-token-123');
      expect(api.lastPostData['dispositivo_info'], 'Pixel 8');
    });
  });

  group('PostulacionRepositoryImpl', () {
    test('postularse, listar y cancelar postulaciones', () async {
      final repo = PostulacionRepositoryImpl(api);

      final nueva = await repo.postularse(candidatoId: 'c-1', vacanteId: 'v-99');
      expect(nueva.vacanteId, 'v-99');
      expect(nueva.estado, PostulacionEstado.postulado);

      final list = await repo.listarMisPostulaciones('c-1');
      expect(list.length, 1);
      expect(list.first.id, 'post-1');

      await repo.cancelarPostulacion('post-1');
      expect(api.lastPath, '/postulaciones/post-1');
    });
  });

  group('VacanteRepositoryImpl', () {
    test('listarVacantes con filtros de ubicación y categoría', () async {
      final repo = VacanteRepositoryImpl(api);

      final list = await repo.listarVacantes(ubicacion: 'Bogotá', categoria: 'Tecnología');
      expect(list.length, 1);
      expect(api.lastQueryParams?['ubicacion'], 'Bogotá');
      expect(api.lastQueryParams?['categoria'], 'Tecnología');

      final vac = await repo.getVacante('vac-1');
      expect(vac.id, 'vac-1');
      expect(vac.estado, VacanteEstado.activa);

      final nueva = await repo.publicarVacante(
        titulo: 'Dev Dart',
        descripcion: 'Senior Developer',
        requisitos: ['Dart'],
        ubicacion: 'Remoto',
        categoria: 'Tecnología',
        salarioMin: 5000000,
        salarioMax: 8000000,
      );
      expect(nueva.id, 'new-vac-1');
      expect(api.lastPostData['titulo'], 'Dev Dart');

      await repo.eliminarVacante('new-vac-1');
      expect(api.lastPath, '/vacantes/new-vac-1');
    });
  });

  group('PerfilRepositoryImpl', () {
    test('getPerfil, updatePerfil y uploadCv', () async {
      final repo = PerfilRepositoryImpl(api);

      final perfil = await repo.getPerfil('prof-123');
      expect(perfil.fullName, 'Dev Tester');
      expect(perfil.skills, contains('Flutter'));

      final actualizado = await repo.updatePerfil(
        profileId: 'prof-123',
        fullName: 'Dev Updated',
        skills: ['Flutter', 'AWS'],
        experienceYears: 4,
        location: 'Medellín',
        phone: '3001234567',
      );
      expect(actualizado.fullName, 'Dev Updated');
      expect(api.lastPutData['location'], 'Medellín');
      expect(api.lastPutData['phone'], '3001234567');

      final cvText = await repo.uploadCv(
        profileId: 'prof-123',
        fileBytes: [1, 2, 3],
        fileName: 'cv.pdf',
        mimeType: 'application/pdf',
      );
      expect(cvText, 'Texto extraído del CV');
      expect(api.lastPath, '/perfiles/prof-123/cv');
    });
  });
}
