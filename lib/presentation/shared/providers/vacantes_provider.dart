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
  bool loadingPub = false;

  // Filtros activos
  String? _ubicacion;
  String? _categoria;
  String _query = '';

  // Filtros locales interactivos
  String? _filtroCategoria;
  double? _filtroSalarioMin;

  String? get filtroCategoria => _filtroCategoria;
  double? get filtroSalarioMin => _filtroSalarioMin;

  List<Vacante> get filtered {
    var lista = vacantes;

    if (_filtroCategoria != null) {
      lista = lista.where((v) => v.categoria?.toLowerCase() == _filtroCategoria!.toLowerCase()).toList();
    }

    if (_filtroSalarioMin != null) {
      lista = lista.where((v) => (v.salarioMin ?? 0) >= _filtroSalarioMin!).toList();
    }

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      lista = lista.where((v) {
        return v.titulo.toLowerCase().contains(q) ||
            v.ubicacion.toLowerCase().contains(q) ||
            (v.categoria?.toLowerCase().contains(q) ?? false) ||
            v.descripcion.toLowerCase().contains(q);
      }).toList();
    }
    return lista;
  }

  void setCategoriaFiltro(String? cat) {
    if (_filtroCategoria == cat) {
      _filtroCategoria = null;
    } else {
      _filtroCategoria = cat;
    }
    notifyListeners();
  }

  void setSalarioFiltro(double? min) {
    if (_filtroSalarioMin == min) {
      _filtroSalarioMin = null;
    } else {
      _filtroSalarioMin = min;
    }
    notifyListeners();
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

  Future<bool> publicarVacante({
    required String titulo,
    required String descripcion,
    required List<String> requisitos,
    required String ubicacion,
    required String categoria,
    double? salarioMin,
    double? salarioMax,
  }) async {
    loadingPub = true;
    error = null;
    notifyListeners();

    try {
      final nuevaVacante = await _repo.publicarVacante(
        titulo: titulo,
        descripcion: descripcion,
        requisitos: requisitos,
        ubicacion: ubicacion,
        categoria: categoria,
        salarioMin: salarioMin,
        salarioMax: salarioMax,
      );
      vacantes.insert(0, nuevaVacante);
      loadingPub = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      loadingPub = false;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Sin conexión. Verifica tu red.';
      loadingPub = false;
      notifyListeners();
      return false;
    }
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
