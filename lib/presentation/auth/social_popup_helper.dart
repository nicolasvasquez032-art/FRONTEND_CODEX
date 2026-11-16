import 'social_popup_stub.dart'
    if (dart.library.html) 'social_popup_web.dart' as platform;

/// Helper cross-platform para abrir ventanas emergentes (popups) reales de OAuth.
class SocialPopupHelper {
  /// Abre una ventana emergente en Web, o utiliza el fallback de la plataforma.
  static void openPopup(
    String url, {
    String name = 'TalentMatch_OAuth',
    int width = 500,
    int height = 650,
  }) {
    platform.openOAuthPopup(url, name: name, width: width, height: height);
  }

  /// Escucha mensajes entrantes desde el popup en Web (`window.postMessage`).
  static void onWebMessage(void Function(Map<String, dynamic> data) callback) {
    platform.registerOAuthWebMessageListener(callback);
  }
}
