import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../../services/secure_storage_service.dart';

/// Centralized API client for all HTTP requests.
/// Handles authentication headers, JSON encoding/decoding, and error responses.
class ApiClient {
  static const String _baseUrl = AppConstants.apiBaseUrl;
  static final _storage = SecureStorageService();

  /// GET request
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    try {
      final headers = await _buildHeaders(requiresAuth);
      final uri = Uri.parse('$_baseUrl$endpoint');
      
      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST request
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    try {
      final headers = await _buildHeaders(requiresAuth);
      final uri = Uri.parse('$_baseUrl$endpoint');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST request with multipart/form-data (for file uploads)
  static Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    Map<String, String>? files,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);
      
      // Add auth header if required
      if (requiresAuth) {
        final token = await _storage.getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }
      
      request.headers['Accept'] = 'application/json';
      
      // Add fields
      request.fields.addAll(fields);
      
      // Add files if provided
      if (files != null) {
        for (var entry in files.entries) {
          request.files.add(await http.MultipartFile.fromPath(
            entry.key,
            entry.value,
          ));
        }
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// PUT request
  static Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    try {
      final headers = await _buildHeaders(requiresAuth);
      final uri = Uri.parse('$_baseUrl$endpoint');
      
      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE request
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    try {
      final headers = await _buildHeaders(requiresAuth);
      final uri = Uri.parse('$_baseUrl$endpoint');
      
      final response = await http.delete(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Build headers with optional authentication
  static Future<Map<String, String>> _buildHeaders(bool requiresAuth) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _storage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Handle HTTP response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Invalid server response: ${response.body}',
      };
    }
  }

  /// Handle errors
  static Map<String, dynamic> _handleError(dynamic error) {
    return {
      'success': false,
      'message': 'Network error: ${error.toString()}',
    };
  }
}
