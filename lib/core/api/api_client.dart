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
  static final _routeObserver = _CurrentRouteObserver();
  static bool _handlingUnauthorized = false;

  /// Global navigator key used by [ApiClient] to force a (re)login on a 401.
  /// Wired into `MaterialApp.navigatorKey` in main.dart.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static NavigatorObserver get routeObserver => _routeObserver;

  /// GET request
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    try {
      final headers = await _buildHeaders(requiresAuth);
      final uri = Uri.parse('$_baseUrl$endpoint');

      final response = await http.get(uri, headers: headers);
      return _handleResponse(response, requiresAuth: requiresAuth);
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

      return _handleResponse(response, requiresAuth: requiresAuth);
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
            request.files.add(
              await http.MultipartFile.fromPath(entry.key, path),
            );
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response, requiresAuth: requiresAuth);
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

      return _handleResponse(response, requiresAuth: requiresAuth);
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
      return _handleResponse(response, requiresAuth: requiresAuth);
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
  static Map<String, dynamic> _handleResponse(
    http.Response response, {
    required bool requiresAuth,
  }) {
    // Centralized 401 / session-expiry handling. This is the single place in
    // the app where an expired/invalid auth token triggers a forced re-login.
    if (response.statusCode == 401 && requiresAuth) {
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
    if (_handlingUnauthorized) return;
    _handlingUnauthorized = true;

    try {
      final token = await _storage.getToken();
      if (token == null || token.isEmpty) return;

      await _storage.deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_role');

      final currentRouteName = _routeObserver.currentRouteName;
      if (!shouldRedirectToLogin(
        hasAuthToken: true,
        routeName: currentRouteName,
      )) {
        return;
      }

      final navigator = navigatorKey.currentState;
      if (navigator == null) return;
      navigator.pushNamedAndRemoveUntil(
        AppConstants.loginRoute,
        (route) => false,
      );
    } finally {
      _handlingUnauthorized = false;
    }
  }

  static bool isAuthenticationRoute(String? routeName) {
    final path = Uri.tryParse(routeName ?? '')?.path;
    return const {
      AppConstants.loginRoute,
      '/onboarding',
      '/welcome',
      '/register-role',
      '/register-account',
      '/verify-email',
      '/forgot-password',
    }.contains(path);
  }

  static bool shouldRedirectToLogin({
    required bool hasAuthToken,
    required String? routeName,
  }) {
    return hasAuthToken && !isAuthenticationRoute(routeName);
  }

  /// Handle errors
  static Map<String, dynamic> _handleError(dynamic error) {
    return {'success': false, 'message': 'Network error: ${error.toString()}'};
  }
}

class _CurrentRouteObserver extends NavigatorObserver {
  String? currentRouteName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    currentRouteName = route.settings.name;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    currentRouteName = previousRoute?.settings.name;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    currentRouteName = newRoute?.settings.name;
  }
}
