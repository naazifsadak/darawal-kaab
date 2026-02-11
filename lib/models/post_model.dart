import 'package:flutter/material.dart';
import 'user_model.dart';
import 'comment_model.dart';

class Post {
  final String id;
  final String roadName;
  final String description;
  final String timeAgo;
  final User author;
  final Color color;
  int likes;
  List<Comment> comments;
  bool isLiked;
  String? videoUrl;
  String? imageUrl;

  Post({
    required this.id,
    required this.roadName,
    required this.description,
    required this.timeAgo,
    required this.author,
    required this.color,
    required this.likes,
    required this.comments,
    this.isLiked = false,
    this.videoUrl,
    this.imageUrl,
  });

  int get commentsCount =>
      comments.length + comments.fold(0, (prev, c) => prev + c.replies.length);
}
