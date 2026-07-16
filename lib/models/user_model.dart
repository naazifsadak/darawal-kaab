import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class User {
  final String id;
  final String name;
  final String profileImage;
  final String bio;
  int followers;
  int following;
  int postsCount;
  bool isFollowing;

  final bool isAdmin;
  final String status;

  User({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.bio,
    required this.followers,
    required this.following,
    required this.postsCount,
    this.isFollowing = false,
    this.isAdmin = false,
    this.status = 'active',
  });

  ImageProvider get imageProvider {
    if (profileImage.startsWith('http')) {
      return NetworkImage(profileImage);
    } else if (profileImage.isNotEmpty && !kIsWeb && File(profileImage).existsSync()) {
      return FileImage(File(profileImage));
    } else {
      return AssetImage(profileImage.isNotEmpty ? profileImage : 'assets/images/placeholder.png');
    }
  }
}
