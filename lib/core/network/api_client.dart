import 'dart:convert';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/secure_storage.dart';

/// URL base del backend.
///
/// Se puede reemplazar al compilar sin editar el código:
/// `flutter build apk --dart-define=API_BASE_URL=https://api.tu-dominio.com`
/// Mantener la URL fuera del binario evita que una IP pública nueva de EC2
/// deje a las versiones ya compiladas apuntando a un servidor inexistente.
const String kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://18.191.162.235:8000',
);

/// Deriva la URL base de WebSockets a partir de [kBaseUrl].
/// Si kBaseUrl utiliza http:// se transforma a ws://, y si usa https:// a wss://.
String get kWsBaseUrl {
  final uri = Uri.parse(kBaseUrl);
  final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
  final host = uri.host;
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '$wsScheme://$host$port';
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final SecureStorage _storage;

  ApiClient(this._storage);

  /// Callback global invocado cuando la sesión expira definitivamente (401 no renovable).
  static void Function(String message)? onSessionExpired;

  // ──────────────────────────────────────────────
  // Métodos base
  // ──────────────────────────────────────────────

  /// Obtiene el código de idioma activo ('es' o 'en')
  Future<String> _getLanguageCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('selected_language_code');
      if (code != null && code.isNotEmpty) return code;
    } catch (_) {}
    try {
      final systemCode = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
      if (systemCode.startsWith('en')) return 'en';
    } catch (_) {}
    return 'es';
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final lang = await _getLanguageCode();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept-Language': lang,
    };
    if (auth) {
      final token = await _storage.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _decode(http.Response res) {
    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
    _handleError(res.statusCode, body);
    throw ApiException(res.statusCode, body);
  }

  List<dynamic> _decodeList(http.Response res) {
    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(body) as List<dynamic>;
    }
    _handleError(res.statusCode, body);
    throw ApiException(res.statusCode, body);
  }

  static const Map<String, String> _errorTranslations = {
    'Credenciales inválidas': 'Invalid credentials',
    'Credenciales incorrectas': 'Incorrect credentials',
    'El correo ya está registrado': 'Email is already registered',
    'Email ya registrado': 'Email is already registered',
    'Usuario no encontrado': 'User not found',
    'Perfil no encontrado': 'Profile not found',
    'Acceso denegado': 'Access denied',
    'No autorizado': 'Unauthorized',
    'No autorizado para ver estas notificaciones': 'Not authorized to view these notifications',
    'Vacante no encontrada': 'Job vacancy not found',
    'No se encontró la vacante': 'Job vacancy not found',
    'Ya te has postulado a esta vacante': 'You have already applied to this job vacancy',
    'Ya estás postulado a esta vacante': 'You have already applied to this job vacancy',
    'Postulación no encontrada': 'Application not found',
    'Token expirado o inválido': 'Expired or invalid token',
    'Formato de archivo inválido': 'Invalid file format',
    'Demasiados intentos. Por favor, espera un momento antes de reintentar.': 'Too many requests. Please wait a moment before trying again.',
  };

  void _handleError(int code, String body) {
    String message;
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      message = json['detail']?.toString() ?? body;
    } catch (_) {
      message = body;
    }

    // Traducción de errores del servidor si la preferencia del usuario es inglés
    try {
      final isEn = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase().startsWith('en');
      if (isEn && _errorTranslations.containsKey(message)) {
        message = _errorTranslations[message]!;
      }
    } catch (_) {}

    // Reporte a Sentry si ocurre un error 500 no previsto en el servidor
    if (code >= 500) {
      try {
        Sentry.captureMessage(
          'API Server Error $code: $message',
          level: SentryLevel.error,
        );
      } catch (_) {}
    }

    throw ApiException(code, message);
  }

  /// Intenta renovar el token JWT de acceso usando el refresh token almacenado en SecureStorage.
  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final uri = Uri.parse('$kBaseUrl/auth/refresh');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final newAccess = data['access_token'] as String?;
        final newRefresh = data['refresh_token'] as String?;
        if (newAccess != null && newAccess.isNotEmpty) {
          await _storage.saveToken(newAccess);
          if (newRefresh != null && newRefresh.isNotEmpty) {
            await _storage.saveRefreshToken(newRefresh);
          }
          return true;
        }
      }
    } catch (e, stackTrace) {
      try {
        Sentry.captureException(e, stackTrace: stackTrace);
      } catch (_) {}
    }
    return false;
  }

  /// Intercepta respuestas 401 en peticiones autenticadas:
  /// 1. Intenta renovar la sesión silenciosamente mediante `_tryRefreshToken()`.
  /// 2. Si tiene éxito, reintenta la petición original con el nuevo token.
  /// 3. Si la renovación falla (o el reintento da 401 de nuevo), borra la sesión en SecureStorage,
  ///    dispara el callback [onSessionExpired] y lanza una [ApiException] 401.
  Future<http.Response> _handle401OrRetry(
    http.Response res,
    String path,
    bool auth,
    Future<http.Response> Function() retry,
  ) async {
    if (res.statusCode == 401 && auth && !path.startsWith('/auth/')) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final retryRes = await retry();
        if (retryRes.statusCode == 401) {
          await _onAuthFailure();
        }
        return retryRes;
      } else {
        await _onAuthFailure();
      }
    }
    return res;
  }

  Future<void> _onAuthFailure() async {
    await _storage.clearSession();
    const message = 'Tu sesión ha expirado. Por favor, inicia sesión de nuevo.';
    onSessionExpired?.call(message);
    throw const ApiException(401, message);
  }

  // ──────────────────────────────────────────────
  // GET (CON CACHÉ OFFLINE-FIRST)
  // ──────────────────────────────────────────────

  Future<Map<String, dynamic>> get(
    String path, {
    bool auth = true,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$kBaseUrl$path')
        .replace(queryParameters: queryParams);
    try {
      var res = await http
          .get(uri, headers: await _headers(auth: auth))
          .timeout(const Duration(seconds: 15));

      res = await _handle401OrRetry(
        res,
        path,
        auth,
        () async => http
            .get(uri, headers: await _headers(auth: auth))
            .timeout(const Duration(seconds: 15)),
      );
      
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cache_$uri', res.body);
      }
      return _decode(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      final prefs = await SharedPreferences.getInstance();
      final cachedBody = prefs.getString('cache_$uri');
      if (cachedBody != null) {
        return jsonDecode(cachedBody) as Map<String, dynamic>;
      }
      throw const ApiException(503, 'Sin conexión y sin datos en caché.');
    }
  }

  Future<List<dynamic>> getList(
    String path, {
    bool auth = true,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$kBaseUrl$path')
        .replace(queryParameters: queryParams);
    try {
      var res = await http
          .get(uri, headers: await _headers(auth: auth))
          .timeout(const Duration(seconds: 15));

      res = await _handle401OrRetry(
        res,
        path,
        auth,
        () async => http
            .get(uri, headers: await _headers(auth: auth))
            .timeout(const Duration(seconds: 15)),
      );
          
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cache_$uri', res.body);
      }
      return _decodeList(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      final prefs = await SharedPreferences.getInstance();
      final cachedBody = prefs.getString('cache_$uri');
      if (cachedBody != null) {
        return jsonDecode(cachedBody) as List<dynamic>;
      }
      throw const ApiException(503, 'Sin conexión y sin datos en caché.');
    }
  }

  // ──────────────────────────────────────────────
  // POST
  // ──────────────────────────────────────────────

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final uri = Uri.parse('$kBaseUrl$path');
    var res = await http
        .post(
          uri,
          headers: await _headers(auth: auth),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    res = await _handle401OrRetry(
      res,
      path,
      auth,
      () async => http
          .post(
            uri,
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15)),
    );
    return _decode(res);
  }

  // ──────────────────────────────────────────────
  // PUT
  // ──────────────────────────────────────────────

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$kBaseUrl$path');
    var res = await http
        .put(uri, headers: await _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));

    res = await _handle401OrRetry(
      res,
      path,
      true,
      () async => http
          .put(uri, headers: await _headers(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15)),
    );
    return _decode(res);
  }

  // ──────────────────────────────────────────────
  // PATCH
  // ──────────────────────────────────────────────

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$kBaseUrl$path');
    var res = await http
        .patch(uri, headers: await _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));

    res = await _handle401OrRetry(
      res,
      path,
      true,
      () async => http
          .patch(uri, headers: await _headers(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15)),
    );
    return _decode(res);
  }

  // ──────────────────────────────────────────────
  // DELETE
  // ──────────────────────────────────────────────

  Future<void> delete(String path, {bool auth = true}) async {
    final uri = Uri.parse('$kBaseUrl$path');
    var res = await http
        .delete(uri, headers: await _headers(auth: auth))
        .timeout(const Duration(seconds: 15));

    res = await _handle401OrRetry(
      res,
      path,
      auth,
      () async => http
          .delete(uri, headers: await _headers(auth: auth))
          .timeout(const Duration(seconds: 15)),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }
    final body = utf8.decode(res.bodyBytes);
    _handleError(res.statusCode, body);
    throw ApiException(res.statusCode, body);
  }

  // ──────────────────────────────────────────────
  // Multipart POST (subir archivos — CV)
  // ──────────────────────────────────────────────

  Future<Map<String, dynamic>> postMultipart(
    String path,
    List<int> fileBytes,
    String fileName,
    String mimeType,
  ) async {
    final token = await _storage.getToken();
    final lang = await _getLanguageCode();
    final uri = Uri.parse('$kBaseUrl$path');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Accept-Language'] = lang;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    var res = await http.Response.fromStream(streamed);

    res = await _handle401OrRetry(
      res,
      path,
      true,
      () async {
        final newToken = await _storage.getToken();
        final retryRequest = http.MultipartRequest('POST', uri);
        retryRequest.headers['Accept-Language'] = lang;
        if (newToken != null) retryRequest.headers['Authorization'] = 'Bearer $newToken';
        retryRequest.files.add(
          http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
        );
        final retryStreamed = await retryRequest.send().timeout(const Duration(seconds: 30));
        return http.Response.fromStream(retryStreamed);
      },
    );
    return _decode(res);
  }
}
