import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';
import '../services/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final SecureStorageService _storage = SecureStorageService();

  AuthProvider(AuthRepository authRepository);

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  String? _userEmail;
  String? get userEmail => _userEmail;

  String? _userRole;
  String? get userRole => _userRole;

  bool _hasSeenOnboarding = false;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  /// Helper to get the correct home route based on the authenticated user's role.
  String getHomeRoute() {
    return _userRole == 'worker' ? '/worker-home' : '/client-home';
  }

  Future<void> checkInitialState() async {
    final token = await _storage.getToken();
    _isAuthenticated = token != null;

    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    _userEmail = prefs.getString('user_email');
    _userRole = prefs.getString('user_role');

    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    _hasSeenOnboarding = true;
    notifyListeners();
  }

  Future<void> setAuthenticated(String token, String role, {String? email}) async {
    await _storage.saveToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
    _userRole = role;
    if (email != null) {
      await prefs.setString('user_email', email);
      _userEmail = email;
    }
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await prefs.remove('user_email');
    _isAuthenticated = false;
    _userEmail = null;
    _userRole = null;
    notifyListeners();
  }
  
  // Login, Register, Logout methods would go here...
}
