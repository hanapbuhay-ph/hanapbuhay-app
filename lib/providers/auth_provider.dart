import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/auth_result_model.dart';
import '../services/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SecureStorageService _storage = SecureStorageService();

  AuthProvider(this._authRepository);

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  String? _userId;
  String? get userId => _userId;

  String? _userEmail;
  String? get userEmail => _userEmail;

  String? _userRole;
  String? get userRole => _userRole;

  String? _userName;
  String? get userName => _userName;

  String? _userMobile;
  String? get userMobile => _userMobile;

  String? _userBarangay;
  String? get userBarangay => _userBarangay;

  String? _userAvatar;
  String? get userAvatar => _userAvatar;

  String? _signInMethod;
  String? get signInMethod => _signInMethod;

  bool _hasSeenOnboarding = false;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  bool _twoFactorEnabled = true;
  bool get twoFactorEnabled => _twoFactorEnabled;

  String getHomeRoute() {
    return _userRole == 'worker' ? '/worker-home' : '/client-home';
  }

  Future<void> checkInitialState() async {
    final token = await _storage.getToken();
    _isAuthenticated = token != null;

    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    _userId = prefs.getString('user_id');
    _userEmail = prefs.getString('user_email');
    _userRole = prefs.getString('user_role');
    _userName = prefs.getString('user_name');
    _userMobile = prefs.getString('user_mobile');
    _userBarangay = prefs.getString('user_barangay');
    _userAvatar = prefs.getString('user_avatar');
    _signInMethod = prefs.getString('sign_in_method');
    _twoFactorEnabled = prefs.getBool('2fa_enabled') ?? true;

    notifyListeners();
  }

  bool get isGoogleLinked => _signInMethod == 'google';

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    _hasSeenOnboarding = true;
    notifyListeners();
  }

  Future<void> toggleTwoFactor(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('2fa_enabled', value);
    _twoFactorEnabled = value;
    notifyListeners();
  }

  Future<AuthResult> login(String email, String password) async {
    final result = await _authRepository.login(email, password);
    if (result.success) {
      if (_twoFactorEnabled) {
        return AuthResult.success(
          message: 'Two-factor authentication required.',
          data: {'email': email, 'requiresOtp': true},
        );
      }

      final userData = result.data?['user'] as Map<String, dynamic>?;
      await setAuthenticated(
        result.data?['token'] ?? '',
        userData?['role'] ?? 'client',
        id: userData?['id']?.toString(),
        email: email,
        name: userData?['name'],
        mobile: userData?['mobile_number'],
        barangay: userData?['barangay']?['name'],
        avatar: userData?['avatar_url'],
        method: userData?['sign_in_method'] ?? 'email',
      );
    }
    return result;
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String mobileNumber,
    required String barangay,
  }) async {
    return await _authRepository.register(
      name: name,
      email: email,
      password: password,
      role: role,
      mobileNumber: mobileNumber,
      barangay: barangay,
    );
  }

  Future<AuthResult> verifyOtp(String email, String otp) async {
    final result = await _authRepository.verifyOtp(email, otp);
    if (result.success) {
      final userData = result.data?['user'] as Map<String, dynamic>?;
      await setAuthenticated(
        result.data?['token'] ?? '',
        userData?['role'] ?? 'client',
        id: userData?['id']?.toString(),
        email: email,
        name: userData?['name'],
        mobile: userData?['mobile_number'],
        barangay: userData?['barangay']?['name'],
        avatar: userData?['avatar_url'],
        method: userData?['sign_in_method'] ?? 'email',
      );
    }
    return result;
  }

  Future<void> setAuthenticated(String token, String role, {
    String? id, 
    String? email, 
    String? name, 
    String? mobile, 
    String? barangay,
    String? avatar,
    String method = 'email',
  }) async {
    await _storage.saveToken(token);
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('user_role', role);
    _userRole = role;

    await prefs.setString('sign_in_method', method);
    _signInMethod = method;

    if (id != null) {
      await prefs.setString('user_id', id);
      _userId = id;
    }
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
    if (barangay != null) {
      await prefs.setString('user_barangay', barangay);
      _userBarangay = barangay;
    }
    if (avatar != null) {
      await prefs.setString('user_avatar', avatar);
      _userAvatar = avatar;
    }

    _isAuthenticated = true;
    notifyListeners();
  }

  Future<AuthResult> updateProfile({required String name, required String mobileNumber, String? avatarPath}) async {
    final result = await _authRepository.updateProfile(name: name, mobileNumber: mobileNumber, avatarPath: avatarPath);
    if (result.success) {
      await updateLocalProfile(name: name, mobile: mobileNumber, avatar: avatarPath);
    }
    return result;
  }

  Future<AuthResult> forgotPassword(String identifier) async {
    return await _authRepository.forgotPassword(identifier);
  }

  Future<AuthResult> verifyForgotPasswordOtp(String identifier, String otp) async {
    return await _authRepository.verifyForgotPasswordOtp(identifier, otp);
  }

  Future<AuthResult> resetPassword(String identifier, String newPassword) async {
    return await _authRepository.resetPassword(identifier, newPassword);
  }

  Future<AuthResult> changePassword({required String currentPassword, required String newPassword}) async {
    final result = await _authRepository.changePassword(currentPassword: currentPassword, newPassword: newPassword);
    if (result.success && _signInMethod == 'google') {
      final prefs = await SharedPreferences.getInstance();
      _signInMethod = 'email'; // Or 'both'
      await prefs.setString('sign_in_method', _signInMethod!);
      notifyListeners();
    }
    return result;
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
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('user_mobile');
    await prefs.remove('user_avatar');
    await prefs.remove('sign_in_method');
    
    _isAuthenticated = false;
    _userId = null;
    _userEmail = null;
    _userRole = null;
    _userName = null;
    _userMobile = null;
    _userAvatar = null;
    _signInMethod = null;
    
    notifyListeners();
  }
}
