import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../models/comment_model.dart';
import '../../providers/social_provider.dart';
import '../../providers/user_provider.dart';
import '../widgets/post_video_player.dart';
import '../widgets/full_screen_image.dart';
import 'other_user_profile_screen.dart';
import 'profile_screen.dart';
import 'package:darawalkaab/l10n/app_localizations.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Future<List<Comment>> _commentsFuture;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _commentsSectionKey = GlobalKey();

  String? _replyingToCommentId;
  String? _replyingToUserName;

  @override
  void initState() {
    super.initState();
    _commentsFuture = Provider.of<SocialProvider>(context, listen: false)
        .fetchCommentsForPost(widget.post.id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _showBlockUserDialog(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.blockUser),
        content: Text(AppLocalizations.of(context)!.confirmBlockUser),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.block),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await Provider.of<SocialProvider>(context, listen: false).blockUser(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.userBlocked),
              backgroundColor: Colors.green,
            ),
          );
          // If the blocked user is the author of this post, we must close this detail screen immediately.
          if (widget.post.author.id == userId) {
            Navigator.pop(context);
          } else {
            // Otherwise just reload comments
            setState(() {
              _commentsFuture = Provider.of<SocialProvider>(context, listen: false)
                  .fetchCommentsForPost(widget.post.id);
            });
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to block user: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showReportCommentDialog(String commentId) async {
    final reasons = [
      AppLocalizations.of(context)!.reportReasonSpam,
      AppLocalizations.of(context)!.reportReasonHarassment,
      AppLocalizations.of(context)!.reportReasonInappropriate,
      AppLocalizations.of(context)!.reportReasonOther,
    ];

    String? selectedReason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(AppLocalizations.of(context)!.reportComment),
        children: reasons
            .map(
              (reason) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, reason),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(reason),
                ),
              ),
            )
            .toList(),
      ),
    );

    if (selectedReason != null && mounted) {
      try {
        await Provider.of<SocialProvider>(context, listen: false).reportComment(
          commentId: commentId,
          reason: selectedReason,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.reportSubmitted),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to submit report: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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

  String _formatShortTime(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inDays >= 7) {
      return "${difference.inDays ~/ 7}w";
    } else if (difference.inDays >= 1) {
      return "${difference.inDays}d";
    } else if (difference.inHours >= 1) {
      return "${difference.inHours}h";
    } else if (difference.inMinutes >= 1) {
      return "${difference.inMinutes}m";
    } else {
      return "now";
    }
  }

  Future<void> _showEditCommentDialog(
    BuildContext context,
    Post post,
    Comment comment,
  ) async {
    final TextEditingController editController = TextEditingController(
      text: comment.text,
    );
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editCommentTitle),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.enterNewComment,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              if (editController.text.trim().isNotEmpty) {
                try {
                  await Provider.of<SocialProvider>(
                    context,
                    listen: false,
                  ).updateComment(
                    post.id,
                    comment.id,
                    editController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {});
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${AppLocalizations.of(context)!.errorUpdatingComment}$e',
                        ),
                      ),
                    );
                  }
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  void _submitComment(Post post) {
    if (_commentController.text.trim().isEmpty) return;
    
    final text = _commentController.text.trim();
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    
    if (_replyingToCommentId != null) {
      Provider.of<SocialProvider>(context, listen: false).replyToComment(
        post.id, _replyingToCommentId!, text, currentUser
      );
    } else {
      Provider.of<SocialProvider>(context, listen: false).addComment(post.id, text, currentUser);
    }

    _commentController.clear();
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
  }

  Widget _buildCommentInputField(BuildContext context, Post post, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingToCommentId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${AppLocalizations.of(context)!.replyingTo} $_replyingToUserName",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _replyingToCommentId = null;
                          _replyingToUserName = null;
                        });
                      },
                      child: const Icon(Icons.close, size: 14),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(post),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: _replyingToCommentId != null
                          ? "${AppLocalizations.of(context)!.replyingTo} $_replyingToUserName..."
                          : AppLocalizations.of(context)!.addCommentHint,
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _submitComment(post),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentThread(
    BuildContext context,
    Post post,
    Comment comment,
    bool isDark,
    Color textColor,
    Color subtitleColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Comment
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _navigateToUserProfile(comment.author),
                child: CircleAvatar(
                  backgroundImage: comment.author.imageProvider,
                  radius: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.author.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatShortTime(comment.timestamp),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Reply Button
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _replyingToCommentId = comment.id;
                              _replyingToUserName = comment.author.name;
                            });
                            FocusScope.of(context).requestFocus(_commentFocusNode);
                          },
                          child: Text(
                            AppLocalizations.of(context)!.reply,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: subtitleColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Like Button
                        GestureDetector(
                          onTap: () {
                            Provider.of<SocialProvider>(context, listen: false)
                                .toggleCommentLike(post.id, comment.id);
                            setState(() {});
                          },
                          child: Row(
                            children: [
                              Icon(
                                comment.isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 16,
                                color: comment.isLiked ? Colors.red : subtitleColor,
                              ),
                              if (comment.likes > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  comment.likes.toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: comment.isLiked ? Colors.red : subtitleColor,
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // More options
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, size: 20, color: subtitleColor),
                onSelected: (value) async {
                  if (value == 'edit') {
                    _showEditCommentDialog(context, post, comment);
                  } else if (value == 'delete') {
                    await Provider.of<SocialProvider>(context, listen: false)
                        .deleteComment(post.id, comment.id);
                    setState(() {});
                  } else if (value == 'report') {
                    _showReportCommentDialog(comment.id);
                  } else if (value == 'block') {
                    _showBlockUserDialog(comment.author.id);
                  }
                },
                itemBuilder: (context) {
                  final currentUserId = Provider.of<UserProvider>(context, listen: false).user.id;
                  if (comment.author.id == currentUserId) {
                    return [
                      PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context)!.edit)),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
                      ),
                    ];
                  } else {
                    return [
                      PopupMenuItem(
                        value: 'report',
                        child: Text(AppLocalizations.of(context)!.reportComment),
                      ),
                      PopupMenuItem(
                        value: 'block',
                        child: Text(AppLocalizations.of(context)!.blockUser, style: const TextStyle(color: Colors.red)),
                      ),
                    ];
                  }
                },
              ),
            ],
          ),
          
          // Replies Section
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 20),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                ),
                padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!comment.isRepliesExpanded)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            comment.isRepliesExpanded = true;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "View ${comment.replies.length} replies",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      )
                    else
                      ...comment.replies.map((reply) => Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _navigateToUserProfile(reply.author),
                              child: CircleAvatar(
                                backgroundImage: reply.author.imageProvider,
                                radius: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        reply.author.name,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatShortTime(reply.timestamp),
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: subtitleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    reply.text,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _replyingToCommentId = comment.id; // Still reply to main thread
                                            _replyingToUserName = reply.author.name;
                                          });
                                          FocusScope.of(context).requestFocus(_commentFocusNode);
                                        },
                                        child: Text(
                                          AppLocalizations.of(context)!.reply,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: subtitleColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      GestureDetector(
                                        onTap: () {
                                          Provider.of<SocialProvider>(context, listen: false)
                                              .toggleCommentLike(post.id, reply.id);
                                          setState(() {});
                                        },
                                        child: Row(
                                          children: [
                                            Icon(
                                              reply.isLiked ? Icons.favorite : Icons.favorite_border,
                                              size: 14,
                                              color: reply.isLiked ? Colors.red : subtitleColor,
                                            ),
                                            if (reply.likes > 0) ...[
                                              const SizedBox(width: 4),
                                              Text(
                                                reply.likes.toString(),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: reply.isLiked ? Colors.red : subtitleColor,
                                                ),
                                              ),
                                            ]
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_horiz, size: 16, color: subtitleColor),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  _showEditCommentDialog(context, post, reply);
                                } else if (value == 'delete') {
                                  await Provider.of<SocialProvider>(context, listen: false)
                                      .deleteComment(post.id, reply.id);
                                  setState(() {});
                                } else if (value == 'report') {
                                  _showReportCommentDialog(reply.id);
                                } else if (value == 'block') {
                                  _showBlockUserDialog(reply.author.id);
                                }
                              },
                              itemBuilder: (context) {
                                final currentUserId = Provider.of<UserProvider>(context, listen: false).user.id;
                                if (reply.author.id == currentUserId) {
                                  return [
                                    PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context)!.edit)),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
                                    ),
                                  ];
                                } else {
                                  return [
                                    PopupMenuItem(
                                      value: 'report',
                                      child: Text(AppLocalizations.of(context)!.reportComment),
                                    ),
                                    PopupMenuItem(
                                      value: 'block',
                                      child: Text(AppLocalizations.of(context)!.blockUser, style: const TextStyle(color: Colors.red)),
                                    ),
                                  ];
                                }
                              },
                            ),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
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

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Post Details",
              style: GoogleFonts.poppins(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (currentPost.author.id ==
                  Provider.of<UserProvider>(context, listen: false).user.id)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Delete Post"),
                        content: const Text("Are you sure you want to delete this post?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context); // Close dialog
                              
                              try {
                                await Provider.of<SocialProvider>(context, listen: false)
                                    .deletePost(currentPost.id);
                                if (context.mounted) {
                                  Navigator.pop(context); // Return to previous screen
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Post deleted successfully")),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error deleting post: $e")),
                                  );
                                }
                              }
                            },
                            child: const Text("Delete", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
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
                            color: textColor,
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
                            color: textColor,
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
                                      color: subtitleColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    currentPost.author.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
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
                                color: subtitleColor,
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
                                        : textColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    currentPost.likes.toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            InkWell(
                              onTap: () {
                                final context = _commentsSectionKey.currentContext;
                                if (context != null) {
                                  Scrollable.ensureVisible(
                                    context,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 22,
                                    color: textColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    currentPost.commentsCount.toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1, thickness: 1),

                      // Comments Section Header
                      Padding(
                        key: _commentsSectionKey,
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(
                          "${AppLocalizations.of(context)!.comments} (${currentPost.commentsCount})",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),

                      FutureBuilder<List<Comment>>(
                        future: _commentsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF6C00)),
                                ),
                              ),
                            );
                          }

                          final comments = currentPost.comments;

                          if (comments.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                              child: Center(
                                child: Text(
                                  AppLocalizations.of(context)!.noCommentsYet,
                                  style: GoogleFonts.poppins(
                                    color: subtitleColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return _buildCommentThread(
                                context,
                                currentPost,
                                comment,
                                isDark,
                                textColor,
                                subtitleColor,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              _buildCommentInputField(context, currentPost, isDark),
            ],
          ),
        );
      },
    );
  }
}
