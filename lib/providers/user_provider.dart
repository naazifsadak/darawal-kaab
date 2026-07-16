import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  supabase.User? _currentUser;

  String _name = "User";
  String _bio = "";
  String _email = "";
  String _phone = "";
  String _profileImage =
      "https://ui-avatars.com/api/?name=User&background=random&size=512";
  File? _profileImageFile;
  int _followers = 0;
  int _following = 0;
  int _postsCount = 0;
  bool _isAdmin = false;
  String _status = "active";

  bool _needsPasswordReset = false;
  bool get needsPasswordReset => _needsPasswordReset;

  void setNeedsPasswordReset(bool value) {
    _needsPasswordReset = value;
    notifyListeners();
  }

  UserProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == supabase.AuthChangeEvent.passwordRecovery) {
        _needsPasswordReset = true;
      }

      _currentUser = session?.user;

      if (_currentUser != null) {
        _email = _currentUser!.email ?? "";
        _name = _currentUser!.userMetadata?['display_name'] ?? "User";
        _phone = _currentUser!.userMetadata?['phone'] ?? "";
        // Set initial avatar based on name
        if (!_profileImage.startsWith('http') ||
            _profileImage.contains('name=User')) {
          _profileImage =
              "https://ui-avatars.com/api/?name=${Uri.encodeComponent(_name)}&background=random&size=512";
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
        if (_postsCount < 0) _postsCount = 0;
        _isAdmin = data['is_admin'] ?? false;
        _status = data['status'] ?? 'active';

        // Fetch exact, real-time follower/following counts from follows table
        try {
          final followersList = await supabase.Supabase.instance.client
              .from('follows')
              .select('follower_id')
              .eq('following_id', _currentUser!.id);
          _followers = (followersList as List).length;

          final followingList = await supabase.Supabase.instance.client
              .from('follows')
              .select('following_id')
              .eq('follower_id', _currentUser!.id);
          _following = (followingList as List).length;
        } catch (e) {
          debugPrint("Error fetching real-time follower/following counts: $e");
        }

        notifyListeners();
      } else {
        debugPrint("No profile found for user (data is null)");
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  Future<void> refreshProfile() async {
    await _fetchProfile();
  }

  String get name => _name;
  String get bio => _bio;
  String get email => _email;
  String get phone => _phone;
  String get profileImage => _profileImage;
  File? get profileImageFile => _profileImageFile;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _isAdmin;
  String get status => _status;
  int get followers => _followers;
  int get following => _following;
  int get postsCount => _postsCount < 0 ? 0 : _postsCount;

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
      isAdmin: _isAdmin,
      status: _status,
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
      };

      if (imageUrl != null) {
        updates['profile_image'] = imageUrl;
      }

      // Remove id from updates if we use update()
      debugPrint("Attempting to UPDATE profile with updates: $updates");

      await supabase.Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('id', _currentUser!.id);

      // Also update auth user metadata so next login uses correct display_name
      await supabase.Supabase.instance.client.auth.updateUser(
        supabase.UserAttributes(
          data: {
            'display_name': name,
            'phone': phone,
          },
        ),
      );

      debugPrint("UPDATE Success.");

      notifyListeners();
    } catch (e) {
      debugPrint("Error updating profile (UPSERT failed): $e");
      rethrow;
    }
  }



  void incrementPostsCount() {
    _postsCount++;
    notifyListeners();
  }

  void decrementPostsCount() {
    if (_postsCount > 0) {
      _postsCount--;
    } else {
      _postsCount = 0;
    }
    notifyListeners();
  }

  void syncPostsCount(int actualCount) {
    if (_postsCount != actualCount && actualCount >= 0) {
      _postsCount = actualCount;
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
    _name = "User";
    _bio = "";
    _email = "";
    _phone = "";
    _profileImage = "https://ui-avatars.com/api/?name=User&background=random&size=512";
    _profileImageFile = null;
    _followers = 0;
    _following = 0;
    _postsCount = 0;
    _isAdmin = false;
    _status = "active";
    _currentUser = null; // Explicitly clear current user
    _needsPasswordReset = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> deleteAccount() async {
    if (_currentUser == null) return;
    final userId = _currentUser!.id;
    try {
      // Delete user profile from database.
      // Trigger in database handles cascade deleting auth.users row.
      await DatabaseService().deleteProfile(userId);
      await signOut();
      clearUserData();
    } catch (e) {
      debugPrint("Error deleting account: $e");
      rethrow;
    }
  }
}
