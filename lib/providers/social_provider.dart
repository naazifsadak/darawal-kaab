import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class SocialProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Post> _posts = [];
  bool _isLoading = false;

  List<String> _likedPostIds = [];
  List<String> _likedCommentIds = [];
  List<String> _followedUserIds = [];
  List<String> _blockedUserIds = [];
  List<NotificationItem> _notifications = [];
  RealtimeChannel? _notificationsChannel;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  List<NotificationItem> get notifications => _notifications;
  List<String> get blockedUserIds => _blockedUserIds;
  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  SocialProvider() {
    // Listen to Supabase auth changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        refreshFeed(); // Refresh when user logs in
        _setupRealtimeNotifications(session.user.id);
      } else {
        _posts.clear(); // Clear posts when user logs out
        _notificationsChannel?.unsubscribe();
        notifyListeners();
      }
    });
    // Initial fetch if already logged in
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      refreshFeed();
      _setupRealtimeNotifications(currentUser.id);
    }
  }

  void _setupRealtimeNotifications(String userId) {
    _notificationsChannel?.unsubscribe();
    _notificationsChannel = Supabase.instance.client
        .channel('public:notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            // Fetch updated notifications
            fetchNotifications();
            // Show local notification
            final newRecord = payload.newRecord;
            final type = newRecord['type'] as String?;
            String title = 'New Notification';
            String body = 'You have a new notification.';
            
            if (type == 'like') {
               title = 'New Like';
               body = 'Someone liked your post.';
            } else if (type == 'comment') {
               title = 'New Comment';
               body = 'Someone commented on your post.';
            } else if (type == 'follow') {
               title = 'New Follower';
               body = 'Someone started following you.';
            }

            NotificationService().showNotification(
              id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
              title: title,
              body: body,
            );
          },
        )
        .subscribe();
  }

  Future<void> refreshFeed() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        _likedPostIds = await _dbService.fetchLikedPostIds(currentUser.id);
        _likedCommentIds = await _dbService.fetchLikedCommentIds(currentUser.id);
        _followedUserIds = await _dbService.fetchFollowedUserIds(
          currentUser.id,
        );
        _blockedUserIds = await _dbService.fetchBlockedUserIds(currentUser.id);
        await fetchNotifications();
      } else {
        _likedPostIds = [];
        _likedCommentIds = [];
        _followedUserIds = [];
        _blockedUserIds = [];
        _notifications = [];
      }

      final data = await _dbService.fetchPosts();

      // Convert Supabase Map data into your Post and User models
      _posts = data
          .map((json) {
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
                    "https://ui-avatars.com/api/?name=${Uri.encodeComponent(profile['name'] ?? 'Driver+User')}&background=random&size=512",
                bio: profile['bio'] ?? 'Road safety enthusiast.',
                followers: profile['followers_count'] ?? 0,
                following: profile['following_count'] ?? 0,
                postsCount: profile['posts_count'] ?? 0,
                isFollowing: _followedUserIds.contains(json['author_id']),
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
          })
          .where((post) => !_blockedUserIds.contains(post.author.id))
          .toList();
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

  void toggleCommentLike(String postId, String commentId) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      // Recursive function to find and toggle comment
      bool toggleInList(List<Comment> comments) {
        for (var comment in comments) {
          if (comment.id == commentId) {
            comment.isLiked = !comment.isLiked;
            if (comment.isLiked) {
              comment.likes++;
              _likedCommentIds.add(commentId);
            } else {
              comment.likes--;
              _likedCommentIds.remove(commentId);
            }
            return true;
          }
          if (toggleInList(comment.replies)) return true;
        }
        return false;
      }
      
      if (toggleInList(post.comments)) {
        notifyListeners();
        // Since we already toggled, pass the updated value
        final updatedIsLiked = _likedCommentIds.contains(commentId);
        try {
          _dbService.toggleCommentLike(commentId, currentUser.id, updatedIsLiked).catchError((e) {
            debugPrint("Toggle comment like error: $e");
          });
        } catch (e) {
          debugPrint("Toggle comment like error: $e");
        }
      }
    }
  }

  Future<void> addComment(String postId, String text, User author) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    try {
      await _dbService.addComment(postId, currentUser.id, text);
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _posts[postIndex].dbCommentsCount++;
        notifyListeners();
      }
      await fetchCommentsForPost(postId);
    } catch (e) {
      debugPrint("Error adding comment: $e");
    }
  }

  Future<void> replyToComment(
    String postId,
    String commentId,
    String text,
    User author,
  ) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    try {
      await _dbService.addComment(postId, currentUser.id, text, commentId);
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _posts[postIndex].dbCommentsCount++;
        notifyListeners();
      }
      await fetchCommentsForPost(postId);
    } catch (e) {
      debugPrint("Error replying to comment: $e");
    }
  }

  // --- FOLLOWER LISTS ---
  Future<List<User>> getFollowers(String userId) async {
    try {
      final data = await _dbService.fetchFollowerProfiles(userId);
      return data.map((json) {
        return User(
          id: json['id'],
          name: json['name'] ?? 'Unknown User',
          profileImage: json['profile_image'] ?? 'assets/images/placeholder.png',
          bio: json['bio'] ?? '',
          followers: json['followers_count'] ?? 0,
          following: json['following_count'] ?? 0,
          postsCount: json['posts_count'] ?? 0,
          isFollowing: _followedUserIds.contains(json['id']),
        );
      }).toList();
    } catch (e) {
      debugPrint("Error fetching followers: $e");
      return [];
    }
  }

  Future<List<User>> getFollowing(String userId) async {
    try {
      final data = await _dbService.fetchFollowingProfiles(userId);
      return data.map((json) {
        return User(
          id: json['id'],
          name: json['name'] ?? 'Unknown User',
          profileImage: json['profile_image'] ?? 'assets/images/placeholder.png',
          bio: json['bio'] ?? '',
          followers: json['followers_count'] ?? 0,
          following: json['following_count'] ?? 0,
          postsCount: json['posts_count'] ?? 0,
          isFollowing: _followedUserIds.contains(json['id']),
        );
      }).toList();
    } catch (e) {
      debugPrint("Error fetching following: $e");
      return [];
    }
  }

  // Toggle Follow
  bool isFollowing(String userId) => _followedUserIds.contains(userId);

  Future<void> toggleFollow(String userId) async {
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
      await _dbService.toggleFollow(currentUser.id, userId, isFollowingNow);
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
        final authorId = json['author_id'] as String;
        if (_blockedUserIds.contains(authorId)) continue;

        final profile = json['profiles'] as Map<String, dynamic>;
        final comment = Comment(
          id: json['id'].toString(),
          text: json['text'] ?? '',
          author: User(
            id: authorId,
            name: profile['name'] ?? 'Driver User',
            profileImage:
                profile['profile_image'] ??
                "https://ui-avatars.com/api/?name=${Uri.encodeComponent(profile['name'] ?? 'Driver+User')}&background=random&size=512",
            bio: '',
            followers: 0,
            following: 0,
            postsCount: 0,
          ),
          timestamp: DateTime.parse(json['created_at']).toLocal(),
          likes: (json['likes_count'] ?? 0) as int,
          isLiked: _likedCommentIds.contains(json['id'].toString()),
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
                "https://ui-avatars.com/api/?name=${Uri.encodeComponent(profile['name'] ?? 'Driver+User')}&background=random&size=512",
            bio: profile['bio'] ?? 'Road safety enthusiast.',
            followers:
                profile['followers_count'] ?? 0, // Ensure real data using map
            following: profile['following_count'] ?? 0,
            postsCount: profile['posts_count'] ?? 0,
            isFollowing: _followedUserIds.contains(json['author_id']),
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
            "https://ui-avatars.com/api/?name=Unknown+User&background=random&size=512",
        bio: 'User details not available.',
        followers: 0,
        following: 0,
        postsCount: 0,
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
            "https://ui-avatars.com/api/?name=Unknown&background=random&size=512",
        bio: data['bio'] ?? '',
        followers: (data['true_followers_count'] ?? data['followers_count'] ?? 0) as int,
        following: (data['true_following_count'] ?? data['following_count'] ?? 0) as int,
        postsCount: (data['posts'] as List?)?.length ?? (data['posts_count'] ?? 0) as int,
        isFollowing: _followedUserIds.contains(userId),
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
              "https://ui-avatars.com/api/?name=Unknown&background=random&size=512",
          bio: senderData['bio'] ?? '',
          followers: senderData['followers_count'] ?? 0,
          following: senderData['following_count'] ?? 0,
          postsCount: senderData['posts_count'] ?? 0,
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

  Future<void> blockUser(String blockedId) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    try {
      await _dbService.blockUser(currentUser.id, blockedId);
      _blockedUserIds.add(blockedId);
      // Remove all posts from this user from local state to update UI immediately
      _posts.removeWhere((post) => post.author.id == blockedId);
      notifyListeners();
    } catch (e) {
      debugPrint("Error blocking user: $e");
      rethrow;
    }
  }

  Future<void> reportPost({
    required String postId,
    required String reason,
    String? details,
  }) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    try {
      await _dbService.reportPost(
        reporterId: currentUser.id,
        postId: postId,
        reason: reason,
        details: details,
      );
    } catch (e) {
      debugPrint("Error reporting post: $e");
      rethrow;
    }
  }

  Future<void> reportComment({
    required String commentId,
    required String reason,
    String? details,
  }) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    try {
      await _dbService.reportComment(
        reporterId: currentUser.id,
        commentId: commentId,
        reason: reason,
        details: details,
      );
    } catch (e) {
      debugPrint("Error reporting comment: $e");
      rethrow;
    }
  }
}
