import 'package:flutter_test/flutter_test.dart';
import 'package:talentmatch/domain/entities/admin_metrics.dart';
import 'package:talentmatch/domain/entities/vacante.dart';
import 'package:talentmatch/domain/repositories/admin_repository.dart';
import 'package:talentmatch/presentation/shared/providers/admin_provider.dart';

class FakeAdminRepo implements AdminRepository {
  bool shouldFail = false;

  final AdminMetrics fakeMetrics = const AdminMetrics(
    totalCandidatos: 42,
    totalVacantesActivas: 15,
    totalPostulaciones: 120,
    tiempoPromedioDias: 12.5,
    efectividadPorcentaje: 91.2,
    sectoresDemanda: [
      SectorDemanda(categoria: 'Tecnología', totalVacantes: 10),
      SectorDemanda(categoria: 'Ventas', totalVacantes: 5),
    ],
  );

  final List<Vacante> fakeVacantes = [
    Vacante(
      id: 'v1',
      empresaId: 'e1',
      titulo: 'Desarrollador Flutter',
      descripcion: 'Exp en apps móviles',
      requisitos: ['Flutter', 'Dart'],
      ubicacion: 'Bogotá',
      estado: VacanteEstado.activa,
      categoria: 'Tecnología',
      creadoEn: DateTime(2026, 1, 1),
    ),
    Vacante(
      id: 'v2',
      empresaId: 'e2',
      titulo: 'Asesor Comercial',
      descripcion: 'Ventas corporativas',
      requisitos: ['Ventas'],
      ubicacion: 'Medellín',
      estado: VacanteEstado.pausada,
      categoria: 'Ventas',
      creadoEn: DateTime(2026, 1, 2),
    ),
    Vacante(
      id: 'v3',
      empresaId: 'e3',
      titulo: 'Contador Senior',
      descripcion: 'Auditorías',
      requisitos: ['NIIF'],
      ubicacion: 'Cali',
      estado: VacanteEstado.cerrada,
      categoria: 'Finanzas',
      creadoEn: DateTime(2026, 1, 3),
    ),
  ];

  @override
  Future<AdminMetrics> getMetricas() async {
    if (shouldFail) throw Exception('Error cargando métricas');
    return fakeMetrics;
  }

  @override
  Future<List<Vacante>> getTodasVacantes() async {
    if (shouldFail) throw Exception('Error cargando vacantes');
    return List.from(fakeVacantes);
  }

  @override
  Future<Vacante> moderarVacante(String vacanteId, String nuevoEstado) async {
    if (shouldFail) throw Exception('Error moderando vacante');
    final v = fakeVacantes.firstWhere((x) => x.id == vacanteId);
    VacanteEstado st;
    if (nuevoEstado == 'activa') {
      st = VacanteEstado.activa;
    } else if (nuevoEstado == 'pausada') {
      st = VacanteEstado.pausada;
    } else {
      st = VacanteEstado.cerrada;
    }

    return Vacante(
      id: v.id,
      empresaId: v.empresaId,
      titulo: v.titulo,
      descripcion: v.descripcion,
      requisitos: v.requisitos,
      ubicacion: v.ubicacion,
      estado: st,
      categoria: v.categoria,
      creadoEn: v.creadoEn,
    );
  }
}

void main() {
  group('AdminProvider Tests', () {
    late FakeAdminRepo fakeRepo;
    late AdminProvider provider;

    setUp(() {
      fakeRepo = FakeAdminRepo();
      provider = AdminProvider(fakeRepo);
    });

    test('loadDashboard carga métricas y vacantes exitosamente', () async {
      expect(provider.isLoading, isFalse);
      expect(provider.metrics, isNull);
      expect(provider.vacantes, isEmpty);

      await provider.loadDashboard();

      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.metrics?.totalCandidatos, 42);
      expect(provider.metrics?.totalVacantesActivas, 15);
      expect(provider.metrics?.efectividadPorcentaje, 91.2);
      expect(provider.vacantes.length, 3);
    });

    test('loadDashboard maneja errores de red y asigna estado de error', () async {
      fakeRepo.shouldFail = true;

      await provider.loadDashboard();

      expect(provider.isLoading, isFalse);
      expect(provider.metrics, isNull);
      expect(provider.error, contains('Error cargando'));
    });

    test('setFilter filtra vacantes por estado correctamente', () async {
      await provider.loadDashboard();

      expect(provider.filteredVacantes.length, 3);

      provider.setFilter('activa');
      expect(provider.filteredVacantes.length, 1);
      expect(provider.filteredVacantes.first.id, 'v1');

      provider.setFilter('pausada');
      expect(provider.filteredVacantes.length, 1);
      expect(provider.filteredVacantes.first.id, 'v2');

      provider.setFilter('cerrada');
      expect(provider.filteredVacantes.length, 1);
      expect(provider.filteredVacantes.first.id, 'v3');

      provider.setFilter('todas');
      expect(provider.filteredVacantes.length, 3);
    });

    test('moderarVacante actualiza el estado de la vacante en la lista', () async {
      await provider.loadDashboard();

      final ok = await provider.moderarVacante('v2', 'activa');
      expect(ok, isTrue);

      final updated = provider.vacantes.firstWhere((v) => v.id == 'v2');
      expect(updated.estado, VacanteEstado.activa);
    });

    test('moderarVacante maneja fallo de API retornando false', () async {
      await provider.loadDashboard();
      fakeRepo.shouldFail = true;

      final ok = await provider.moderarVacante('v1', 'cerrada');
      expect(ok, isFalse);
      expect(provider.error, contains('Error moderando vacante'));
    });
  });

  group('AdminMetrics Entity Tests', () {
    test('SectorDemanda fromJson parsea correctamente', () {
      final s = SectorDemanda.fromJson({'categoria': 'Salud', 'total_vacantes': 7});
      expect(s.categoria, 'Salud');
      expect(s.totalVacantes, 7);

      final fallback = SectorDemanda.fromJson({'sector': 'Finanzas', 'total': 3});
      expect(fallback.categoria, 'Finanzas');
      expect(fallback.totalVacantes, 3);
    });

    test('AdminMetrics copyWith genera copia inmutable modificada', () {
      const original = AdminMetrics(
        totalCandidatos: 10,
        totalVacantesActivas: 5,
        totalPostulaciones: 20,
      );

      final copy = original.copyWith(totalCandidatos: 15, tiempoPromedioDias: 8.5);
      expect(copy.totalCandidatos, 15);
      expect(copy.totalVacantesActivas, 5);
      expect(copy.tiempoPromedioDias, 8.5);
    });
  });
}
