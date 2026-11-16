/// Stub implementation for non-web platforms (Android, iOS, macOS, Windows, Linux).
void openOAuthPopup(String url, {String name = 'OAuth', int width = 500, int height = 650}) {
  // Mobile uses url_launcher or Chrome Custom Tabs directly.
}

void registerOAuthWebMessageListener(void Function(Map<String, dynamic> data) onMessage) {
  // No-op on non-web.
}
