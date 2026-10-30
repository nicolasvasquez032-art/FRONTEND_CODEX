import 'package:flutter_test/flutter_test.dart';
import 'package:talentmatch/domain/entities/profile.dart';
import 'package:talentmatch/domain/entities/vacante.dart';
import 'package:talentmatch/domain/entities/postulacion.dart';
import 'package:talentmatch/domain/entities/recomendacion.dart';
import 'package:talentmatch/domain/entities/user_session.dart';

void main() {
  group('Domain Entities Tests', () {
    test('Profile initial y copyWith', () {
      const profile = Profile(
        id: 'p-1',
        userId: 'u-1',
        fullName: 'Nicolas Vasquez',
        skills: ['Flutter', 'Python'],
        experienceYears: 4,
      );

      expect(profile.initial, 'N');

      const emptyNameProfile = Profile(
        id: 'p-2',
        userId: 'u-2',
        fullName: '',
        skills: [],
        experienceYears: 0,
      );
      expect(emptyNameProfile.initial, '?');

      final updated = profile.copyWith(
        fullName: 'Carlos Gomez',
        skills: ['Dart'],
        experienceYears: 5,
        location: 'Bogotá',
        education: 'Ingeniería',
        cvText: 'cv.pdf',
        phone: '1234567890',
        portfolioUrl: 'https://carlos.dev',
        aboutMe: 'Sobre mí',
        jobTitle: 'Senior Dev',
      );

      expect(updated.fullName, 'Carlos Gomez');
      expect(updated.skills, ['Dart']);
      expect(updated.experienceYears, 5);
      expect(updated.location, 'Bogotá');
      expect(updated.education, 'Ingeniería');
      expect(updated.cvText, 'cv.pdf');
      expect(updated.phone, '1234567890');
      expect(updated.portfolioUrl, 'https://carlos.dev');
      expect(updated.aboutMe, 'Sobre mí');
      expect(updated.jobTitle, 'Senior Dev');
      expect(updated.id, 'p-1');
      expect(updated.userId, 'u-1');
    });

    test('Vacante métodos de visualización y localización', () {
      final vacante = Vacante(
        id: 'v-1',
        empresaId: 'e-1',
        titulo: 'Desarrollador Backend',
        descripcion: 'Buscamos desarrollador para unirse a nuestro equipo',
        requisitos: ['Trabajo en equipo', 'Experiencia de 3 años'],
        ubicacion: 'Bogotá, Colombia',
        estado: VacanteEstado.activa,
        creadoEn: DateTime.now().subtract(const Duration(days: 2)),
        categoria: 'Tecnología',
        salarioMin: 4000000,
        salarioMax: 6000000,
      );

      expect(vacante.salarioDisplay, contains('4.000.000'));
      expect(vacante.salarioDisplayLocalized(false), contains('4,000,000'));
      expect(vacante.tiempoRelativo, isNotEmpty);
      expect(vacante.tiempoRelativoLocalized(false), isNotEmpty);
      expect(vacante.fechaPublicacionLocalized(true, full: true), isNotEmpty);
      expect(vacante.fechaPublicacionLocalized(false, full: false), isNotEmpty);

      // Localización de contenido dinámico
      expect(vacante.tituloLocalized(true), 'Desarrollador Backend');
      expect(vacante.tituloLocalized(false), 'Backend Developer');
      expect(vacante.categoriaLocalized(false), 'Technology');
      expect(vacante.descripcionLocalized(true), vacante.descripcion);
      expect(vacante.descripcionLocalized(false), contains('We are looking for'));
      expect(vacante.requisitosLocalized(false).first, 'Teamwork');
      expect(vacante.ubicacionLocalized(false), 'Bogota, Colombia');
    });

    test('Recomendacion score y badges', () {
      const rec = Recomendacion(
        vacanteId: 'v-100',
        titulo: 'Desarrollador Frontend',
        empresaId: 'emp-10',
        scoreSimilitud: 0.88,
        explicacion: 'Habilidades coincidentes: React, Flutter',
      );

      expect(rec.scorePercent, 88);
      expect(rec.badgeText, '✦ 88% compatible contigo');
      expect(rec.badgeTextLocalized(false), '✦ 88% match for you');
      expect(rec.tituloLocalized(false), 'Frontend Developer');
      expect(rec.explicacionLocalized(false), 'Matching skills: React, Flutter');
    });

    test('PostulacionEstadoX labels', () {
      expect(PostulacionEstado.postulado.label, 'Postulado');
      expect(PostulacionEstado.entrevista.label, 'En entrevista');
      expect(PostulacionEstado.rechazado.label, 'Rechazado');
      expect(PostulacionEstado.contratado.label, 'Contratado');
    });

    test('UserSession roles helper', () {
      const candidateSession = UserSession(
        userId: 'u-c',
        profileId: 'p-c',
        role: 'candidate',
      );
      expect(candidateSession.isCandidate, isTrue);
      expect(candidateSession.isCompany, isFalse);
      expect(candidateSession.isAdmin, isFalse);

      const companySession = UserSession(
        userId: 'u-e',
        profileId: 'p-e',
        role: 'company',
      );
      expect(companySession.isCandidate, isFalse);
      expect(companySession.isCompany, isTrue);
      expect(companySession.isAdmin, isFalse);

      const adminSession = UserSession(
        userId: 'u-a',
        profileId: 'p-a',
        role: 'admin',
      );
      expect(adminSession.isCandidate, isFalse);
      expect(adminSession.isCompany, isFalse);
      expect(adminSession.isAdmin, isTrue);
    });
  });
}
