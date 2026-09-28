import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../domain/entities/vacante.dart';
import '../../../domain/repositories/vacante_repository.dart';

enum VacantesStatus { initial, loading, loaded, error }

class VacantesProvider extends ChangeNotifier {
  final VacanteRepository _repo;

  VacantesProvider(this._repo);

  VacantesStatus status = VacantesStatus.initial;
  List<Vacante> vacantes = [];
  String? error;

  // Filtros activos
  String? _ubicacion;
  String? _categoria;
  String _query = '';

  List<Vacante> get filtered {
    if (_query.isEmpty) return vacantes;
    final q = _query.toLowerCase();
    return vacantes.where((v) {
      return v.titulo.toLowerCase().contains(q) ||
          v.ubicacion.toLowerCase().contains(q) ||
          (v.categoria?.toLowerCase().contains(q) ?? false) ||
          v.descripcion.toLowerCase().contains(q);
    }).toList();
  }

  // ─────────────────────────────────────────────
  // Cargar vacantes
  // ─────────────────────────────────────────────

  Future<void> cargar({String? ubicacion, String? categoria}) async {
    _ubicacion = ubicacion;
    _categoria = categoria;
    status = VacantesStatus.loading;
    error = null;
    notifyListeners();

    try {
      vacantes = await _repo.listarVacantes(
        ubicacion: _ubicacion,
        categoria: _categoria,
      );
      status = VacantesStatus.loaded;
    } on ApiException catch (e) {
      error = e.message;
      status = VacantesStatus.error;
    } catch (_) {
      error = 'Sin conexión. Verifica tu red.';
      status = VacantesStatus.error;
    }
    notifyListeners();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void clearQuery() {
    _query = '';
    notifyListeners();
  }
}
