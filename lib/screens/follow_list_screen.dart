import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/social_provider.dart';
import 'other_user_profile_screen.dart';
import '../providers/user_provider.dart';
import 'profile_screen.dart';

class FollowListScreen extends StatefulWidget {
  final String title;
  final String userId;
  final bool isFollowers;

  const FollowListScreen({
    super.key,
    required this.title,
    required this.userId,
    required this.isFollowers,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  late Future<List<User>> _futureUsers;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    final socialProvider = Provider.of<SocialProvider>(context, listen: false);
    _futureUsers = widget.isFollowers
        ? socialProvider.getFollowers(widget.userId)
        : socialProvider.getFollowing(widget.userId);
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
      ).then((_) {
        // Refresh the list when returning in case follow status changed
        setState(() {
          _loadUsers();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          widget.title,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<User>>(
        future: _futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading ${widget.title.toLowerCase()}",
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            );
          }
          
          final users = snapshot.data ?? [];
          
          if (users.isEmpty) {
            return Center(
              child: Text(
                "No ${widget.title.toLowerCase()} found",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: user.imageProvider,
                ),
                title: Text(
                  user.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: user.bio.isNotEmpty
                    ? Text(
                        user.bio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      )
                    : null,
                onTap: () => _navigateToUserProfile(user),
                trailing: Consumer<SocialProvider>(
                  builder: (context, socialProvider, child) {
                    final isFollowing = socialProvider.isFollowing(user.id);
                    return ElevatedButton(
                      onPressed: () async {
                        final userProvider = Provider.of<UserProvider>(context, listen: false);
                        await socialProvider.toggleFollow(user.id);
                        userProvider.refreshProfile();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing ? Colors.grey[200] : Colors.blue,
                        foregroundColor: isFollowing ? Colors.black : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        isFollowing ? "Following" : "Follow",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
