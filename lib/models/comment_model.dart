import 'user_model.dart';

class Comment {
  final String id;
  String text;
  int likes;
  bool isLiked;
  final User author;
  final DateTime timestamp;
  final List<Comment> replies;
  bool isRepliesExpanded; // UI state for collapsing/expanding replies

  Comment({
    required this.id,
    required this.text,
    required this.author,
    required this.timestamp,
    this.likes = 0,
    this.isLiked = false,
    List<Comment>? replies,
    this.isRepliesExpanded = false,
  }) : replies = replies ?? [];
}
