import 'package:flutter/material.dart';

import 'dart:async';

import '../data/models/chat_model.dart';
import '../data/repositories/chat_repository.dart';
import '../services/fcm_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _repository;
  final bool Function()? isAuthenticated;
  final Stream<void> _notificationEvents;
  late final StreamSubscription<void> _notificationSubscription;
  int _unreadCount = 0;
  Future<void>? _unreadCountRefresh;

  ChatProvider(
    this._repository, {
    this.isAuthenticated,
    Stream<void>? notificationEvents,
  }) : _notificationEvents =
           notificationEvents ?? FcmService.onNotificationReceived {
    _notificationSubscription = _notificationEvents.listen((_) {
      unawaited(refreshUnreadCount());
    });
  }

  Future<List<Conversation>> getConversations() async {
    final conversations = await _repository.getConversations();
    _publishUnreadCount(conversations);
    return conversations;
  }

  Future<List<Message>> getMessages(String conversationId) =>
      _repository.getMessages(conversationId);

  Future<String> resolveConversationId({
    required String otherUserId,
    required String fallbackBookingId,
  }) async {
    final conversations = await getConversations();
    for (final conversation in conversations) {
      if (conversation.otherUserId == otherUserId) {
        return conversation.id;
      }
    }
    return fallbackBookingId;
  }

  Future<Message> sendMessage(
    String conversationId, {
    String? senderId,
    String? text,
    String? imageUrl,
  }) async {
    final message = await _repository.sendMessage(
      conversationId,
      senderId: senderId,
      text: text,
      imageUrl: imageUrl,
    );
    notifyListeners();
    return message;
  }

  Future<void> markAsRead(String conversationId) async {
    await _repository.markAsRead(conversationId);
    await refreshUnreadCount();
    notifyListeners();
  }

  Future<void> clearMessages(String conversationId) async {
    await _repository.clearMessages(conversationId);
    notifyListeners();
  }

  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();

  int get unreadCount => _unreadCount;

  Stream<int> getUnreadCount() => _unreadCountController.stream;

  Future<void> refreshUnreadCount() {
    if (isAuthenticated?.call() == false) return Future.value();
    final currentRefresh = _unreadCountRefresh;
    if (currentRefresh != null) return currentRefresh;

    final refresh = _loadUnreadCount();
    _unreadCountRefresh = refresh;
    return refresh.whenComplete(() {
      if (identical(_unreadCountRefresh, refresh)) {
        _unreadCountRefresh = null;
      }
    });
  }

  Future<void> _loadUnreadCount() async {
    try {
      await getConversations();
    } catch (error, stackTrace) {
      debugPrint(
        '[ChatProvider] Failed to refresh unread message count: '
        '$error\n$stackTrace',
      );
    }
  }

  void _publishUnreadCount(List<Conversation> conversations) {
    _unreadCount = conversations
        .where((conversation) => conversation.isUnread)
        .length;
    _unreadCountController.add(_unreadCount);
  }

  @override
  void dispose() {
    unawaited(_notificationSubscription.cancel());
    _unreadCountController.close();
    super.dispose();
  }
}
