import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';
import '../services/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final SecureStorageService _storage = SecureStorageService();

  AuthProvider(AuthRepository authRepository);

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  bool _hasSeenOnboarding = false;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  Future<void> checkInitialState() async {
    final token = await _storage.getToken();
    _isAuthenticated = token != null;

    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    _hasSeenOnboarding = true;
    notifyListeners();
  }

  Future<void> setAuthenticated(String token, String role) async {
    await _storage.saveToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
    _isAuthenticated = true;
    notifyListeners();
  }
  
  // Login, Register, Logout methods would go here...
}
