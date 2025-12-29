// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secure_store.dart';

class ApiConfig {
  // ⚠️ Android Emülatör: 10.0.2.2, iOS Simulator/desktop: 127.0.0.1
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://127.0.0.1:3000',
  );
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();
  final SecureStore _store = SecureStore();

  Future<Map<String, dynamic>> getJson(String path) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = await _authHeaders();
    final res = await http.get(uri, headers: headers);
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = await _authHeaders(contentTypeJson: true);
    final res = await http.post(uri, headers: headers, body: jsonEncode(body));
    return _handleResponse(res);
  }

  Future<Map<String, String>> _authHeaders({bool contentTypeJson = false}) async {
    final token = await _store.getToken();
    final headers = <String, String>{};
    if (contentTypeJson) headers['Content-Type'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map> deleteJson(String path) async {
  final uri = Uri.parse('${ApiConfig.baseUrl}$path');
  final headers = await _authHeaders();
  final res = await http.delete(uri, headers: headers);
  return _handleResponse(res);
  }

  Map<String, dynamic> _handleResponse(http.Response res) {
    final data = res.body.isEmpty ? {} : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (data is Map<String, dynamic>) ? data : {'data': data};
    } else {
      final msg = (data is Map && data['error'] is String) ? data['error'] : 'Request failed';
      throw ApiException(res.statusCode, msg);
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}
