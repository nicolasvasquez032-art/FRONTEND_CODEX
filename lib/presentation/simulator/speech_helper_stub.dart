import 'package:flutter/foundation.dart';

class SpeechService {
  bool get isSupported => false;
  bool isListening = false;

  void start({
    required Function(String text, bool isFinal) onResult,
    required VoidCallback onEnd,
    Function(String error)? onError,
    VoidCallback? onStart,
  }) {
    onError?.call('El dictado de voz nativo no está disponible en este entorno.');
    onEnd();
  }

  void stop() {
    isListening = false;
  }
}
