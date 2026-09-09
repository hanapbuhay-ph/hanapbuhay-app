import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/api/api_auth_repository.dart';
import '../data/models/auth_result_model.dart';
import '../services/secure_storage_service.dart';
import '../services/google_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/api/api_client.dart'; // ignore: unused_import - used in logout()

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

  int? _userBarangayId;
  int? get userBarangayId => _userBarangayId;

  String? _userAvatar;
  String? get userAvatar => _userAvatar;

  String? _workerProfileId;
  /// The authenticated worker's profile ID (integer stored as string).
  /// Populated from GET /api/user → data.worker_profile.id.
  /// null for client-role users or before refreshProfile() completes.
  String? get workerProfileId => _workerProfileId;

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
    _userBarangayId = prefs.getInt('user_barangay_id');
    _userAvatar = prefs.getString('user_avatar');
    _workerProfileId = prefs.getString('worker_profile_id');
    _signInMethod = prefs.getString('sign_in_method');
    _twoFactorEnabled = prefs.getBool('2fa_enabled') ?? true;

    notifyListeners();
    if (_isAuthenticated && (_userMobile == null || _userMobile!.isEmpty)) {
      await refreshProfile();
    }
  }

  /// Fetch GET /api/user and hydrate local fields. Login/Verify often omit mobile_number.
  Future<void> refreshProfile() async {
    try {
      final res = await ApiClient.get('/user', requiresAuth: true);
      if (res['success'] != true) return;
      final raw = res['data'];
      final user = raw is Map ? raw.map((k, v) => MapEntry(k.toString(), v)) : <String, dynamic>{};
      final nested = user['user'] is Map ? (user['user'] as Map).map((k, v) => MapEntry(k.toString(), v)) : null;
      final src = nested ?? user;
      final prefs = await SharedPreferences.getInstance();
      final mobile = (src['mobile_number'] ?? src['mobile'] ?? src['phone'])?.toString();
      if (mobile != null && mobile.trim().isNotEmpty && mobile.trim() != 'null') {
        await prefs.setString('user_mobile', mobile.trim());
        _userMobile = mobile.trim();
      }
      final b = src['barangay'];
      String? bName;
      if (b is Map) bName = b['name']?.toString();
      else if (b != null) bName = b.toString();
      if (bName != null && bName.isNotEmpty && bName != 'null') {
        await prefs.setString('user_barangay', bName);
        _userBarangay = bName;
      }
      // Extract barangay id (integer) for dropdown matching
      if (b is Map) {
        final bId = b['id'];
        final parsedId = bId is int ? bId : int.tryParse(bId?.toString() ?? '');
        if (parsedId != null) {
          await prefs.setInt('user_barangay_id', parsedId);
          _userBarangayId = parsedId;
        }
      }
      final name = src['name']?.toString();
      if (name != null && name.isNotEmpty) {
        await prefs.setString('user_name', name);
        _userName = name;
      }
      final email = src['email']?.toString();
      if (email != null && email.isNotEmpty) {
        await prefs.setString('user_email', email);
        _userEmail = email;
      }
      final rawAvatar = (src['profile_photo_url'] ?? src['avatar_url'])?.toString();
      if (rawAvatar != null && rawAvatar.isNotEmpty) {
        final avatar = AppConstants.getPhotoUrl(rawAvatar);
        await prefs.setString('user_avatar', avatar);
        _userAvatar = avatar;
      }
      // Extract worker_profile.id for worker-authenticated endpoints
      final wp = src['worker_profile'];
      if (wp is Map) {
        final wpId = wp['id'];
        final wpIdStr = wpId?.toString();
        if (wpIdStr != null && wpIdStr.isNotEmpty && wpIdStr != 'null') {
          await prefs.setString('worker_profile_id', wpIdStr);
          _workerProfileId = wpIdStr;
        }
      }
      final role = src['role']?.toString();
      if (role != null && role.isNotEmpty && role != 'null') {
        await prefs.setString('user_role', role);
        _userRole = role;
      }
      notifyListeners();
    } catch (_) {}
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
      final userData = result.data?['user'] as Map<String, dynamic>?;
      final token = result.data?['token']?.toString() ?? '';
      if (token.isNotEmpty) {
        final bar = userData?['barangay'];
        final barIdRaw = bar is Map ? bar['id'] : null;
        final barId = barIdRaw is int ? barIdRaw : int.tryParse(barIdRaw?.toString() ?? '');
        await setAuthenticated(
          token,
          (userData?['role']?.toString() ?? 'client'),
          id: userData?['id']?.toString(),
          email: (userData?['email']?.toString() ?? email),
          name: userData?['name']?.toString(),
          mobile: (userData?['mobile_number'] ?? userData?['mobile'] ?? userData?['phone'])?.toString(),
          barangay: bar is Map ? (bar['name']?.toString()) : bar?.toString(),
          barangayId: barId,
          avatar: (userData?['profile_photo_url'] ?? userData?['avatar_url'])?.toString(),
          method: (userData?['is_google_account'] == true ? 'google' : 'email'),
        );
        if (_userMobile == null || _userMobile!.isEmpty) {
          await refreshProfile();
        }
      }
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
      final token = result.data?['token']?.toString() ?? '';
      if (token.isNotEmpty) {
        String? barangayName;
        int? barangayId;
        final b = userData?['barangay'];
        if (b is Map) {
          barangayName = b['name']?.toString();
          final bId = b['id'];
          barangayId = bId is int ? bId : int.tryParse(bId?.toString() ?? '');
        }
        final avatarUrl = (userData?['profile_photo_url'] ?? userData?['avatar_url'])?.toString();
        final isGoogle = userData?['is_google_account'] == true;
        await setAuthenticated(token, (userData?['role']?.toString() ?? 'client'), id: userData?['id']?.toString(), email: (userData?['email']?.toString() ?? email), name: userData?['name']?.toString(), mobile: (userData?['mobile_number'] ?? userData?['mobile'] ?? userData?['phone'])?.toString(), barangay: barangayName, barangayId: barangayId, avatar: avatarUrl, method: isGoogle ? 'google' : 'email');
        if (_userMobile == null || _userMobile!.isEmpty) {
          await refreshProfile();
        }
      }
    }
    return result;
  }

  Future<AuthResult> googleLogin({String? roleForNewUser, bool forceAccountPicker = true}) async {
    final account = await GoogleAuthService().signIn(forceAccountPicker: forceAccountPicker);
    if (account == null) return AuthResult.failure(message: 'Google sign-in cancelled.');
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) return AuthResult.failure(message: 'Failed to get Google ID token.');
    AuthResult result;
    if (_authRepository is ApiAuthRepository) {
      result = await (_authRepository as ApiAuthRepository).googleAuth(googleToken: idToken, role: roleForNewUser);
    } else {
      result = AuthResult.success(message: 'Google sign-in (mock)', data: {'token': 'mock_google_token', 'is_new_user': true, 'user': {'email': account.email, 'name': account.displayName ?? account.email}});
    }
    if (result.success) {
      final data = result.data ?? {};
      final token = data['token']?.toString() ?? '';
      final userRaw = data['user'];
      final user = userRaw is Map ? userRaw.map((k, v) => MapEntry(k.toString(), v)) : <String, dynamic>{};
      final isNew = data['is_new_user'] == true;
      // Don't default role for new users — backend returns role=null and Flutter must go through CompleteProfile
      String role = user['role']?.toString() ?? '';
      if (role.isEmpty) {
        if (!isNew && roleForNewUser != null) role = roleForNewUser;
        else if (!isNew) role = 'client';
        else role = roleForNewUser ?? '';
      }
      if (token.isNotEmpty) {
        final avatarUrl = (user['profile_photo_url'] ?? user['avatar_url'])?.toString();
        // For new users with no role yet, keep role empty so getHomeRoute isn't confused; complete-profile will set it
        final storedRole = role.isEmpty ? '' : role;
        await setAuthenticated(token, storedRole, id: user['id']?.toString(), email: (user['email']?.toString() ?? account.email), name: (user['name']?.toString() ?? account.displayName), avatar: avatarUrl, method: 'google');
        // Preserve raw role for caller by keeping it in result data; ensure is_new_user survives setAuthenticated
      }
    }
    return result;
  }

  Future<AuthResult> completeGoogleProfile({required String name, required String mobileNumber, required String role, required String barangay, String? avatarPath}) async {
    if (_authRepository is ApiAuthRepository) {
      final r = await (_authRepository as ApiAuthRepository).completeGoogleProfile(name: name, mobileNumber: mobileNumber, role: role, barangay: barangay, avatarPath: avatarPath);
      if (r.success) {
        final userRaw = r.data?['user'];
        final user = userRaw is Map ? userRaw.map((k, v) => MapEntry(k.toString(), v)) : null;
        await updateLocalProfile(name: user?['name']?.toString() ?? name, mobile: user?['mobile_number']?.toString() ?? mobileNumber, avatar: (user?['profile_photo_url'] ?? avatarPath)?.toString());
        final prefs = await SharedPreferences.getInstance();
        final newRole = user?['role']?.toString() ?? role;
        await prefs.setString('user_role', newRole); _userRole = newRole;
        final b2 = user?['barangay'];
        String? barangayName2;
        if (b2 is Map) barangayName2 = b2['name']?.toString(); else if (b2 != null) barangayName2 = b2.toString();
        if (barangayName2 != null) { await prefs.setString('user_barangay', barangayName2); _userBarangay = barangayName2; }
        if (b2 is Map) {
          final b2Id = b2['id'];
          final parsedB2Id = b2Id is int ? b2Id : int.tryParse(b2Id?.toString() ?? '');
          if (parsedB2Id != null) { await prefs.setInt('user_barangay_id', parsedB2Id); _userBarangayId = parsedB2Id; }
        }
        notifyListeners();
      }
      return r;
    }
    return await _authRepository.updateProfile(name: name, mobileNumber: mobileNumber, avatarPath: avatarPath);
  }

  Future<void> setAuthenticated(String token, String role, {
    String? id, 
    String? email, 
    String? name, 
    String? mobile, 
    String? barangay,
    int? barangayId,
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
      final v = mobile.trim();
      if (v.isNotEmpty && v != 'null') {
        await prefs.setString('user_mobile', v);
        _userMobile = v;
      }
    }
    if (barangay != null) {
      await prefs.setString('user_barangay', barangay);
      _userBarangay = barangay;
    }
    if (barangayId != null) {
      await prefs.setInt('user_barangay_id', barangayId);
      _userBarangayId = barangayId;
    }
    if (avatar != null) {
      await prefs.setString('user_avatar', avatar);
      _userAvatar = avatar;
    }

    _isAuthenticated = true;
    notifyListeners();
  }

  Future<AuthResult> updateProfile({required String name, required String mobileNumber, int? barangayId, String? barangayName, String? avatarPath}) async {
    final result = await _authRepository.updateProfile(name: name, mobileNumber: mobileNumber, barangayId: barangayId, avatarPath: avatarPath);
    if (result.success) {
      await updateLocalProfile(name: name, mobile: mobileNumber, barangayId: barangayId, barangayName: barangayName, avatar: avatarPath);
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

  Future<void> updateLocalProfile({required String name, required String mobile, int? barangayId, String? barangayName, String? avatar}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    _userName = name;
    await prefs.setString('user_mobile', mobile);
    _userMobile = mobile;
    if (barangayId != null) {
      await prefs.setInt('user_barangay_id', barangayId);
      _userBarangayId = barangayId;
    }
    if (barangayName != null) {
      await prefs.setString('user_barangay', barangayName);
      _userBarangay = barangayName;
    }
    if (avatar != null) {
      await prefs.setString('user_avatar', avatar);
      _userAvatar = avatar;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    // Best-effort server logout
    try { await ApiClient.post('/auth/logout', requiresAuth: true); } catch (_) {}
    if (_signInMethod == 'google') {
      try { await GoogleAuthService().signOut(); } catch (_) {}
    }
    await _storage.deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('user_mobile');
    await prefs.remove('user_avatar');
    await prefs.remove('user_barangay');
    await prefs.remove('user_barangay_id');
    await prefs.remove('sign_in_method');
    await prefs.remove('worker_profile_id');
    _isAuthenticated = false;
    _userId = null; _userEmail = null; _userRole = null; _userName = null; _userMobile = null; _userBarangay = null; _userBarangayId = null; _userAvatar = null; _signInMethod = null; _workerProfileId = null;
    notifyListeners();
  }
}
