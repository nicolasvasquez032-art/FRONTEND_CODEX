import 'package:flutter/foundation.dart';
import '../../../domain/entities/admin_metrics.dart';
import '../../../domain/entities/vacante.dart';
import '../../../domain/repositories/admin_repository.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _repository;

  AdminMetrics? _metrics;
  List<Vacante> _vacantes = [];
  bool _isLoading = false;
  String? _error;
  String _filterState = 'todas'; // 'todas', 'activa', 'pausada', 'cerrada'

  AdminProvider(this._repository);

  AdminMetrics? get metrics => _metrics;
  List<Vacante> get vacantes => _vacantes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterState => _filterState;

  List<Vacante> get filteredVacantes {
    if (_filterState == 'todas') return _vacantes;
    return _vacantes.where((v) => v.estado.name.toLowerCase() == _filterState.toLowerCase()).toList();
  }

  void setFilter(String filter) {
    _filterState = filter;
    notifyListeners();
  }

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getMetricas(),
        _repository.getTodasVacantes(),
      ]);

      _metrics = results[0] as AdminMetrics;
      _vacantes = results[1] as List<Vacante>;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> moderarVacante(String vacanteId, String nuevoEstado) async {
    try {
      final updated = await _repository.moderarVacante(vacanteId, nuevoEstado);
      final index = _vacantes.indexWhere((v) => v.id == vacanteId);
      if (index != -1) {
        _vacantes[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
