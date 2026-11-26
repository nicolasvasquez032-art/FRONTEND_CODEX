// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

class SpeechService {
  bool _isListening = false;
  final List<StreamSubscription> _subs = [];

  bool get isSupported {
    try {
      _ensureJsInjected();
      return html.window.navigator.userAgent.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool get isListening => _isListening;

  static bool _jsInjected = false;

  static void _ensureJsInjected() {
    if (_jsInjected) return;
    try {
      final script = html.ScriptElement()
        ..type = 'text/javascript'
        ..text = '''
(function() {
  window.tmSpeech = {
    recognition: null,
    start: function() {
      var SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
      if (!SpeechRec) {
        window.dispatchEvent(new CustomEvent('tm_speech_error', { detail: 'Tu navegador no soporta reconocimiento de voz. Usa Google Chrome.' }));
        window.dispatchEvent(new CustomEvent('tm_speech_end'));
        return;
      }

      var run = function() {
        try {
          if (window.tmSpeech.recognition) {
            try { window.tmSpeech.recognition.abort(); } catch(e) {}
          }
          var rec = new SpeechRec();
          window.tmSpeech.recognition = rec;
          rec.continuous = true;
          rec.interimResults = true;
          rec.lang = 'es-CO';

          rec.onstart = function() {
            window.dispatchEvent(new CustomEvent('tm_speech_start'));
          };

          rec.onresult = function(event) {
            try {
              var transcript = '';
              var isFinal = false;
              for (var i = 0; i < event.results.length; ++i) {
                var item = event.results[i];
                if (item && item[0]) {
                  transcript += item[0].transcript + ' ';
                  if (item.isFinal) isFinal = true;
                }
              }
              var clean = transcript.trim();
              if (clean.length > 0) {
                window.dispatchEvent(new CustomEvent('tm_speech_result', {
                  detail: JSON.stringify({ text: clean, isFinal: isFinal })
                }));
              }
            } catch(e) {
              console.error('onresult error:', e);
            }
          };

          rec.onerror = function(event) {
            var err = event.error || 'error';
            console.warn('Speech error:', err);
            if (err === 'no-speech') return;
            var msg = 'Micrófono: ' + err;
            if (err === 'not-allowed') {
              msg = 'Permiso de micrófono denegado. Haz clic en el ícono del candado en la barra de direcciones y selecciona "Permitir micrófono".';
            } else if (err === 'network') {
              msg = 'Error de conexión con el servicio de voz de Google.';
            }
            window.dispatchEvent(new CustomEvent('tm_speech_error', { detail: msg }));
            window.dispatchEvent(new CustomEvent('tm_speech_end'));
          };

          rec.onend = function() {
            window.dispatchEvent(new CustomEvent('tm_speech_end'));
          };

          rec.start();
        } catch(e) {
          window.dispatchEvent(new CustomEvent('tm_speech_error', { detail: 'No se pudo iniciar el dictado: ' + e }));
          window.dispatchEvent(new CustomEvent('tm_speech_end'));
        }
      };

      if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        navigator.mediaDevices.getUserMedia({ audio: true }).then(function(stream) {
          stream.getTracks().forEach(function(t) { t.stop(); });
          run();
        }).catch(function(err) {
          console.warn('getUserMedia warning:', err);
          run();
        });
      } else {
        run();
      }
    },

    stop: function() {
      if (window.tmSpeech.recognition) {
        try { window.tmSpeech.recognition.stop(); } catch(e) {}
      }
      window.dispatchEvent(new CustomEvent('tm_speech_end'));
    }
  };
})();
''';
      html.document.head?.append(script);
      _jsInjected = true;
    } catch (_) {}
  }

  void start({
    required Function(String text, bool isFinal) onResult,
    required VoidCallback onEnd,
    Function(String error)? onError,
    VoidCallback? onStart,
  }) {
    _ensureJsInjected();
    _cleanSubs();

    _subs.add(html.window.on['tm_speech_start'].listen((_) {
      _isListening = true;
      onStart?.call();
    }));

    _subs.add(html.window.on['tm_speech_result'].listen((event) {
      if (event is html.CustomEvent && event.detail != null) {
        try {
          final data = jsonDecode(event.detail.toString()) as Map<String, dynamic>;
          final text = data['text']?.toString() ?? '';
          final isFinal = data['isFinal'] == true;
          if (text.isNotEmpty) {
            onResult(text, isFinal);
          }
        } catch (_) {}
      }
    }));

    _subs.add(html.window.on['tm_speech_error'].listen((event) {
      _isListening = false;
      if (event is html.CustomEvent && event.detail != null) {
        onError?.call(event.detail.toString());
      }
    }));

    _subs.add(html.window.on['tm_speech_end'].listen((_) {
      _isListening = false;
      onEnd();
    }));

    _isListening = true;
    try {
      final tm = js.context['tmSpeech'];
      if (tm != null) {
        tm.callMethod('start');
      } else {
        throw Exception('tmSpeech no disponible');
      }
    } catch (e) {
      _isListening = false;
      onError?.call('Error al iniciar: $e');
      onEnd();
    }
  }

  void _cleanSubs() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  void stop() {
    _isListening = false;
    _cleanSubs();
    try {
      final tm = js.context['tmSpeech'];
      if (tm != null) {
        tm.callMethod('stop');
      }
    } catch (_) {}
  }
}
