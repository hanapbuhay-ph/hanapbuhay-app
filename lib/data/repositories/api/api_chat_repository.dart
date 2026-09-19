import '../../models/chat_model.dart';
import '../chat_repository.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';

/// API-connected ChatRepository — Section I of 07_API_ENDPOINTS.md
class ApiChatRepository implements ChatRepository {
  @override
  Future<List<Conversation>> getConversations() async {
    try {
      final res = await ApiClient.get('/messages', requiresAuth: true);
      
      if (res['success'] != true) {
        print('[ApiChatRepository] getConversations failed: ${res['message']}');
        return [];
      }

      final data = res['data'];
      if (data == null) return [];

      final conversationsData = data['conversations'] ?? data;
      if (conversationsData is! List) return [];

      final conversations = conversationsData.map((item) {
        return _parseConversation(item);
      }).whereType<Conversation>().toList();

      return conversations;
    } catch (e) {
      print('[ApiChatRepository] getConversations error: $e');
      return [];
    }
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    try {
      // API expects bookingId for chat thread: GET /api/messages/{bookingId}
      final res = await ApiClient.get('/messages/$conversationId', requiresAuth: true);
      
      if (res['success'] != true) {
        print('[ApiChatRepository] getMessages failed: ${res['message']}');
        return [];
      }

      final data = res['data'];
      if (data == null) return [];

      final messagesData = data['messages'] ?? data;
      if (messagesData is! List) return [];

      final messages = messagesData.map((item) {
        return _parseMessage(item, conversationId);
      }).whereType<Message>().toList();

      return messages;
    } catch (e) {
      print('[ApiChatRepository] getMessages error: $e');
      return [];
    }
  }

  @override
  Future<void> sendMessage(String conversationId, {String? senderId, String? text, String? imageUrl}) async {
    try {
      // API: POST /api/messages/{bookingId}
      // Always uses multipart/form-data
      // IMPORTANT: Backend expects 'message' field (not 'content' as in docs)
      // See: MessageController.php line 140 → $request->input('message')
      
      final fields = <String, String>{};
      if (text != null && text.isNotEmpty) {
        fields['message'] = text;  // ← Backend expects 'message', not 'content'
      }

      Map<String, List<String>>? files;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        files = <String, List<String>>{'attachment': [imageUrl]};
      }

      final res = await ApiClient.postMultipart(
        '/messages/$conversationId',
        fields: fields,
        files: files,
        requiresAuth: true,
      );

      if (res['success'] != true) {
        print('[ApiChatRepository] sendMessage failed: ${res['message']}');
      }
    } catch (e) {
      print('[ApiChatRepository] sendMessage error: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    try {
      // Note: The API doesn't have a mark-as-read endpoint for messages
      // Messages are automatically marked as read when fetched
      // This is a no-op for now
      print('[ApiChatRepository] markAsRead: No backend endpoint available');
    } catch (e) {
      print('[ApiChatRepository] markAsRead error: $e');
    }
  }

  @override
  Future<void> clearMessages(String conversationId) async {
    try {
      // Note: The API doesn't have a clear messages endpoint
      // This would require backend implementation
      print('[ApiChatRepository] clearMessages: No backend endpoint available');
    } catch (e) {
      print('[ApiChatRepository] clearMessages error: $e');
    }
  }

  /// Parse conversation from API response
  Conversation? _parseConversation(dynamic item) {
    try {
      if (item is! Map) return null;

      final bookingId = item['booking_id']?.toString();
      final otherParty = item['other_party'];

      if (bookingId == null || bookingId.isEmpty) {
        return null;
      }

      final otherPartyMap = otherParty is Map ? otherParty : const <String, dynamic>{};
      final otherUserId = otherPartyMap['id']?.toString() ?? '';
      final otherUserName = otherPartyMap['name']?.toString() ?? 'User';
      final otherUserRole = otherPartyMap['role']?.toString();
      final rawAvatar = otherPartyMap['profile_photo_url']?.toString() ?? otherPartyMap['profile_photo']?.toString() ?? otherPartyMap['avatar']?.toString();
      final otherUserAvatar = (rawAvatar != null && rawAvatar.isNotEmpty)
          ? AppConstants.getPhotoUrl(rawAvatar)
          : null;
      
      final lastMessage = item['last_message']?.toString() ?? '';
      final lastMessageTimeStr = item['last_message_at']?.toString();
      final unreadCount = (item['unread_count'] as num?)?.toInt() ?? 0;
      final isOnline = otherPartyMap['is_online'] == true;
      final availabilityStatus = otherPartyMap['availability_status']?.toString();

      final lastMessageTime = lastMessageTimeStr != null
          ? DateTime.tryParse(lastMessageTimeStr) ?? DateTime.now()
          : DateTime.now();

      return Conversation(
        id: bookingId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        otherUserRole: otherUserRole ?? 'User',
        otherUserAvatar: otherUserAvatar ?? 'https://i.pravatar.cc/150?u=$otherUserId',
        lastMessage: lastMessage,
        lastMessageTime: lastMessageTime,
        isUnread: unreadCount > 0,
        bookingId: bookingId,
        isOnline: isOnline,
        availabilityStatus: availabilityStatus,
        isSupport: false,
      );
    } catch (e) {
      print('[ApiChatRepository] _parseConversation error: $e');
      return null;
    }
  }

  /// Parse message from API response
  Message? _parseMessage(dynamic item, String conversationId) {
    try {
      if (item is! Map) return null;

      final id = item['id']?.toString();
      final senderId = item['sender_id']?.toString();
      final content = item['content']?.toString() ?? item['message']?.toString();
      final attachmentUrl = item['attachment_url']?.toString();
      final createdAtStr = item['created_at']?.toString();
      final isRead = item['is_read'] == true || item['read_at'] != null;

      if (id == null || senderId == null) {
        return null;
      }

      final timestamp = createdAtStr != null
          ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
          : DateTime.now();

      return Message(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        text: content,
        imageUrl: attachmentUrl,
        timestamp: timestamp,
        isRead: isRead,
      );
    } catch (e) {
      print('[ApiChatRepository] _parseMessage error: $e');
      return null;
    }
  }
}
