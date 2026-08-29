enum NotificationType {
  bookingAccepted,
  bookingUpdated,
  bookingCompleted,
  newChatMessage,
  verificationApproved,
  newRatingReceived,
  system
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? relatedId; // bookingId, conversationId, etc.
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      relatedId: relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

class NotificationPreferences {
  final bool bookingUpdates;
  final bool messages;
  final bool promotions;
  final bool pushEnabled;
  final bool emailEnabled;

  NotificationPreferences({
    this.bookingUpdates = true,
    this.messages = true,
    this.promotions = false,
    this.pushEnabled = true,
    this.emailEnabled = true,
  });

  NotificationPreferences copyWith({
    bool? bookingUpdates,
    bool? messages,
    bool? promotions,
    bool? pushEnabled,
    bool? emailEnabled,
  }) {
    return NotificationPreferences(
      bookingUpdates: bookingUpdates ?? this.bookingUpdates,
      messages: messages ?? this.messages,
      promotions: promotions ?? this.promotions,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
    );
  }
}
