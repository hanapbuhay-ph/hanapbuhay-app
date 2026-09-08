import '../../models/auth_result_model.dart';
import '../../models/barangay_model.dart';
import '../auth_repository.dart';
import '../../../core/api/api_client.dart';

/// API-connected AuthRepository — Section A. Aligned to 07_API_ENDPOINTS.md.
class ApiAuthRepository implements AuthRepository {
  String _barangayIdFor(String name) {
    final m = {for (final b in Barangay.trinidadBarangays) b.name.toLowerCase(): b.id};
    final found = m[name.toLowerCase()];
    if (found != null) { final n = int.tryParse(found.replaceAll(RegExp(r'[^0-9]'), '')); if (n != null) return n.toString(); }
    final idx = Barangay.trinidadBarangays.indexWhere((b) => b.name.toLowerCase() == name.toLowerCase());
    if (idx != -1) return (idx + 1).toString();
    return '13';
  }
  AuthResult _toResult(Map<String, dynamic> res) {
    final ok = res['success'] == true;
    if (ok) return AuthResult.success(message: res['message'] ?? 'Success', data: res['data'] is Map ? (res['data'] as Map).map((k,v)=> MapEntry(k.toString(), v)) : {'raw': res['data']});
    return AuthResult.failure(message: (res['message'] ?? 'Request failed').toString(), errors: res['errors'] is Map ? (res['errors'] as Map).map((k,v)=> MapEntry(k.toString(), v)) : null);
  }

  @override
  Future<AuthResult> register({required String name, required String email, required String password, required String role, required String mobileNumber, required String barangay}) async {
    final res = await ApiClient.post('/auth/register', body: {'name': name, 'email': email, 'password': password, 'password_confirmation': password, 'mobile_number': mobileNumber, 'role': role, 'barangay_id': int.tryParse(_barangayIdFor(barangay)) ?? 13});
    return _toResult(res);
  }

  @override
  Future<AuthResult> verifyOtp(String email, String otp) async {
    final res = await ApiClient.post('/auth/email/verify', body: {'email': email, 'code': otp});
    return _toResult(res);
  }

  Future<AuthResult> resendOtp(String email) async {
    final res = await ApiClient.post('/auth/email/resend-otp', body: {'email': email});
    return _toResult(res);
  }

  @override
  Future<AuthResult> login(String email, String password) async {
    final res = await ApiClient.post('/auth/login', body: {'email': email, 'password': password});
    return _toResult(res);
  }

  Future<AuthResult> googleAuth({required String googleToken, String? role}) async {
    final body = <String, dynamic>{'google_token': googleToken};
    if (role != null) body['role'] = role;
    final res = await ApiClient.post('/auth/google', body: body);
    return _toResult(res);
  }

  Future<AuthResult> completeGoogleProfile({required String name, required String mobileNumber, required String role, required String barangay, String? avatarPath}) async {
    final fields = <String, String>{'name': name, 'mobile_number': mobileNumber, 'role': role, 'barangay_id': _barangayIdFor(barangay)};
    final files = avatarPath != null ? <String, String>{'profile_photo': avatarPath} : null;
    final res = await ApiClient.postMultipart('/auth/google/complete-profile', fields: fields, files: files, requiresAuth: true);
    return _toResult(res);
  }

  @override
  Future<AuthResult> forgotPassword(String identifier) async {
    final res = await ApiClient.post('/auth/password/forgot', body: {'email': identifier});
    return _toResult(res);
  }

  @override
  Future<AuthResult> verifyForgotPasswordOtp(String identifier, String otp) async {
    final res = await ApiClient.post('/auth/password/verify-otp', body: {'email': identifier, 'code': otp});
    return _toResult(res);
  }

  @override
  Future<AuthResult> resetPassword(String identifier, String newPassword) async {
    final res = await ApiClient.post('/auth/password/reset', body: {'email': identifier, 'password': newPassword, 'password_confirmation': newPassword});
    return _toResult(res);
  }

  Future<AuthResult> resetPasswordWithToken({required String email, required String resetToken, required String newPassword}) async {
    final res = await ApiClient.post('/auth/password/reset', body: {'email': email, 'reset_token': resetToken, 'password': newPassword, 'password_confirmation': newPassword});
    return _toResult(res);
  }

  @override
  Future<AuthResult> changePassword({required String currentPassword, required String newPassword}) async {
    final res = await ApiClient.post('/user/password', body: {'current_password': currentPassword, 'password': newPassword, 'password_confirmation': newPassword}, requiresAuth: true);
    return _toResult(res);
  }

  @override
  Future<AuthResult> updateProfile({required String name, required String mobileNumber, String? barangay, String? avatarPath}) async {
    final fields = <String, String>{'name': name, 'mobile_number': mobileNumber};
    if (barangay != null) {
      fields['barangay_id'] = _barangayIdFor(barangay);
    }
    final files = avatarPath != null ? <String, String>{'profile_photo': avatarPath} : null;
    final res = await ApiClient.postMultipart('/user/profile', fields: fields, files: files, requiresAuth: true);
    return _toResult(res);
  }
}
