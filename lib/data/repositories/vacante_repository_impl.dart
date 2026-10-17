import '../../core/network/api_client.dart';
import '../../domain/entities/vacante.dart';
import '../../domain/repositories/vacante_repository.dart';
import '../models/vacante_model.dart';

class VacanteRepositoryImpl implements VacanteRepository {
  final ApiClient _api;

  VacanteRepositoryImpl(this._api);

  @override
  Future<List<Vacante>> listarVacantes({
    String? ubicacion,
    String? categoria,
  }) async {
    final params = <String, String>{};
    if (ubicacion != null && ubicacion.isNotEmpty) params['ubicacion'] = ubicacion;
    if (categoria != null && categoria.isNotEmpty) params['categoria'] = categoria;

    final raw = await _api.getList(
      '/vacantes',
      auth: true,
      queryParams: params.isNotEmpty ? params : null,
    );

    return raw
        .map((e) => VacanteModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  @override
  Future<Vacante> getVacante(String id) async {
    final raw = await _api.get('/vacantes/$id', auth: true);
    return VacanteModel.fromJson(raw).toEntity();
  }

  @override
  Future<Vacante> publicarVacante({
    required String titulo,
    required String descripcion,
    required List<String> requisitos,
    required String ubicacion,
    required String categoria,
    double? salarioMin,
    double? salarioMax,
    double? latitud,
    double? longitud,
  }) async {
    final response = await _api.post(
      '/vacantes',
      {
        'titulo': titulo,
        'descripcion': descripcion,
        'requisitos': requisitos,
        'ubicacion': ubicacion,
        'categoria': categoria,
        'salario_min': ?salarioMin,
        'salario_max': ?salarioMax,
        'latitud': ?latitud,
        'longitud': ?longitud,
      },
      auth: true,
    );
    return VacanteModel.fromJson(response).toEntity();
  }

  @override
  Future<void> eliminarVacante(String id) async {
    await _api.delete('/vacantes/$id', auth: true);
  }
}
