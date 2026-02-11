import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/comment_model.dart';

class SocialProvider with ChangeNotifier {
  List<User> _users = [];
  List<Post> _posts = [];

  List<Post> get posts => _posts;

  SocialProvider() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Initialize Users
    final user1 = User(
      id: 'u1',
      name: 'Sadiya Omar',
      profileImage: 'assets/images/somali woman1.jpg',
      bio: 'Loves driving and exploring the city.',
      followers: 120,
      following: 45,
      postsCount: 12,
    );

    final user2 = User(
      id: 'u2',
      name: 'Ahmed Ali',
      profileImage: 'assets/images/somali man1.jpg',
      bio: 'Professional driver. Safety first.',
      followers: 350,
      following: 200,
      postsCount: 56,
      isFollowing: true,
    );

    final user3 = User(
      id: 'u3',
      name: 'Mohamed Nur',
      profileImage: 'assets/images/somali man2.jpg',
      bio: 'Traffic reporter.',
      followers: 890,
      following: 50,
      postsCount: 102,
    );

    final user4 = User(
      id: 'u4',
      name: 'Fatima Hassan',
      profileImage: 'assets/images/somali woman2.jpg',
      bio: 'New driver. Learning the roads.',
      followers: 45,
      following: 60,
      postsCount: 5,
    );

    _users = [user1, user2, user3, user4];

    // Initialize Posts
    _posts = [
      Post(
        id: 'p1',
        roadName: "Wadada bula-xuubey",
        description:
            "Wadooyinku waa furan yihiin saakay, aad bay u fiican tahay kaxeynta baabuurka.",
        timeAgo: "2h ago",
        author: user1,
        color: Colors.blue[100]!,
        likes: 67,
        comments: [
          Comment(
            id: 'c1',
            text: "Great update, thanks!",
            author: user2,
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          Comment(
            id: 'c2',
            text: "I was just there!",
            author: user3,
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ],
        isLiked: false,
      ),
      Post(
        id: 'p2',
        roadName: "Wadada buundooyinka",
        description: "Traffic is heavy near the bridge due to construction.",
        timeAgo: "4h ago",
        author: user2,
        color: Colors.orange[100]!,
        likes: 120,
        comments: [], // Initialize with empty list
        isLiked: true,
      ),
      Post(
        id: 'p3',
        roadName: "Wadada Maka Al-Mukarama",
        description:
            "Road is clear but watch out for potholes near the junction.",
        timeAgo: "5h ago",
        author: user3,
        color: Colors.green[100]!,
        likes: 45,
        comments: [],
        isLiked: false,
      ),
      Post(
        id: 'p5',
        roadName: "Airport Road",
        description: "Checking out the new road expansion. Looks smooth!",
        timeAgo: "30m ago",
        author: user1,
        color: Colors.blue[100]!,
        likes: 200,
        comments: [],
        isLiked: false,
        videoUrl:
            'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      ),
      Post(
        id: 'p6',
        roadName: "Liido Road",
        description: "Beautiful sunset view from the corniche today.",
        timeAgo: "15m ago",
        author: user1,
        color: Colors.purple[100]!,
        likes: 350,
        comments: [],
        isLiked: true,
        imageUrl:
            'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg',
      ),
    ];
  }

  User getUser(String id) {
    return _users.firstWhere((u) => u.id == id, orElse: () => _users[0]);
  }

  void addPost(Post post) {
    _posts.insert(0, post);
    notifyListeners();
  }

  void toggleLike(String postId) {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      post.isLiked = !post.isLiked;
      if (post.isLiked) {
        post.likes++;
      } else {
        post.likes--;
      }
      notifyListeners();
    }
  }

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
      notifyListeners();
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
      // Simple search for top-level comments for now
      final commentIndex = post.comments.indexWhere((c) => c.id == commentId);
      if (commentIndex != -1) {
        final reply = Comment(
          id: DateTime.now().toString(),
          text: text,
          author: author,
          timestamp: DateTime.now(),
        );
        post.comments[commentIndex].replies.add(reply);
        notifyListeners();
      }
    }
  }

  void toggleFollow(String userId) {
    final userIndex = _users.indexWhere((u) => u.id == userId);
    if (userIndex != -1) {
      _users[userIndex].isFollowing = !_users[userIndex].isFollowing;

      // Update followers count for effect
      if (_users[userIndex].isFollowing) {
        // Since User fields are final, we can't update them directly if we made them final.
        // But in the User model provided earlier, 'isFollowing' is not final, but 'followers' is final.
        // For now, we will just toggle isFollowing.
        // To update counts properly, User model needs to be mutable or copied.
        // Assuming 'isFollowing' is mutable as per previous 'view_file'.
      }
      notifyListeners();
    }
  }
}
