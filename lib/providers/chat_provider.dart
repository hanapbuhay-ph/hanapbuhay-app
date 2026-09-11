import 'package:flutter/material.dart';
import '../data/repositories/chat_repository.dart';
import '../data/models/chat_model.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _repository;

  ChatProvider(this._repository);

  Future<List<Conversation>> getConversations() => _repository.getConversations();
  Future<List<Message>> getMessages(String conversationId) => _repository.getMessages(conversationId);

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
  
  Future<void> sendMessage(String conversationId, {String? senderId, String? text, String? imageUrl}) async {
    await _repository.sendMessage(conversationId, senderId: senderId, text: text, imageUrl: imageUrl);
    notifyListeners();
  }

  Future<void> markAsRead(String conversationId) async {
    await _repository.markAsRead(conversationId);
    notifyListeners();
  }

  Future<void> clearMessages(String conversationId) async {
    await _repository.clearMessages(conversationId);
    notifyListeners();
  }
}
