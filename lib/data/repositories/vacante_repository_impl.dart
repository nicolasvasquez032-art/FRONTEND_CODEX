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
}
