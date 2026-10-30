import 'package:flutter_test/flutter_test.dart';
import 'package:talentmatch/data/models/vacante_model.dart';
import 'package:talentmatch/data/models/postulacion_model.dart';
import 'package:talentmatch/data/models/notificacion_model.dart';
import 'package:talentmatch/data/models/profile_model.dart';
import 'package:talentmatch/data/models/recomendacion_model.dart';
import 'package:talentmatch/domain/entities/vacante.dart';
import 'package:talentmatch/domain/entities/postulacion.dart';

void main() {
  group('Modelos y Serialización JSON', () {
    test('VacanteModel.fromJson mapea campos completos y convierte a entidad', () {
      final json = {
        'id': 'v-100',
        'empresa_id': 'emp-200',
        'titulo': 'Senior Flutter Dev',
        'descripcion': 'Desarrollo de apps móviles de alto impacto',
        'requisitos': ['Flutter', 'Dart', 'Bloc', 'CI/CD'],
        'ubicacion': 'Bogotá, Colombia',
        'estado': 'activa',
        'categoria': 'Tecnología',
        'salario_min': 5000000,
        'salario_max': 8000000,
        'latitud': 4.711,
        'longitud': -74.0721,
        'creado_en': '2026-10-30T10:00:00.000Z',
      };

      final model = VacanteModel.fromJson(json);
      expect(model.id, 'v-100');
      expect(model.empresaId, 'emp-200');
      expect(model.titulo, 'Senior Flutter Dev');
      expect(model.requisitos.length, 4);
      expect(model.salarioMin, 5000000.0);
      expect(model.salarioMax, 8000000.0);
      expect(model.latitud, 4.711);
      expect(model.longitud, -74.0721);

      final entity = model.toEntity();
      expect(entity.id, 'v-100');
      expect(entity.estado, VacanteEstado.activa);
      expect(entity.creadoEn.year, 2026);
    });

    test('VacanteModel maneja estados alternativos y campos nulos', () {
      final jsonPausada = {
        'id': 'v-101',
        'empresa_id': 'emp-200',
        'titulo': 'Junior QA',
        'descripcion': 'Testing',
        'requisitos': <String>[],
        'ubicacion': 'Remoto',
        'estado': 'pausada',
        'creado_en': '2026-10-30T10:00:00.000Z',
      };
      final modelPausada = VacanteModel.fromJson(jsonPausada);
      expect(modelPausada.toEntity().estado, VacanteEstado.pausada);
      expect(modelPausada.categoria, isNull);
      expect(modelPausada.salarioMin, isNull);

      final jsonCerrada = {
        'id': 'v-102',
        'empresa_id': 'emp-200',
        'titulo': 'DevOps',
        'descripcion': 'AWS',
        'requisitos': <String>['Docker'],
        'ubicacion': 'Medellín',
        'estado': 'cerrada',
        'creado_en': '2026-10-30T10:00:00.000Z',
      };
      final modelCerrada = VacanteModel.fromJson(jsonCerrada);
      expect(modelCerrada.toEntity().estado, VacanteEstado.cerrada);
    });

    test('PostulacionModel.fromJson mapea estados y scoreMatch', () {
      final json = {
        'id': 'p-300',
        'candidato_id': 'cand-1',
        'vacante_id': 'v-100',
        'estado': 'entrevista',
        'fecha': '2026-10-30T12:00:00.000Z',
        'score_match': 0.88,
      };

      final model = PostulacionModel.fromJson(json);
      expect(model.id, 'p-300');
      expect(model.candidatoId, 'cand-1');
      expect(model.vacanteId, 'v-100');
      expect(model.scoreMatch, 0.88);

      final entity = model.toEntity();
      expect(entity.estado, PostulacionEstado.entrevista);
      expect(entity.fecha.year, 2026);

      // Estados adicionales
      expect(PostulacionModel.fromJson({...json, 'estado': 'rechazado'}).toEntity().estado, PostulacionEstado.rechazado);
      expect(PostulacionModel.fromJson({...json, 'estado': 'contratado'}).toEntity().estado, PostulacionEstado.contratado);
      expect(PostulacionModel.fromJson({...json, 'estado': 'postulado'}).toEntity().estado, PostulacionEstado.postulado);
      expect(PostulacionModel.fromJson({...json, 'estado': 'desconocido'}).toEntity().estado, PostulacionEstado.postulado);
    });

    test('NotificacionModel.fromJson maneja valores por defecto y nulos', () {
      final jsonNulls = {
        'id': 'notif-1',
      };
      final model = NotificacionModel.fromJson(jsonNulls);
      expect(model.id, 'notif-1');
      expect(model.tipo, 'general');
      expect(model.mensaje, '');
      expect(model.leido, isFalse);

      final entity = model.toEntity();
      expect(entity.id, 'notif-1');
      expect(entity.tipo, 'general');

      final jsonFull = {
        'id': 'notif-2',
        'tipo': 'postulacion',
        'mensaje': 'Tu postulación fue vista',
        'leido': true,
        'creado_en': '2026-10-30T09:00:00.000Z',
      };
      final modelFull = NotificacionModel.fromJson(jsonFull);
      expect(modelFull.leido, isTrue);
      expect(modelFull.mensaje, 'Tu postulación fue vista');
      expect(modelFull.creadoEn.year, 2026);
    });

    test('ProfileModel.fromJson y toUpdateJson funcionan correctamente', () {
      final json = {
        'id': 'prof-1',
        'user_id': 'u-1',
        'full_name': 'Camila Restrepo',
        'skills': ['Dart', 'FastAPI'],
        'experience_years': 4,
        'location': 'Bogotá',
        'education': 'Ingeniería de Sistemas',
        'cv_text': 'Resumen CV',
        'phone': '+573001234567',
        'portfolio_url': 'https://camila.dev',
        'about_me': 'Entusiasta del código limpio',
        'job_title': 'Lead Mobile Architect',
      };

      final profile = ProfileModel.fromJson(json);
      expect(profile.id, 'prof-1');
      expect(profile.fullName, 'Camila Restrepo');
      expect(profile.skills.length, 2);
      expect(profile.experienceYears, 4);
      expect(profile.jobTitle, 'Lead Mobile Architect');

      final updateMap = profile.toUpdateJson();
      expect(updateMap['full_name'], 'Camila Restrepo');
      expect(updateMap['phone'], '+573001234567');
      expect(updateMap['job_title'], 'Lead Mobile Architect');
    });

    test('RecomendacionModel.fromJson mapea coincidencia de IA', () {
      final json = {
        'vacante_id': 'v-999',
        'titulo': 'Python Machine Learning Engineer',
        'empresa_id': 'emp-888',
        'score_similitud': 0.95,
        'explicacion': '95% de compatibilidad con tus habilidades en Python y PyTorch',
      };

      final rec = RecomendacionModel.fromJson(json);
      expect(rec.vacanteId, 'v-999');
      expect(rec.titulo, 'Python Machine Learning Engineer');
      expect(rec.scoreSimilitud, 0.95);
      expect(rec.explicacion, contains('95% de compatibilidad'));
    });
  });
}
