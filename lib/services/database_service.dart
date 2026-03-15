import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final _supabase = Supabase.instance.client;

  // --- POSTS ---
  Future<List<Map<String, dynamic>>> fetchPosts() async {
    // Fetches posts with author profile details
    return await _supabase
        .from('posts')
        .select('*, profiles!author_id(name, profile_image)')
        .order('created_at', ascending: false);
  }

  Future<void> createPost({
    required String roadName,
    required String description,
    required String? authorId,
    String? imageUrl,
    String? videoUrl,
  }) async {
    // Updated to include media URLs in the database record
    await _supabase.from('posts').insert({
      'author_id': authorId,
      'road_name': roadName,
      'description': description,
      'image_url': imageUrl,
      'video_url': videoUrl,
    });
  }

  // --- STORAGE ---
  Future<String?> uploadMedia(File file, String folder) async {
    // Generate a unique filename using timestamp
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final path = '$folder/$fileName';

    // Upload the file to the 'post-media' bucket
    await _supabase.storage.from('post-media').upload(path, file);

    // Return the public URL for saving in the posts table
    return _supabase.storage.from('post-media').getPublicUrl(path);
  }

  // --- COMMENTS ---
  Future<void> addComment(
    String postId,
    String authorId,
    String text, [
    String? parentId,
  ]) async {
    // Standard insert for new comments
    final Map<String, dynamic> insertData = {
      'post_id': postId,
      'author_id': authorId,
      'text': text,
    };
    if (parentId != null) {
      insertData['parent_id'] = int.tryParse(parentId);
    }
    await _supabase.from('comments').insert(insertData);
  }

  Future<List<Map<String, dynamic>>> fetchComments(String postId) async {
    // Join with profiles to get the author's details alongside the comment
    return await _supabase
        .from('comments')
        .select('*, profiles!author_id(name, profile_image)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
  }

  Future<void> deleteComment(String commentId) async {
    await _supabase.from('comments').delete().eq('id', commentId);
  }

  // --- PROFILES ---
  Future<void> createProfile({
    required String id,
    required String email,
    String? name,
    String? profileImage,
  }) async {
    await _supabase.from('profiles').insert({
      'id': id,
      // 'email': email, // REMOVED: Column does not exist in public.profiles
      'name': name ?? email.split('@')[0], // Default name from email
      'profile_image': profileImage,
    });
  }

  Future<void> ensureProfileExists({
    required String id,
    required String email,
    String? name,
    String? profileImage,
  }) async {
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) {
      await createProfile(
        id: id,
        email: email,
        name: name,
        profileImage: profileImage,
      );
    }
  }

  Future<void> deletePost(String postId) async {
    await _supabase.from('posts').delete().eq('id', postId);
  }

  Future<void> updateComment(String commentId, String text) async {
    await _supabase.from('comments').update({'text': text}).eq('id', commentId);
  }

  Future<List<Map<String, dynamic>>> fetchUserPosts(String userId) async {
    return await _supabase
        .from('posts')
        .select('*, profiles!author_id(name, profile_image)')
        .eq('author_id', userId)
        .order('created_at', ascending: false);
  }

  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    return await _supabase
        .from('profiles')
        .select('*, posts(id)')
        .eq('id', userId)
        .maybeSingle();
  }

  // --- LIKES ---
  Future<void> toggleLike(String postId, String userId, bool isLiking) async {
    if (isLiking) {
      await _supabase.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
    } else {
      await _supabase
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    }
  }

  Future<List<String>> fetchLikedPostIds(String userId) async {
    final response = await _supabase
        .from('post_likes')
        .select('post_id')
        .eq('user_id', userId);
    return (response as List).map((row) => row['post_id'].toString()).toList();
  }

  // --- FOLLOWS ---
  Future<void> toggleFollow(
    String followerId,
    String followingId,
    bool isFollowing,
  ) async {
    if (isFollowing) {
      await _supabase.from('follows').insert({
        'follower_id': followerId,
        'following_id': followingId,
      });
    } else {
      await _supabase
          .from('follows')
          .delete()
          .eq('follower_id', followerId)
          .eq('following_id', followingId);
    }
  }

  Future<List<String>> fetchFollowedUserIds(String followerId) async {
    final response = await _supabase
        .from('follows')
        .select('following_id')
        .eq('follower_id', followerId);
    return (response as List)
        .map((row) => row['following_id'].toString())
        .toList();
  }

  // --- NOTIFICATIONS ---
  Future<List<Map<String, dynamic>>> fetchNotifications(String userId) async {
    return await _supabase
        .from('notifications')
        .select(
          '*, sender_id:profiles!sender_id(id, name, profile_image, bio, followers_count, following_count, posts_count), post:posts(*)',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }
}
