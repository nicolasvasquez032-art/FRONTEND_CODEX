import '../../core/network/api_client.dart';
import '../../domain/entities/recomendacion.dart';
import '../../domain/repositories/recomendacion_repository.dart';
import '../models/recomendacion_model.dart';

class RecomendacionRepositoryImpl implements RecomendacionRepository {
  final ApiClient _api;

  RecomendacionRepositoryImpl(this._api);

  /// GET /recomendaciones/candidato/{candidatoId}
  /// Requiere JWT. Devuelve lista ordenada por score descendente.
  @override
  Future<List<Recomendacion>> getRecomendaciones(String candidatoId) async {
    final raw = await _api.getList(
      '/recomendaciones/candidato/$candidatoId',
      auth: true,
    );
    return raw
        .map((e) => RecomendacionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
