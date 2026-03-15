import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../providers/social_provider.dart';
import 'post_detail_screen.dart';

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
        final isFollowing = displayUser.isFollowing;

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
                Container(
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
                    _buildStatItem(displayUser.postsCount.toString(), "Posts"),
                    _buildStatItem(
                      displayUser.hideFollowersFollowing
                          ? "-"
                          : displayUser.followers.toString(),
                      "Followers",
                    ),
                    _buildStatItem(
                      displayUser.hideFollowersFollowing
                          ? "-"
                          : displayUser.following.toString(),
                      "Following",
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
                      onPressed: () {
                        socialProvider.toggleFollow(displayUser.id);
                        setState(() {
                          // Manually toggle locally if waiting for fetch
                          displayUser.isFollowing = !displayUser.isFollowing;
                          if (displayUser.isFollowing)
                            displayUser.followers++;
                          else
                            displayUser.followers--;
                        });
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
                    if (!postsSnapshot.hasData || postsSnapshot.data!.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          "No posts yet",
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      );
                    }

                    final userPosts = postsSnapshot.data!;
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

  Widget _buildStatItem(String count, String label) {
    return Column(
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
    );
  }
}
