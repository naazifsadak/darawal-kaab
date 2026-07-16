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
      insertData['parent_id'] = parentId;
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

  Future<void> toggleCommentLike(String commentId, String userId, bool isLiking) async {
    if (isLiking) {
      await _supabase.from('comment_likes').insert({
        'comment_id': commentId,
        'user_id': userId,
      });
    } else {
      await _supabase
          .from('comment_likes')
          .delete()
          .eq('comment_id', commentId)
          .eq('user_id', userId);
    }
  }

  Future<List<String>> fetchLikedCommentIds(String userId) async {
    final response = await _supabase
        .from('comment_likes')
        .select('comment_id')
        .eq('user_id', userId);
    return (response as List).map((row) => row['comment_id'].toString()).toList();
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

  Future<void> deleteProfile(String userId) async {
    await _supabase.from('profiles').delete().eq('id', userId);
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
    final profileData = await _supabase
        .from('profiles')
        .select('*, posts:posts!posts_author_id_fkey(id)')
        .eq('id', userId)
        .maybeSingle();
        
    if (profileData == null) return null;

    // Fetch exact follower/following counts
    try {
      final followersList = await _supabase
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId);
      profileData['true_followers_count'] = (followersList as List).length;
      
      final followingList = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);
      profileData['true_following_count'] = (followingList as List).length;
    } catch (e) {
      // Ignored: fallback to cached counts if this fails
    }

    return profileData;
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

  Future<List<Map<String, dynamic>>> fetchFollowerProfiles(String userId) async {
    final response = await _supabase
        .from('follows')
        .select('follower_id')
        .eq('following_id', userId);
    final List<String> followerIds = (response as List)
        .map((row) => row['follower_id'].toString())
        .toList();
    
    if (followerIds.isEmpty) return [];
    
    return await _supabase
        .from('profiles')
        .select()
        .filter('id', 'in', '(${followerIds.join(",")})');
  }

  Future<List<Map<String, dynamic>>> fetchFollowingProfiles(String userId) async {
    final response = await _supabase
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);
    final List<String> followingIds = (response as List)
        .map((row) => row['following_id'].toString())
        .toList();
    
    if (followingIds.isEmpty) return [];
    
    return await _supabase
        .from('profiles')
        .select()
        .filter('id', 'in', '(${followingIds.join(",")})');
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

  // --- UGC BLOCKING & REPORTING ---
  Future<void> blockUser(String blockerId, String blockedId) async {
    await _supabase.from('user_blocks').insert({
      'blocker_id': blockerId,
      'blocked_id': blockedId,
    });
  }

  Future<List<String>> fetchBlockedUserIds(String blockerId) async {
    final response = await _supabase
        .from('user_blocks')
        .select('blocked_id')
        .eq('blocker_id', blockerId);
    return (response as List).map((row) => row['blocked_id'].toString()).toList();
  }

  Future<void> reportPost({
    required String reporterId,
    required String postId,
    required String reason,
    String? details,
  }) async {
    await _supabase.from('content_reports').insert({
      'reporter_id': reporterId,
      'reported_post_id': postId,
      'reason': reason,
      'details': details,
    });
  }

  Future<void> reportComment({
    required String reporterId,
    required String commentId,
    required String reason,
    String? details,
  }) async {
    await _supabase.from('content_reports').insert({
      'reporter_id': reporterId,
      'reported_comment_id': commentId,
      'reason': reason,
      'details': details,
    });
  }
}
