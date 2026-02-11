import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  String _name = "Driver User";
  String _bio =
      "Road safety enthusiast.\nReporting accidents and traffic updates.";
  String _email = "driver@example.com";
  String _phone = "+252 61 5000000";
  String _profileImage = "assets/images/me.jpeg";
  File? _profileImageFile;

  String get name => _name;
  String get bio => _bio;
  String get email => _email;
  String get phone => _phone;
  String get profileImage => _profileImage;
  File? get profileImageFile => _profileImageFile;

  ImageProvider get imageProvider {
    if (_profileImageFile != null) {
      return FileImage(_profileImageFile!);
    } else if (_profileImage.startsWith('http')) {
      return NetworkImage(_profileImage);
    } else {
      return AssetImage(_profileImage);
    }
  }

  User get user {
    return User(
      id: 'current_user',
      name: _name,
      profileImage: _profileImageFile != null
          ? _profileImageFile!.path
          : _profileImage,
      bio: _bio,
      followers: 0,
      following: 0,
      postsCount: 0,
    );
  }

  void updateUser({
    required String name,
    required String bio,
    required String email,
    required String phone,
  }) {
    _name = name;
    _bio = bio;
    _email = email;
    _phone = phone;
    notifyListeners();
  }

  void updateProfileImage(String newImage) {
    _profileImage = newImage;
    _profileImageFile = null; // Reset local file if network image is set
    notifyListeners();
  }

  void setProfileImageFile(File image) {
    _profileImageFile = image;
    notifyListeners();
  }

  void clearUserData() {
    _name = "Driver User";
    _bio = "Road safety enthusiast.\nReporting accidents and traffic updates.";
    _email = "driver@example.com";
    _phone = "+252 61 5000000";
    _profileImage = "assets/images/me.jpeg";
    _profileImageFile = null;
    notifyListeners();
  }
}
