import 'dart:convert';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

/// Opens a true centered popup window on Web instead of a new browser tab.
void openOAuthPopup(String url, {String name = 'OAuth', int width = 500, int height = 650}) {
  final screenWidth = web.window.screen.width;
  final screenHeight = web.window.screen.height;
  final left = (screenWidth - width) ~/ 2;
  final top = (screenHeight - height) ~/ 2;

  final features = 'width=$width,height=$height,top=$top,left=$left,toolbar=no,location=no,status=no,menubar=no,scrollbars=yes,resizable=yes';
  web.window.open(url, name, features);
}

/// Registers a listener for window.postMessage sent from the OAuth popup when completed.
void registerOAuthWebMessageListener(void Function(Map<String, dynamic> data) onMessage) {
  web.window.addEventListener(
    'message',
    (web.MessageEvent event) {
      if (event.data != null) {
        try {
          final jsVal = event.data;
          if (jsVal.isA<JSString>()) {
            final str = (jsVal as JSString).toDart;
            final decoded = jsonDecode(str);
            if (decoded is Map<String, dynamic> && decoded['type'] == 'TALENTMATCH_AUTH_SUCCESS') {
              onMessage(decoded);
            }
          }
        } catch (_) {}
      }
    }.toJS,
  );
}
