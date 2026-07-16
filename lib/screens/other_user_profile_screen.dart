import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../providers/social_provider.dart';
import '../../providers/user_provider.dart';
import '../widgets/full_screen_image.dart';
import 'post_detail_screen.dart';
import 'follow_list_screen.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final User user;

  const OtherUserProfileScreen({super.key, required this.user});

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  User? _liveUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveUser();
  }

  Future<void> _fetchLiveUser() async {
    final liveProfile = await Provider.of<SocialProvider>(
      context,
      listen: false,
    ).fetchUserProfile(widget.user.id);

    if (mounted) {
      setState(() {
        _liveUser = liveProfile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fallback to exactly what was passed in while loading or if it fails
    final displayUser = _liveUser ?? widget.user;

    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        final isFollowing = socialProvider.isFollowing(displayUser.id);

        if (_isLoading) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

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
              displayUser.name,
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Avatar
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImage(
                          imageProvider: displayUser.imageProvider,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[200]!, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: displayUser.imageProvider,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  displayUser.name,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                // Bio
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 8,
                  ),
                  child: Text(
                    displayUser.bio,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      displayUser.postsCount.toString(),
                      "Posts",
                      null,
                    ),
                     _buildStatItem(
                      displayUser.followers.toString(),
                      "Followers",
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FollowListScreen(
                              title: "Followers",
                              userId: displayUser.id,
                              isFollowers: true,
                            ),
                          ),
                        ).then((_) {
                          _fetchLiveUser();
                        });
                      },
                    ),
                    _buildStatItem(
                      displayUser.following.toString(),
                      "Following",
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FollowListScreen(
                              title: "Following",
                              userId: displayUser.id,
                              isFollowers: false,
                            ),
                          ),
                        ).then((_) {
                          _fetchLiveUser();
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Follow Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final userProvider = Provider.of<UserProvider>(context, listen: false);
                        // Optimistically toggle counts locally
                        setState(() {
                          final wasFollowing = socialProvider.isFollowing(displayUser.id);
                          if (!wasFollowing) {
                            displayUser.followers++;
                          } else {
                            displayUser.followers = (displayUser.followers - 1).clamp(0, 999999);
                          }
                        });

                        await socialProvider.toggleFollow(displayUser.id);
                        await _fetchLiveUser();
                        userProvider.refreshProfile();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing
                            ? Colors.white
                            : const Color(0xFF1E88E5), // Blue
                        foregroundColor: isFollowing
                            ? Colors.black
                            : Colors.white,
                        side: isFollowing
                            ? const BorderSide(color: Colors.grey)
                            : BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isFollowing ? "Following" : "Follow",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Photo Grid (Fetch actual posts for this user)
                FutureBuilder<List<Post>>(
                  future: socialProvider.fetchUserPosts(displayUser.id),
                  builder: (context, postsSnapshot) {
                    if (postsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final userPosts = postsSnapshot.data ?? [];

                    // Automatically sync the exact post count locally
                    if (userPosts.length != displayUser.postsCount) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            displayUser.postsCount = userPosts.length;
                          });
                        }
                      });
                    }

                    if (userPosts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          "No posts yet",
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      );
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: userPosts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                          ),
                      itemBuilder: (context, index) {
                        final post = userPosts[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PostDetailScreen(post: post),
                              ),
                            );
                          },
                          child: Container(
                            color: Colors.grey[200],
                            child: userPosts[index].imageUrl != null
                                ? Image.network(
                                    userPosts[index].imageUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String count, String label, [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            Text(
              count,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
