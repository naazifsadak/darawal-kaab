import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:darawalkaab/l10n/app_localizations.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'settings/help_center_screen.dart';
import 'settings/settings_screen.dart';
import 'welcome_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import '../../models/post_model.dart';
import '../../providers/social_provider.dart';
import 'post_detail_screen.dart'; // Added this import
import 'follow_list_screen.dart';
import '../widgets/full_screen_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).refreshProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final displayUser = userProvider.user;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bgColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
            final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
            final textColor = isDark ? Colors.white : Colors.black;
            final text87Color = isDark ? Colors.white70 : Colors.black87;

            return Scaffold(
              backgroundColor: bgColor,
              appBar: AppBar(
                backgroundColor: bgColor,
                elevation: 0,
                title: Text(
                  displayUser.name,
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                centerTitle: false,
                actions: [
                  // Menu Button
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.grey[800] : Colors.grey[50],
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.menu_rounded,
                        color: text87Color,
                        size: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: cardColor, // Ensure visibility
                      offset: const Offset(0, 45),
                      elevation: 4,
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        } else if (value == 'settings') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        } else if (value == 'admin') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminDashboardScreen(),
                            ),
                          );
                        } else if (value == 'logout') {
                          _showLogoutDialog(context);
                        } else if (value == 'help') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HelpCenterScreen(),
                            ),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  color: Colors.grey[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppLocalizations.of(context)!.editProfile,
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (userProvider.isAdmin)
                            PopupMenuItem(
                              value: 'admin',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.admin_panel_settings_outlined,
                                    color: Colors.blue[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Admin Portal",
                                    style: GoogleFonts.poppins(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          PopupMenuItem(
                            value: 'settings',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.settings_outlined,
                                  color: Colors.grey[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppLocalizations.of(context)!.settings,
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'help',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.help_outline,
                                  color: Colors.grey[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppLocalizations.of(context)!.helpCenter,
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.logout_rounded,
                                  color: Color(0xFFE53935),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppLocalizations.of(context)!.logOut,
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFE53935),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Avatar
                    Center(
                      child: Stack(
                        children: [
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
                              padding: const EdgeInsets.all(2), // Border width
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey,
                                backgroundImage: displayUser.imageProvider,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EditProfileScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      displayUser.name,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
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
                          AppLocalizations.of(context)!.posts,
                          textColor,
                          null, // Posts list not implemented
                        ),
                        _buildStatItem(
                          displayUser.followers.toString(),
                          AppLocalizations.of(context)!.followers,
                          textColor,
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
                              if (context.mounted) {
                                Provider.of<UserProvider>(context, listen: false).refreshProfile();
                              }
                            });
                          },
                        ),
                        _buildStatItem(
                          displayUser.following.toString(),
                          AppLocalizations.of(context)!.following,
                          textColor,
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
                              if (context.mounted) {
                                Provider.of<UserProvider>(context, listen: false).refreshProfile();
                              }
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Follow Button
                    const SizedBox(height: 12),

                    const SizedBox(height: 24),

                    // Divider/Grid Header
                    const Divider(height: 1, thickness: 1),

                    // Photo Grid
                    FutureBuilder<List<Post>>(
                      future: Provider.of<SocialProvider>(
                        context,
                        listen: false,
                      ).fetchUserPosts(displayUser.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text("Error loading posts"),
                          );
                        }
                        final posts = snapshot.data ?? [];
                        
                        // Automatically sync the exact post count with the provider
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted) {
                            Provider.of<UserProvider>(context, listen: false)
                                .syncPostsCount(posts.length);
                          }
                        });

                        if (posts.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              "No posts yet",
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                          );
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: posts.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 2,
                                mainAxisSpacing: 2,
                              ),
                          itemBuilder: (context, index) {
                            final post = posts[index];
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
                                color: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                child: post.imageUrl != null
                                    ? Image.network(
                                        post.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.error),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.videocam,
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

  Widget _buildStatItem(String count, String label, Color textColor, [VoidCallback? onTap]) {
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
                color: textColor,
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

  void _showLogoutDialog(BuildContext context) {
    // Capture necessary objects before async gap
    final navigator = Navigator.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.logOut),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              // 1. Close the dialog
              Navigator.pop(dialogContext);

              // 2. Perform mock sign out
              await AuthService().signOut();

              // 3. Clear local user data
              userProvider.clearUserData();

              // 4. Navigate using the captured navigator
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );
            },
            child: Text(
              AppLocalizations.of(context)!.logOut,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
