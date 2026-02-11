import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../providers/social_provider.dart';
import '../providers/user_provider.dart';
import 'create_jump_post_screen.dart';
import 'other_user_profile_screen.dart';
import 'profile_screen.dart';
import 'package:gal/gal.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/full_screen_image.dart';
import '../widgets/post_video_player.dart';

class JumpPostFeedScreen extends StatefulWidget {
  const JumpPostFeedScreen({super.key});

  @override
  State<JumpPostFeedScreen> createState() => _JumpPostFeedScreenState();
}

class _JumpPostFeedScreenState extends State<JumpPostFeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // State for replying
  String? _replyingToCommentId;
  String? _replyingToUserName;
  final FocusNode _commentFocusNode = FocusNode();
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _showComments(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Comments (${post.commentsCount})",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: post.comments.isEmpty
                            ? Center(
                                child: Text(
                                  "No comments yet. Be the first!",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: post.comments.length,
                                itemBuilder: (context, index) {
                                  final comment = post.comments[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Column(
                                      // Main Column for comment + replies
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              onTap: () =>
                                                  _navigateToUserProfile(
                                                    comment.author,
                                                  ),
                                              child: CircleAvatar(
                                                backgroundImage: comment
                                                    .author
                                                    .imageProvider,
                                                radius: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    comment.author.name,
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    comment.text,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "${comment.timestamp.hour}:${comment.timestamp.minute.toString().padLeft(2, '0')}",
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      GestureDetector(
                                                        onTap: () {
                                                          setModalState(() {
                                                            _replyingToCommentId =
                                                                comment.id;
                                                            _replyingToUserName =
                                                                comment
                                                                    .author
                                                                    .name;
                                                          });
                                                          FocusScope.of(
                                                            context,
                                                          ).requestFocus(
                                                            _commentFocusNode,
                                                          );
                                                        },
                                                        child: Text(
                                                          "Reply",
                                                          style:
                                                              GoogleFonts.poppins(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .grey[600],
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Display Replies
                                        if (comment.replies.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 12,
                                              left: 48, // Indent replies
                                            ),
                                            child: Column(
                                              children: comment.replies
                                                  .map(
                                                    (reply) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 12,
                                                          ),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          GestureDetector(
                                                            onTap: () =>
                                                                _navigateToUserProfile(
                                                                  reply.author,
                                                                ),
                                                            child: CircleAvatar(
                                                              backgroundImage: reply
                                                                  .author
                                                                  .imageProvider,
                                                              radius:
                                                                  14, // Smaller avatar for replies
                                                            ),
                                                          ), // Added closing parenthesis for GestureDetector and comma
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  reply
                                                                      .author
                                                                      .name,
                                                                  style: GoogleFonts.poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  reply.text,
                                                                  style:
                                                                      GoogleFonts.poppins(
                                                                        fontSize:
                                                                            13,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      const Divider(),
                      if (_replyingToCommentId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          color: Colors.grey[200],
                          child: Row(
                            children: [
                              Text(
                                "Replying to $_replyingToUserName",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  setModalState(() {
                                    _replyingToCommentId = null;
                                    _replyingToUserName = null;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16, top: 8),
                        child: TextField(
                          controller: _commentController,
                          focusNode: _commentFocusNode,
                          decoration: InputDecoration(
                            hintText: _replyingToCommentId != null
                                ? "Reply to $_replyingToUserName..."
                                : "Add a comment...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.send, color: Colors.blue),
                              onPressed: () {
                                if (_commentController.text.trim().isEmpty)
                                  return;

                                final text = _commentController.text.trim();
                                final currentUser = Provider.of<UserProvider>(
                                  context,
                                  listen: false,
                                ).user;
                                if (_replyingToCommentId != null) {
                                  Provider.of<SocialProvider>(
                                    context,
                                    listen: false,
                                  ).replyToComment(
                                    post.id,
                                    _replyingToCommentId!,
                                    text,
                                    currentUser,
                                  );
                                } else {
                                  Provider.of<SocialProvider>(
                                    context,
                                    listen: false,
                                  ).addComment(post.id, text, currentUser);
                                }

                                _commentController.clear();
                                setModalState(() {
                                  _replyingToCommentId = null;
                                  _replyingToUserName = null;
                                });
                                // Close keyboard logic if needed, or keep open
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() {
        // Clear reply state when bottom sheet closes
        _replyingToCommentId = null;
        _replyingToUserName = null;
        _commentController.clear(); // Optional: clear text
      });
    });
  }

  Future<void> _downloadMedia(String url, bool isVideo) async {
    try {
      // 1. Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}.${isVideo ? "mp4" : "jpg"}';
      final String filePath = '${tempDir.path}/$fileName';

      // 2. Download file
      await Dio().download(url, filePath);

      // 3. Save to gallery
      if (isVideo) {
        await Gal.putVideo(filePath);
      } else {
        await Gal.putImage(filePath);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Saved to Gallery!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Download Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save media: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        // Filtering Logic
        List<Post> filteredPosts = socialProvider.posts;
        if (_searchQuery.isNotEmpty) {
          filteredPosts = socialProvider.posts
              .where(
                (post) =>
                    post.roadName.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    post.description.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5), // Light grey background
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              "Jump Post",
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Search Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey[300]!, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: "Search roads or streets...",
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.blue[700], // Consistent blue accent
                        size: 24,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

              // Feed List
              Expanded(
                child: filteredPosts.isEmpty
                    ? Center(
                        child: Text(
                          "No posts found",
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredPosts.length,
                        itemBuilder: (context, index) {
                          final post = filteredPosts[index];
                          return _buildPostCard(context, post);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateJumpPostScreen(),
                ),
              );
            },
            backgroundColor: const Color(0xFFE3F2FD), // Light blue
            child: const Icon(Icons.add, color: Colors.black),
          ),
        );
      },
    );
  }

  Widget _buildPostCard(BuildContext context, Post post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Road Name Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              post.roadName,
              style: GoogleFonts.poppins(
                fontSize: 22, // Increased size
                fontWeight: FontWeight.w800, // Extra Bold
                color: Colors.black, // Pure black
              ),
            ),
          ),

          // Media Content (Video or Image Placeholder)
          if (post.videoUrl != null)
            SizedBox(
              height: 250,
              width: double.infinity,
              child: PostVideoPlayer(videoUrl: post.videoUrl!),
            )
          else if (post.imageUrl != null)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FullScreenImage(imageUrl: post.imageUrl!),
                  ),
                );
              },
              child: SizedBox(
                height: 250,
                width: double.infinity,
                child: _buildPostImage(post.imageUrl!),
              ),
            )
          else
            Container(
              height: 200,
              width: double.infinity,
              color: post.color,
              child: const Center(
                child: Icon(Icons.image, size: 50, color: Colors.white54),
              ),
            ),

          // Description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              post.description,
              style: GoogleFonts.poppins(
                fontSize: 16, // Increased size
                color: Colors.black, // Pure black for strong visibility
                height: 1.5, // Better line spacing
                fontWeight: FontWeight.w500, // Medium weight
              ),
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Footer (User info & Actions)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _navigateToUserProfile(post.author),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: post.author.imageProvider,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _navigateToUserProfile(post.author),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Posted by",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[700], // Darker grey
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        post.author.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Pure black
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  post.timeAgo,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[800], // Darker grey
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLikeButton(context, post),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: post.commentsCount.toString(),
                  onTap: () => _showComments(context, post),
                ),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: "Share",
                  onTap: () {
                    // Implement Share
                  },
                ),
                if (post.videoUrl != null || post.imageUrl != null)
                  _buildActionButton(
                    icon: Icons.download_rounded,
                    label: "Save",
                    onTap: () {
                      if (post.videoUrl != null) {
                        _downloadMedia(post.videoUrl!, true);
                      } else if (post.imageUrl != null) {
                        _downloadMedia(post.imageUrl!, false);
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikeButton(BuildContext context, Post post) {
    return InkWell(
      onTap: () {
        Provider.of<SocialProvider>(context, listen: false).toggleLike(post.id);
      },
      child: Row(
        children: [
          Icon(
            post.isLiked ? Icons.favorite : Icons.favorite_border,
            size: 22,
            color: post.isLiked ? Colors.red : Colors.black87,
          ),
          const SizedBox(width: 6),
          Text(
            post.likes.toString(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87, // Darker text
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.black87), // Darker icon
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87, // Darker text
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
