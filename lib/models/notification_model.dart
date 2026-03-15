import 'user_model.dart';
import 'post_model.dart';

enum NotificationType { like, comment, follow }

class NotificationItem {
  final String id;
  final User sender;
  final NotificationType type;
  final Post? post; // Nullable for follow notifications
  final DateTime createdAt;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.sender,
    required this.type,
    this.post,
    required this.createdAt,
    this.isRead = false,
  });

  static NotificationType _parseType(String typeStr) {
    switch (typeStr) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      default:
        throw Exception("Unknown notification type: $typeStr");
    }
  }

  factory NotificationItem.fromJson(
    Map<String, dynamic> json,
    User sender, {
    Post? post,
  }) {
    return NotificationItem(
      id: json['id'].toString(),
      sender: sender,
      type: _parseType(json['type']),
      post: post,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      isRead: json['is_read'] ?? false,
    );
  }
}
