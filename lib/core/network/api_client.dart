import 'dart:convert';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
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

    throw ApiException(code, message);
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
      final res = await http
          .get(uri, headers: await _headers(auth: auth))
          .timeout(const Duration(seconds: 15));
      
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cache_$uri', res.body);
      }
      return _decode(res);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cachedBody = prefs.getString('cache_$uri');
      if (cachedBody != null) {
        return jsonDecode(cachedBody) as Map<String, dynamic>;
      }
      throw ApiException(503, 'Sin conexión y sin datos en caché.');
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
      final res = await http
          .get(uri, headers: await _headers(auth: auth))
          .timeout(const Duration(seconds: 15));
          
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cache_$uri', res.body);
      }
      return _decodeList(res);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cachedBody = prefs.getString('cache_$uri');
      if (cachedBody != null) {
        return jsonDecode(cachedBody) as List<dynamic>;
      }
      throw ApiException(503, 'Sin conexión y sin datos en caché.');
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
    final res = await http
        .post(
          uri,
          headers: await _headers(auth: auth),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
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
    final res = await http
        .put(uri, headers: await _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
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
    final res = await http
        .patch(uri, headers: await _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    return _decode(res);
  }

  // ──────────────────────────────────────────────
  // DELETE
  // ──────────────────────────────────────────────

  Future<void> delete(String path, {bool auth = true}) async {
    final uri = Uri.parse('$kBaseUrl$path');
    final res = await http
        .delete(uri, headers: await _headers(auth: auth))
        .timeout(const Duration(seconds: 15));
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
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }
}
