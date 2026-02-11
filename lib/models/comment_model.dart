import 'user_model.dart';

class Comment {
  final String id;
  final String text;
  final User author;
  final DateTime timestamp;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.text,
    required this.author,
    required this.timestamp,
    List<Comment>? replies,
  }) : replies = replies ?? [];
}
