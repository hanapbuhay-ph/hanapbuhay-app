class Conversation {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String otherUserRole;
  final String otherUserAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool isUnread;
  final String? bookingId;
  final bool isOnline;
  final bool isSupport;

  Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
    required this.otherUserAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.isUnread = false,
    this.bookingId,
    this.isOnline = false,
    this.isSupport = false,
  });
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String? text;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.text,
    this.imageUrl,
    required this.timestamp,
    this.isRead = false,
  });
}
