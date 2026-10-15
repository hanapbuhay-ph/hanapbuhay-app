import 'package:google_sign_in/google_sign_in.dart';

/// Handles native Google Sign-In flow.
/// Use [signIn(forceAccountPicker: true)] on both login and registration role screens
/// to always show the account chooser (prevents auto-sign-in to last account).
class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Web client ID (client_type 3) from google-services.json — required to get idToken on Android.
    serverClientId: '416482556754-q1l1lbbs1u5bev0ob4q2k2t5klterlkg.apps.googleusercontent.com',
  );

  /// Sign in with Google.
  /// When [forceAccountPicker] is true, signs out any cached account first
  /// so the OS account chooser is always shown.
  Future<GoogleSignInAccount?> signIn({bool forceAccountPicker = false}) async {
    try {
      if (forceAccountPicker) {
        try { await _googleSignIn.signOut(); } catch (_) {}
      }
      final account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      // Surface as null — caller shows SnackBar with message
      // ignore: avoid_print
      print('[GoogleAuthService] signIn error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // ignore: avoid_print
      print('[GoogleAuthService] signOut error: $e');
    }
  }

  /// Fully revoke access — useful on logout for Google accounts
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      // ignore: avoid_print
      print('[GoogleAuthService] disconnect error: $e');
    }
  }
}
