import '../models/chat_model.dart';

abstract class ChatRepository {
  Future<List<Conversation>> getConversations();
  Future<List<Message>> getMessages(String conversationId);
  Future<void> sendMessage(String conversationId, String senderId, {String? text, String? imageUrl});
  Future<void> markAsRead(String conversationId);
}
