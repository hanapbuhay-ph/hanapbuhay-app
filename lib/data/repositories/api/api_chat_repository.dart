import '../../models/chat_model.dart';
import '../chat_repository.dart';

class ApiChatRepository implements ChatRepository {
  @override
  Future<List<Conversation>> getConversations() async {
    // TODO: GET /api/conversations
    throw UnimplementedError();
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    // TODO: GET /api/conversations/{id}/messages
    throw UnimplementedError();
  }

  @override
  Future<void> sendMessage(String conversationId, String senderId, {String? text, String? imageUrl}) async {
    // TODO: POST /api/messages (and notify via WebSocket)
    throw UnimplementedError();
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    // TODO: POST /api/conversations/{id}/read
    throw UnimplementedError();
  }

  @override
  Future<void> clearMessages(String conversationId) async {
    // TODO: DELETE /api/conversations/{id}/messages
    throw UnimplementedError();
  }
}
