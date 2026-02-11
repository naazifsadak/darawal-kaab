import 'dart:io';
import 'package:flutter/material.dart';

class User {
  final String id;
  final String name;
  final String profileImage;
  final String bio;
  final int followers;
  final int following;
  final int postsCount;
  bool isFollowing;

  User({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.bio,
    required this.followers,
    required this.following,
    required this.postsCount,
    this.isFollowing = false,
  });

  ImageProvider get imageProvider {
    if (profileImage.startsWith('http')) {
      return NetworkImage(profileImage);
    } else if (File(profileImage).existsSync()) {
      return FileImage(File(profileImage));
    } else {
      return AssetImage(profileImage);
    }
  }
}
