import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';
import '../services/database_service.dart';

class SocialProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Post> _posts = [];
  bool _isLoading = false;

  List<String> _likedPostIds = [];
  List<String> _followedUserIds = [];
  List<NotificationItem> _notifications = [];

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  List<NotificationItem> get notifications => _notifications;
  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  SocialProvider() {
    // Listen to Supabase auth changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        refreshFeed(); // Refresh when user logs in
      } else {
        _posts.clear(); // Clear posts when user logs out
        notifyListeners();
      }
    });
    // Initial fetch if already logged in
    if (Supabase.instance.client.auth.currentSession != null) {
      refreshFeed();
    }
  }

  Future<void> refreshFeed() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        _likedPostIds = await _dbService.fetchLikedPostIds(currentUser.id);
        _followedUserIds = await _dbService.fetchFollowedUserIds(
          currentUser.id,
        );
        await fetchNotifications();
      } else {
        _likedPostIds = [];
        _followedUserIds = [];
        _notifications = [];
      }

      final data = await _dbService.fetchPosts();

      // Convert Supabase Map data into your Post and User models
      _posts = data.map((json) {
        final profile = json['profiles'] as Map<String, dynamic>;

        return Post(
          id: json['id'].toString(),
          roadName: json['road_name'] ?? 'Unknown Road',
          description: json['description'] ?? '',
          timeAgo: _formatTimeAgo(json['created_at']),
          author: User(
            id: json['author_id'],
            name: profile['name'] ?? 'Driver User',
            profileImage:
                profile['profile_image'] ??
                "https://ui-avatars.com/api/?name=${Uri.encodeComponent(profile['name'] ?? 'Driver+User')}&background=random",
            bio: profile['bio'] ?? 'Road safety enthusiast.',
            followers: profile['followers_count'] ?? 0,
            following: profile['following_count'] ?? 0,
            postsCount: profile['posts_count'] ?? 0,
            isFollowing: _followedUserIds.contains(json['author_id']),
            hideFollowersFollowing:
                profile['hide_followers_following'] ?? false,
          ),
          likes: (json['likes_count'] ?? 0) as int,
          dbCommentsCount: (json['comments_count'] ?? 0) as int,
          comments:
              [], // Initialize with empty list; fetch separately if needed
          color: Colors.blue[100]!,
          imageUrl: json['image_url'],
          videoUrl: json['video_url'],
          isLiked: _likedPostIds.contains(json['id'].toString()),
        );
      }).toList();
    } catch (e) {
      debugPrint("Error refreshing feed: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Updated to work with the live post list
  void toggleLike(String postId) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      post.isLiked = !post.isLiked;
      if (post.isLiked) {
        post.likes++;
        _likedPostIds.add(postId);
      } else {
        post.likes--;
        _likedPostIds.remove(postId);
      }
      notifyListeners();
      _dbService.toggleLike(postId, currentUser.id, post.isLiked);
    }
  }

  // Adds a comment locally to the UI immediately
  void addComment(String postId, String text, User author) {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final newComment = Comment(
        id: DateTime.now().toString(),
        text: text,
        author: author,
        timestamp: DateTime.now(),
      );
      _posts[postIndex].comments.add(newComment);
      _posts[postIndex].dbCommentsCount++;
      notifyListeners();

      // Persist to Supabase
      _dbService.addComment(postId, author.id, text);
    }
  }

  void replyToComment(
    String postId,
    String commentId,
    String text,
    User author,
  ) {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      final commentIndex = post.comments.indexWhere((c) => c.id == commentId);
      if (commentIndex != -1) {
        final reply = Comment(
          id: DateTime.now().toString(),
          text: text,
          author: author,
          timestamp: DateTime.now(),
        );
        post.comments[commentIndex].replies.add(reply);
        post.dbCommentsCount++;
        notifyListeners();

        // Persist to database with parent_id
        _dbService.addComment(postId, author.id, text, commentId);
      }
    }
  }

  // Toggle Follow
  void toggleFollow(String userId) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null || currentUser.id == userId) return;

    final isPresentlyFollowing = _followedUserIds.contains(userId);
    final isFollowingNow = !isPresentlyFollowing;

    if (isFollowingNow) {
      _followedUserIds.add(userId);
    } else {
      _followedUserIds.remove(userId);
    }

    try {
      // Update follow status on existing posts by this user locally
      for (var post in _posts) {
        if (post.author.id == userId) {
          post.author.isFollowing = isFollowingNow;
        }
      }
      notifyListeners();
      _dbService.toggleFollow(currentUser.id, userId, isFollowingNow);
    } catch (e) {
      debugPrint("Error toggling follow: $e");
    }
  }

  // Delete Post
  Future<void> deletePost(String postId) async {
    try {
      await _dbService.deletePost(postId);
      _posts.removeWhere((p) => p.id == postId);
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting post: $e");
      rethrow;
    }
  }

  // Update Comment
  Future<void> updateComment(
    String postId,
    String commentId,
    String validText,
  ) async {
    try {
      await _dbService.updateComment(commentId, validText);
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final commentIndex = _posts[postIndex].comments.indexWhere(
          (c) => c.id == commentId,
        );
        if (commentIndex != -1) {
          _posts[postIndex].comments[commentIndex].text = validText;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error updating comment: $e");
      rethrow;
    }
  }

  // Fetch comments dynamically
  Future<List<Comment>> fetchCommentsForPost(String postId) async {
    try {
      final data = await _dbService.fetchComments(postId);

      final Map<String, Comment> commentMap = {};
      final List<Comment> topLevelComments = [];
      final List<Map<String, dynamic>> repliesData = [];

      for (var json in data) {
        final profile = json['profiles'] as Map<String, dynamic>;
        final comment = Comment(
          id: json['id'].toString(),
          text: json['text'] ?? '',
          author: User(
            id: json['author_id'],
            name: profile['name'] ?? 'Driver User',
            profileImage:
                profile['profile_image'] ??
                "https://ui-avatars.com/api/?name=${Uri.encodeComponent(profile['name'] ?? 'Driver+User')}&background=random",
            bio: '',
            followers: 0,
            following: 0,
            postsCount: 0,
          ),
          timestamp: DateTime.parse(json['created_at']).toLocal(),
        );

        commentMap[comment.id] = comment;

        if (json['parent_id'] != null) {
          repliesData.add(json);
        } else {
          topLevelComments.add(comment);
        }
      }

      // Attach replies to parents
      for (var json in repliesData) {
        final parentId = json['parent_id'].toString();
        final parentComment = commentMap[parentId];
        if (parentComment != null) {
          parentComment.replies.add(commentMap[json['id'].toString()]!);
        }
      }

      // Optionally update the local post comments
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _posts[postIndex].comments = topLevelComments;
        notifyListeners();
      }
      return topLevelComments;
    } catch (e) {
      debugPrint("Error fetching comments: $e");
      return [];
    }
  }

  // Delete Comment
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _dbService.deleteComment(commentId);
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _posts[postIndex].comments.removeWhere((c) => c.id == commentId);
        _posts[postIndex].dbCommentsCount =
            (_posts[postIndex].dbCommentsCount - 1).clamp(0, 99999);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error deleting comment: $e");
      rethrow;
    }
  }

  // Fetch User Posts
  Future<List<Post>> fetchUserPosts(String userId) async {
    try {
      final data = await _dbService.fetchUserPosts(userId);
      return data.map((json) {
        final profile = json['profiles'] as Map<String, dynamic>;
        return Post(
          id: json['id'].toString(),
          roadName: json['road_name'] ?? 'Unknown Road',
          description: json['description'] ?? '',
          timeAgo: _formatTimeAgo(json['created_at']),
          author: User(
            id: json['author_id'],
            name: profile['name'] ?? 'Driver User',
            profileImage:
                profile['profile_image'] ??
                "https://ui-avatars.com/api/?name=${Uri.encodeComponent(profile['name'] ?? 'Driver+User')}&background=random",
            bio: profile['bio'] ?? 'Road safety enthusiast.',
            followers:
                profile['followers_count'] ?? 0, // Ensure real data using map
            following: profile['following_count'] ?? 0,
            postsCount: profile['posts_count'] ?? 0,
            isFollowing: _followedUserIds.contains(json['author_id']),
            hideFollowersFollowing:
                profile['hide_followers_following'] ?? false,
          ),
          likes: (json['likes_count'] ?? 0) as int,
          dbCommentsCount: (json['comments_count'] ?? 0) as int,
          comments: [], // Comments are fetched separately if needed
          color: Colors.blue[100]!, // Default color
          imageUrl: json['image_url'],
          videoUrl: json['video_url'],
          isLiked: _likedPostIds.contains(json['id'].toString()),
        );
      }).toList();
    } catch (e) {
      debugPrint("Error fetching user posts: $e");
      return [];
    }
  }

  // Helper to find a user from the existing posts
  User getUser(String id) {
    try {
      return _posts.firstWhere((p) => p.author.id == id).author;
    } catch (e) {
      // Fallback if user not found in posts (should ideally fetch from DB)
      return User(
        id: id,
        name: 'Unknown User',
        profileImage:
            "https://ui-avatars.com/api/?name=Unknown+User&background=random",
        bio: 'User details not available.',
        followers: 0,
        following: 0,
        postsCount: 0,
        hideFollowersFollowing: false,
      );
    }
  }

  // Dynamically fetch a user's absolute latest profile stats
  Future<User?> fetchUserProfile(String userId) async {
    try {
      final data = await _dbService.fetchUserProfile(userId);
      if (data == null) return null;
      return User(
        id: data['id'],
        name: data['name'] ?? 'Unknown',
        profileImage:
            data['profile_image'] ??
            "https://ui-avatars.com/api/?name=Unknown&background=random",
        bio: data['bio'] ?? '',
        followers: (data['followers_count'] ?? 0) as int,
        following: (data['following_count'] ?? 0) as int,
        postsCount: (data['posts_count'] ?? 0) as int,
        isFollowing: _followedUserIds.contains(userId),
        hideFollowersFollowing: data['hide_followers_following'] ?? false,
      );
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      return null;
    }
  }

  // --- NOTIFICATIONS ---
  Future<void> fetchNotifications() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    try {
      final data = await _dbService.fetchNotifications(currentUser.id);
      _notifications = data.map((json) {
        final senderData = json['sender_id'] as Map<String, dynamic>;
        final postData = json['post'] as Map<String, dynamic>?;

        final sender = User(
          id: senderData['id'],
          name: senderData['name'] ?? 'Unknown',
          profileImage:
              senderData['profile_image'] ??
              "https://ui-avatars.com/api/?name=Unknown&background=random",
          bio: senderData['bio'] ?? '',
          followers: senderData['followers_count'] ?? 0,
          following: senderData['following_count'] ?? 0,
          postsCount: senderData['posts_count'] ?? 0,
          hideFollowersFollowing:
              senderData['hide_followers_following'] ?? false,
          isFollowing: _followedUserIds.contains(senderData['id']),
        );

        Post? post;
        if (postData != null) {
          post = Post(
            id: postData['id'].toString(),
            roadName: postData['road_name'] ?? 'Unknown',
            description: postData['description'] ?? '',
            timeAgo: "Recently", // Simplified
            author: sender, // Placeholder for the view
            color: Colors.blue[100]!,
            likes: (postData['likes_count'] ?? 0) as int,
            comments: [],
            dbCommentsCount: (postData['comments_count'] ?? 0) as int,
            imageUrl: postData['image_url'],
            videoUrl: postData['video_url'],
            isLiked: _likedPostIds.contains(postData['id'].toString()),
          );
        }

        return NotificationItem.fromJson(json, sender, post: post);
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
      _dbService.markNotificationAsRead(notificationId);
    }
  }

  // --- TIME UTILITY ---
  String _formatTimeAgo(String? dateStr) {
    if (dateStr == null) return "Unknown time";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return "${(difference.inDays / 365).floor()}y ago";
      } else if (difference.inDays >= 30) {
        return "${(difference.inDays / 30).floor()}mo ago";
      } else if (difference.inDays >= 1) {
        return "${difference.inDays}d ago";
      } else if (difference.inHours >= 1) {
        return "${difference.inHours}h ago";
      } else if (difference.inMinutes >= 1) {
        return "${difference.inMinutes}m ago";
      } else {
        return "Just now";
      }
    } catch (e) {
      return "Recently";
    }
  }
}
