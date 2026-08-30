import 'package:flutter/material.dart';
import '../data/repositories/notification_repository.dart';
import '../data/models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationProvider(this._repository);

  Future<List<AppNotification>> getNotifications() => _repository.getNotifications();
  
  Future<void> markAsRead(String notificationId) async {
    await _repository.markAsRead(notificationId);
    notifyListeners();
  }

  Stream<int> getUnreadCount() => _repository.getUnreadCount();

  Future<NotificationPreferences> getPreferences() => _repository.getPreferences();
  
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    await _repository.updatePreferences(preferences);
    notifyListeners();
  }
}
