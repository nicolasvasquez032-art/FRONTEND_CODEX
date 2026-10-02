import 'package:flutter/foundation.dart';
import '../../../domain/entities/notificacion.dart';
import '../../../domain/repositories/notificacion_repository.dart';

enum NotificacionesStatus { initial, loading, loaded, error }

class NotificacionesProvider extends ChangeNotifier {
  final NotificacionRepository _repository;

  NotificacionesStatus _status = NotificacionesStatus.initial;
  NotificacionesStatus get status => _status;

  String? _error;
  String? get error => _error;

  List<Notificacion> _notificaciones = [];
  List<Notificacion> get notificaciones => _notificaciones;

  int get noLeidasCount => _notificaciones.where((n) => !n.leido).length;

  NotificacionesProvider(this._repository);

  Future<void> cargar(String usuarioId) async {
    _status = NotificacionesStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _notificaciones = await _repository.getNotificaciones(usuarioId);
      _status = NotificacionesStatus.loaded;
    } catch (e) {
      _status = NotificacionesStatus.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> marcarLeida(String id) async {
    final index = _notificaciones.indexWhere((n) => n.id == id);
    if (index == -1 || _notificaciones[index].leido) return;

    // Optimistic update
    final n = _notificaciones[index];
    _notificaciones[index] = n.copyWith(leido: true);
    notifyListeners();

    try {
      await _repository.marcarLeida(id);
    } catch (e) {
      // Revert if error
      _notificaciones[index] = n;
      notifyListeners();
    }
  }
}
