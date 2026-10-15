import 'dart:async';
import 'package:flutter/widgets.dart';
import '../core/api/api_client.dart';
import 'secure_storage_service.dart';

class PresenceService with WidgetsBindingObserver {
  Timer? _timer;
  final _storage = SecureStorageService();

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _sendHeartbeat();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _sendHeartbeat());
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sendHeartbeat();
  }

  Future<void> _sendHeartbeat() async {
    // The app starts before login; do not make an authenticated request until
    // a token exists, otherwise the global 401 handler would clear the session.
    if (await _storage.getToken() == null) return;
    await ApiClient.post('/presence/heartbeat', requiresAuth: true);
  }
}