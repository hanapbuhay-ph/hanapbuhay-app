import '../../models/chat_model.dart';
import '../chat_repository.dart';

class MockChatRepository implements ChatRepository {
  final List<Conversation> _mockConversations = [
    Conversation(
      id: 'c1',
      otherUserId: 'w1',
      otherUserName: 'Mang Jun',
      otherUserRole: 'Carpenter',
      otherUserAvatar: 'https://i.pravatar.cc/150?u=w1',
      lastMessage: 'I will be there at 9 AM tomorrow.',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 2)),
      isUnread: true,
      bookingId: 'HB-2026-00001',
      isOnline: true,
    ),
    Conversation(
      id: 'c2',
      otherUserId: 'support',
      otherUserName: 'HanapBuhay Support',
      otherUserRole: 'System',
      otherUserAvatar: '',
      lastMessage: 'Your report has been received.',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
      isSupport: true,
    ),
    Conversation(
      id: 'c3',
      otherUserId: 'w2',
      otherUserName: 'Maria Santos',
      otherUserRole: 'Electrician',
      otherUserAvatar: 'https://i.pravatar.cc/150?u=w2',
      lastMessage: 'Please send a photo of the breaker.',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      bookingId: 'HB-2026-00002',
    ),
    Conversation(
      id: 'c4',
      otherUserId: 'u1',
      otherUserName: 'Juan Dela Cruz',
      otherUserRole: 'Client',
      otherUserAvatar: 'https://i.pravatar.cc/150?u=u1',
      lastMessage: 'Is the price negotiable?',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 3)),
      bookingId: 'HB-2026-00004',
    ),
  ];

  final Map<String, List<Message>> _mockMessages = {
    'c1': [
      Message(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'w1',
        text: 'Hello! I received your booking request.',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: true,
      ),
      Message(
        id: 'm2',
        conversationId: 'c1',
        senderId: 'current_user',
        text: 'Great. What time can you come?',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        isRead: true,
      ),
      Message(
        id: 'm3',
        conversationId: 'c1',
        senderId: 'w1',
        text: 'I will be there at 9 AM tomorrow.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ],
    'c2': [
      Message(
        id: 'ms1',
        conversationId: 'c2',
        senderId: 'support',
        text: 'Welcome to HanapBuhay Support. How can we help you today?',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ],
  };

  @override
  Future<List<Conversation>> getConversations() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockConversations;
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockMessages[conversationId] ?? [];
  }

  @override
  Future<void> sendMessage(String conversationId, String senderId, {String? text, String? imageUrl}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: conversationId,
      senderId: senderId,
      text: text,
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
    );
    
    if (!_mockMessages.containsKey(conversationId)) {
      _mockMessages[conversationId] = [];
    }
    _mockMessages[conversationId]!.add(newMessage);

    // Update last message in conversation
    final index = _mockConversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final old = _mockConversations[index];
      _mockConversations[index] = Conversation(
        id: old.id,
        otherUserId: old.otherUserId,
        otherUserName: old.otherUserName,
        otherUserRole: old.otherUserRole,
        otherUserAvatar: old.otherUserAvatar,
        lastMessage: text ?? 'Image attachment',
        lastMessageTime: DateTime.now(),
        isUnread: false,
        bookingId: old.bookingId,
        isOnline: old.isOnline,
        isSupport: old.isSupport,
      );
    }
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    final index = _mockConversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final old = _mockConversations[index];
      _mockConversations[index] = Conversation(
        id: old.id,
        otherUserId: old.otherUserId,
        otherUserName: old.otherUserName,
        otherUserRole: old.otherUserRole,
        otherUserAvatar: old.otherUserAvatar,
        lastMessage: old.lastMessage,
        lastMessageTime: old.lastMessageTime,
        isUnread: false,
        bookingId: old.bookingId,
        isOnline: old.isOnline,
        isSupport: old.isSupport,
      );
    }
  }

  @override
  Future<void> clearMessages(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockMessages[conversationId] = [];
    
    // Update last message in conversation
    final index = _mockConversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final old = _mockConversations[index];
      _mockConversations[index] = Conversation(
        id: old.id,
        otherUserId: old.otherUserId,
        otherUserName: old.otherUserName,
        otherUserRole: old.otherUserRole,
        otherUserAvatar: old.otherUserAvatar,
        lastMessage: 'Conversation cleared',
        lastMessageTime: DateTime.now(),
        isUnread: false,
        bookingId: old.bookingId,
        isOnline: old.isOnline,
        isSupport: old.isSupport,
      );
    }
  }
}
