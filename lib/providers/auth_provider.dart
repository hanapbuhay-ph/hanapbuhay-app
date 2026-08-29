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

  String? _userName;
  String? get userName => _userName;

  String? _userMobile;
  String? get userMobile => _userMobile;

  String? _userAvatar;
  String? get userAvatar => _userAvatar;

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
    _userName = prefs.getString('user_name');
    _userMobile = prefs.getString('user_mobile');
    _userAvatar = prefs.getString('user_avatar');

    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    _hasSeenOnboarding = true;
    notifyListeners();
  }

  Future<void> setAuthenticated(String token, String role, {String? email, String? name, String? mobile, String? avatar}) async {
    await _storage.saveToken(token);
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('user_role', role);
    _userRole = role;

    if (email != null) {
      await prefs.setString('user_email', email);
      _userEmail = email;
    }
    if (name != null) {
      await prefs.setString('user_name', name);
      _userName = name;
    }
    if (mobile != null) {
      await prefs.setString('user_mobile', mobile);
      _userMobile = mobile;
    }
    if (avatar != null) {
      await prefs.setString('user_avatar', avatar);
      _userAvatar = avatar;
    }

    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> updateLocalProfile({required String name, required String mobile, String? avatar}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    _userName = name;
    await prefs.setString('user_mobile', mobile);
    _userMobile = mobile;
    if (avatar != null) {
      await prefs.setString('user_avatar', avatar);
      _userAvatar = avatar;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('user_mobile');
    await prefs.remove('user_avatar');
    
    _isAuthenticated = false;
    _userEmail = null;
    _userRole = null;
    _userName = null;
    _userMobile = null;
    _userAvatar = null;
    
    notifyListeners();
  }
}
