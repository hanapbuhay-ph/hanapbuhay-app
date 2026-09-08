import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../services/secure_storage_service.dart';

/// Centralized API client for all HTTP requests.
/// Handles authentication headers, JSON encoding/decoding, and error responses.
class ApiClient {
  static const String _baseUrl = AppConstants.apiBaseUrl;
  static final _storage = SecureStorageService();

  /// Global navigator key used by [ApiClient] to force a (re)login on a 401.
  /// Wired into `MaterialApp.navigatorKey` in main.dart.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
    Map<String, List<String>>? files,
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
      
      // Add files if provided (each key may hold multiple paths)
      if (files != null) {
        for (var entry in files.entries) {
          for (final path in entry.value) {
            request.files.add(await http.MultipartFile.fromPath(entry.key, path));
          }
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
    // Centralized 401 / session-expiry handling. This is the single place in
    // the app where an expired/invalid auth token triggers a forced re-login.
    if (response.statusCode == 401) {
      _handleUnauthorized();
    }
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

  /// Clears the stored auth token + user role and forces navigation to the
  /// Login screen (clearing the entire navigation stack). Defined here only.
  static Future<void> _handleUnauthorized() async {
    try {
      await _storage.deleteToken();
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_role');
    } catch (_) {}

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    // Don't force navigation if the user is already on the Login screen.
    final currentRoute = ModalRoute.of(navigator.context);
    if (currentRoute?.settings.name == AppConstants.loginRoute) return;

    navigator.pushNamedAndRemoveUntil(
      AppConstants.loginRoute,
      (route) => false,
    );
  }

  /// Handle errors
  static Map<String, dynamic> _handleError(dynamic error) {
    return {
      'success': false,
      'message': 'Network error: ${error.toString()}',
    };
  }
}
