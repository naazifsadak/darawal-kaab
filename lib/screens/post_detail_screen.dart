import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/social_provider.dart';
import '../../providers/user_provider.dart';
import '../widgets/post_video_player.dart';
import '../widgets/full_screen_image.dart';
import 'other_user_profile_screen.dart';
import 'profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  void _navigateToUserProfile(User user) {
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    if (user.id == currentUser.id) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtherUserProfileScreen(user: user),
        ),
      );
    }
  }

  Widget _buildPostImage(String imageUrl) {
    if (File(imageUrl).existsSync()) {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 250,
          width: double.infinity,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        ),
      );
    } else if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 250,
          width: double.infinity,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        ),
      );
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 250,
          width: double.infinity,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap in Consumer to rebuild when likes change
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        // Fetch the fresh post state if it changed
        final currentPost = socialProvider.posts.firstWhere(
          (p) => p.id == widget.post.id,
          orElse: () => widget.post,
        );

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Post Details",
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Road Name Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    currentPost.roadName,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),

                // Media Content (Video or Image Placeholder)
                if (currentPost.videoUrl != null)
                  SizedBox(
                    height: 250,
                    width: double.infinity,
                    child: PostVideoPlayer(videoUrl: currentPost.videoUrl!),
                  )
                else if (currentPost.imageUrl != null)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FullScreenImage(imageUrl: currentPost.imageUrl!),
                        ),
                      );
                    },
                    child: SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: _buildPostImage(currentPost.imageUrl!),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: currentPost.color,
                    child: const Center(
                      child: Icon(Icons.image, size: 50, color: Colors.white54),
                    ),
                  ),

                // Description
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    currentPost.description,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const Divider(height: 1, thickness: 1),

                // Footer (User info)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToUserProfile(currentPost.author),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: currentPost.author.imageProvider,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _navigateToUserProfile(currentPost.author),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Posted by",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              currentPost.author.name,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        currentPost.timeAgo,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons (Only Like shown for simplicity. Comments shouldn't pop up over details ideally, maybe push user back home)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Provider.of<SocialProvider>(
                            context,
                            listen: false,
                          ).toggleLike(currentPost.id);
                        },
                        child: Row(
                          children: [
                            Icon(
                              currentPost.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 22,
                              color: currentPost.isLiked
                                  ? Colors.red
                                  : Colors.black87,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              currentPost.likes.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 22,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            currentPost.commentsCount.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      "To comment on this post or interact further, please locate it in the Main Jump Feed.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
