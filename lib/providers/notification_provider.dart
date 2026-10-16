import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repositories/notification_repository.dart';
import '../data/repositories/api/api_notification_repository.dart';
import '../data/models/notification_model.dart';
import '../services/fcm_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;
  final bool Function()? isAuthenticated;
  late final StreamSubscription<void> _notificationSubscription;
  Future<List<AppNotification>>? _notificationsRequest;
  Future<void>? _initialUnreadCountLoad;

  NotificationProvider(this._repository, {this.isAuthenticated}) {
    _notificationSubscription = FcmService.onNotificationReceived.listen((_) {
      unawaited(refreshUnreadCount());
    });
  }

  Future<List<AppNotification>> getNotifications() {
    final existingRequest = _notificationsRequest;
    if (existingRequest != null) return existingRequest;

    final request = _repository.getNotifications();
    _notificationsRequest = request;
    request.then<void>(
      (_) => _clearNotificationsRequest(request),
      onError: (Object error, StackTrace stackTrace) =>
          _clearNotificationsRequest(request),
    );
    return request;
  }

  void _clearNotificationsRequest(Future<List<AppNotification>> request) {
    if (identical(_notificationsRequest, request)) {
      _notificationsRequest = null;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _repository.markAsRead(notificationId);
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    // Delegate to ApiNotificationRepository if available
    if (_repository case ApiNotificationRepository repo) {
      await repo.markAllAsRead();
    }
    notifyListeners();
  }

  Stream<int> getUnreadCount() {
    _initialUnreadCountLoad ??= _loadInitialUnreadCount();
    return _repository.getUnreadCount();
  }

  Future<void> refreshUnreadCount() async {
    if (isAuthenticated?.call() == false) return;
    try {
      await getNotifications();
    } catch (error, stackTrace) {
      debugPrint(
        '[NotificationProvider] Failed to refresh unread notification count: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<void> _loadInitialUnreadCount() async {
    await refreshUnreadCount();
  }

  Future<NotificationPreferences> getPreferences() =>
      _repository.getPreferences();

  Future<void> updatePreferences(NotificationPreferences preferences) async {
    await _repository.updatePreferences(preferences);
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_notificationSubscription.cancel());
    super.dispose();
  }
}
