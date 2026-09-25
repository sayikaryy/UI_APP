import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String _baseUrl = ApiConstants.defaultBaseUrl;
  String? _authToken;
  VoidCallback? onUnauthorized;

  String get baseUrl => _baseUrl;
  String? get authToken => _authToken;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(ApiConstants.keyToken);
    final savedBaseUrl = prefs.getString(ApiConstants.keyBaseUrl);
    if (savedBaseUrl != null && savedBaseUrl.isNotEmpty) {
      _baseUrl = savedBaseUrl;
    } else {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        _baseUrl = 'http://10.0.2.2:8000/api/v1';
      } else {
        _baseUrl = 'http://127.0.0.1:8000/api/v1';
      }
    }
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.keyBaseUrl, _baseUrl);
  }

  Future<void> setAuthToken(String? token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(ApiConstants.keyToken, token);
    } else {
      await prefs.remove(ApiConstants.keyToken);
    }
  }

  Map<String, String> _buildHeaders([Map<String, String>? extraHeaders]) {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    String cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    String url = '$_baseUrl$cleanEndpoint';

    if (queryParams != null && queryParams.isNotEmpty) {
      final cleanParams = queryParams.map((k, v) => MapEntry(k, v.toString()));
      return Uri.parse(url).replace(queryParameters: cleanParams);
    }
    return Uri.parse(url);
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      final response = await http.get(uri, headers: _buildHeaders());
      return _processResponse(response);
    } catch (e) {
      _handleNetworkError(e);
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body, Map<String, dynamic>? queryParams}) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      final response = await http.post(
        uri,
        headers: _buildHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      _handleNetworkError(e);
    }
  }

  Future<dynamic> put(String endpoint, {dynamic body, Map<String, dynamic>? queryParams}) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      final response = await http.put(
        uri,
        headers: _buildHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      _handleNetworkError(e);
    }
  }

  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      final response = await http.delete(uri, headers: _buildHeaders());
      return _processResponse(response);
    } catch (e) {
      _handleNetworkError(e);
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic jsonBody;
    try {
      jsonBody = jsonDecode(response.body);
    } catch (_) {
      jsonBody = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    // Auto-logout interceptor on 401 Unauthorized
    if (response.statusCode == 401) {
      setAuthToken(null);
      if (onUnauthorized != null) {
        onUnauthorized!();
      }
      throw ApiException(
        jsonBody != null && jsonBody['message'] != null
            ? jsonBody['message']
            : 'Session expired. Please log in again.',
        statusCode: 401,
      );
    }

    // Validation or Logic Error
    String message = 'Request failed (${response.statusCode})';
    Map<String, dynamic>? errors;

    if (jsonBody is Map<String, dynamic>) {
      if (jsonBody.containsKey('message')) {
        message = jsonBody['message'].toString();
      }
      if (jsonBody.containsKey('errors') && jsonBody['errors'] is Map) {
        errors = Map<String, dynamic>.from(jsonBody['errors']);
        // Extract first error message if available
        if (errors.isNotEmpty) {
          final firstVal = errors.values.first;
          if (firstVal is List && firstVal.isNotEmpty) {
            message = firstVal.first.toString();
          }
        }
      }
    }

    throw ApiException(message, statusCode: response.statusCode, errors: errors);
  }

  void _handleNetworkError(dynamic error) {
    if (error is ApiException) {
      throw error;
    }
    throw ApiException('Network connection failed. Please check backend server.');
  }
}
