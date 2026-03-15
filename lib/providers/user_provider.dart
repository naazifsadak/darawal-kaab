import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/user_model.dart';
import '../services/auth_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  supabase.User? _currentUser;

  String _name = "Driver User";
  String _bio =
      "Road safety enthusiast.\nReporting accidents and traffic updates.";
  String _email = "driver@example.com";
  String _phone = "+252 61 5000000";
  String _profileImage =
      "https://ui-avatars.com/api/?name=Driver+User&background=random";
  File? _profileImageFile;
  int _followers = 0;
  int _following = 0;
  int _postsCount = 0;
  bool _hideFollowersFollowing = false;

  UserProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((data) {
      // final event = data.event;
      final session = data.session;

      _currentUser = session?.user;

      if (_currentUser != null) {
        _email = _currentUser!.email ?? "";
        _name = _currentUser!.userMetadata?['display_name'] ?? "Driver User";
        _phone = _currentUser!.userMetadata?['phone'] ?? "+252 61 5000000";
        // Set initial avatar based on name
        if (!_profileImage.startsWith('http') &&
            _profileImage.contains('assets')) {
          _profileImage =
              "https://ui-avatars.com/api/?name=${Uri.encodeComponent(_name)}&background=random";
        }
        _fetchProfile(); // Fetch real data
      } else {
        clearUserData();
      }
      notifyListeners();
    });
  }

  Future<void> _fetchProfile() async {
    if (_currentUser == null) return;
    try {
      debugPrint("Fetching profile for user: ${_currentUser!.id}");
      final data = await supabase.Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', _currentUser!.id)
          .maybeSingle();

      debugPrint("Profile Fetch Result: $data");

      if (data != null) {
        _name = data['name'] ?? _name;
        _bio = data['bio'] ?? _bio;
        // _profileImage = data['profile_image'] ?? _profileImage; // Keep local if null, or handle logic
        if (data['profile_image'] != null) {
          _profileImage = data['profile_image'];
          debugPrint("Profile Image loaded from DB: $_profileImage");
        } else {
          debugPrint(
            "Profile Image is NULL in DB, keeping current: $_profileImage",
          );
        }
        _followers = data['followers_count'] ?? 0;
        _following = data['following_count'] ?? 0;
        _postsCount = data['posts_count'] ?? 0;
        _hideFollowersFollowing = data['hide_followers_following'] ?? false;
        notifyListeners();
      } else {
        debugPrint("No profile found for user (data is null)");
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  String get name => _name;
  String get bio => _bio;
  String get email => _email;
  String get phone => _phone;
  String get profileImage => _profileImage;
  File? get profileImageFile => _profileImageFile;
  bool get isAuthenticated => _currentUser != null;
  int get followers => _followers;
  int get following => _following;
  int get postsCount => _postsCount;
  bool get hideFollowersFollowing => _hideFollowersFollowing;

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
      id: _currentUser?.id ?? 'guest',
      name: _name,
      profileImage: _profileImageFile != null
          ? _profileImageFile!.path
          : _profileImage,
      bio: _bio,
      followers: _followers,
      following: _following,
      postsCount: _postsCount,
      hideFollowersFollowing: _hideFollowersFollowing,
    );
  }

  Future<void> updateUser({
    required String name,
    required String bio,
    required String email,
    required String phone,
  }) async {
    _name = name;
    _bio = bio;
    _email = email;
    _phone = phone;
    notifyListeners();

    if (_currentUser == null) return;

    try {
      String? imageUrl;
      if (_profileImageFile != null) {
        // Upload image if a new file is selected
        final fileName =
            '${_currentUser!.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.Supabase.instance.client.storage
            .from('avatars') // Ensure this bucket exists or use 'post-media'
            .upload(fileName, _profileImageFile!);
        imageUrl = supabase.Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl(fileName);
        _profileImage = imageUrl;
        _profileImageFile = null; // Clear local file after upload
      }

      final updates = {
        'name': name,
        'bio': bio,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (imageUrl != null) {
        updates['profile_image'] = imageUrl;
      }

      updates['id'] = _currentUser!.id; // Ensure ID is present for upsert
      debugPrint("Attempting to UPSERT profile with updates: $updates");

      final response = await supabase.Supabase.instance.client
          .from('profiles')
          .upsert(updates)
          .select();

      debugPrint("UPSERT Success. Response: $response");

      notifyListeners();
    } catch (e) {
      debugPrint("Error updating profile (UPSERT failed): $e");
      // Optionally create a method to set error state
    }
  }

  Future<void> toggleHideFollowersFollowing(bool value) async {
    _hideFollowersFollowing = value;
    notifyListeners();

    if (_currentUser == null) return;
    try {
      await supabase.Supabase.instance.client
          .from('profiles')
          .update({'hide_followers_following': value})
          .eq('id', _currentUser!.id);
      debugPrint("hide_followers_following updated in DB: $value");
    } catch (e) {
      debugPrint("Error updating hide_followers_following: $e");
    }
  }

  void incrementPostsCount() {
    _postsCount++;
    notifyListeners();
  }

  void decrementPostsCount() {
    if (_postsCount > 0) {
      _postsCount--;
      notifyListeners();
    }
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
    _followers = 0;
    _following = 0;
    _postsCount = 0;
    _hideFollowersFollowing = false;
    _currentUser = null; // Explicitly clear current user
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
