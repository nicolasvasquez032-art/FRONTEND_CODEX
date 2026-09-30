import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/secure_storage.dart';

/// URL base del backend. Cambiar a IP real del servidor en producción.
const String kBaseUrl = 'http://127.0.0.1:8000'; // IP para Web/Localhost

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

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
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

  void _handleError(int code, String body) {
    String message;
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      message = json['detail']?.toString() ?? body;
    } catch (_) {
      message = body;
    }
    throw ApiException(code, message);
  }

  // ──────────────────────────────────────────────
  // GET
  // ──────────────────────────────────────────────

  Future<Map<String, dynamic>> get(
    String path, {
    bool auth = true,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$kBaseUrl$path')
        .replace(queryParameters: queryParams);
    final res = await http
        .get(uri, headers: await _headers(auth: auth))
        .timeout(const Duration(seconds: 15));
    return _decode(res);
  }

  Future<List<dynamic>> getList(
    String path, {
    bool auth = true,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$kBaseUrl$path')
        .replace(queryParameters: queryParams);
    final res = await http
        .get(uri, headers: await _headers(auth: auth))
        .timeout(const Duration(seconds: 15));
    return _decodeList(res);
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
        .post(uri, headers: await _headers(auth: auth), body: jsonEncode(body))
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
  // Multipart POST (subir archivos — CV)
  // ──────────────────────────────────────────────

  Future<Map<String, dynamic>> postMultipart(
    String path,
    List<int> fileBytes,
    String fileName,
    String mimeType,
  ) async {
    final token = await _storage.getToken();
    final uri = Uri.parse('$kBaseUrl$path');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    ));
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }
}
