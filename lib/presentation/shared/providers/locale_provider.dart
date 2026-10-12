import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider ultra-rápido para la gestión reactiva del idioma de la aplicación.
/// Detecta automáticamente el idioma del dispositivo y persiste la elección del usuario.
class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'selected_language_code';

  late Locale _locale;
  SharedPreferences? _prefs;

  Locale get locale => _locale;
  bool get isSpanish => _locale.languageCode == 'es';
  String get languageName => isSpanish ? 'Español' : 'English';

  LocaleProvider() {
    _locale = _resolveInitialLocale();
    _loadSavedLocale();
  }

  /// Detecta de forma síncrona el idioma nativo del dispositivo (es / en)
  static Locale _resolveInitialLocale() {
    try {
      final systemCode = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
      if (systemCode.startsWith('en')) {
        return const Locale('en');
      }
    } catch (_) {
      // Si falla la lectura del dispatcher, por defecto español
    }
    return const Locale('es');
  }

  Future<void> _loadSavedLocale() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedCode = _prefs?.getString(_prefKey);
      if (savedCode != null && (savedCode == 'es' || savedCode == 'en')) {
        if (_locale.languageCode != savedCode) {
          _locale = Locale(savedCode);
          notifyListeners();
        }
      } else {
        // Primera vez en el dispositivo: usar idioma nativo del sistema
        final detected = _resolveInitialLocale();
        if (_locale != detected) {
          _locale = detected;
          notifyListeners();
        }
      }
    } catch (_) {
      // Si falla la lectura, se mantiene el locale inicial detectado
    }
  }

  void setLocale(Locale newLocale) {
    if (_locale == newLocale) return;
    if (newLocale.languageCode != 'es' && newLocale.languageCode != 'en') return;

    _locale = newLocale;
    notifyListeners();

    // Persistencia asíncrona en segundo plano sin pausar la UI
    _persistLocale(newLocale.languageCode);
  }

  void _persistLocale(String code) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setString(_prefKey, code);
    } catch (_) {}
  }

  void toggleLocale() {
    final next = isSpanish ? const Locale('en') : const Locale('es');
    setLocale(next);
  }

  /// Restablece el idioma al predeterminado del sistema operativo
  void resetToSystemLocale() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.remove(_prefKey);
      final systemLocale = _resolveInitialLocale();
      if (_locale != systemLocale) {
        _locale = systemLocale;
        notifyListeners();
      }
    } catch (_) {}
  }
}
