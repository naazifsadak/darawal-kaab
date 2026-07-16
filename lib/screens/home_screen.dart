import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:darawalkaab/l10n/app_localizations.dart';

import '../providers/user_provider.dart';
import 'jump_post_feed_screen.dart';
import 'services/service_list_screen.dart';
import '../models/service_place.dart';
import '../services/location_service.dart';
import 'profile_screen.dart';
import '../providers/social_provider.dart';
import '../models/post_model.dart';
import 'post_detail_screen.dart';
import 'dart:io';
import '../widgets/app_banners_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  LatLng _initialPosition = const LatLng(
    2.046934,
    45.318162,
  ); // Mogadishu default

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      if (!mounted) return;
      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final socialProvider = context.watch<SocialProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF152238), const Color(0xFF0F172A)]
                : [
                    const Color(0xFF8AD4F5).withValues(alpha: 0.45),
                    const Color(0xFFF2F9FD),
                  ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Blue Header Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    24,
                    MediaQuery.of(context).padding.top + 16,
                    24,
                    20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF1565C0), const Color(0xFF0D47A1)]
                          : [const Color(0xFF1E88E5), const Color(0xFF1565C0)],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.3 : 0.15,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Hug content
                    children: [
                      // Top Right Profile Picture
                      Align(
                        alignment: Alignment.topRight,
                        child: Consumer<UserProvider>(
                          builder: (context, userProvider, _) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundImage: userProvider.imageProvider,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),

                      Text(
                        AppLocalizations.of(context)!.welcomeMessage,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.findNearbyServices,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Grid Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ServiceListScreen(
                                      title: AppLocalizations.of(
                                        context,
                                      )!.repairShops,
                                      type: ServiceType.repairShop,
                                      userLocation: _initialPosition,
                                    ),
                                  ),
                                );
                              },
                              child: _buildServiceCard(
                                gradientColors: const [
                                  Color(0xFF1A73E8),
                                  Color(0xFF0D47A1),
                                ],
                                icon: Icons.build,
                                label: AppLocalizations.of(
                                  context,
                                )!.findRepairShops,
                                rotateIcon: true,
                                height: 80,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ServiceListScreen(
                                      title: AppLocalizations.of(
                                        context,
                                      )!.gasStations,
                                      type: ServiceType.gasStation,
                                      userLocation: _initialPosition,
                                    ),
                                  ),
                                );
                              },
                              child: _buildServiceCard(
                                gradientColors: const [
                                  Color(0xFF34A853),
                                  Color(0xFF1B5E20),
                                ],
                                icon: Icons.local_gas_station,
                                label: AppLocalizations.of(
                                  context,
                                )!.findGasStations,
                                height: 80,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Jump Post Button
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const JumpPostFeedScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFF97316), Color(0xFFC2410C)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFF97316,
                                ).withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_a_photo,
                                size: 22,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.jumpPostRoadConditions,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Spacing below the blue header
                const SizedBox(height: 12),

                // Active Admin Banners
                const AppBannersWidget(),

                // Recent Road Conditions Section Header
                _buildRecentPostsHeader(context, isDark),

                // Recent Jump Posts List
                _buildRecentJumpPosts(
                  context,
                  socialProvider,
                  isDark,
                  cardColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required List<Color> gradientColors,
    required IconData icon,
    required String label,
    bool rotateIcon = false,
    double height = 100,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.rotate(
            angle: rotateIcon ? -0.5 : 0,
            child: Icon(icon, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPostsHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF6C00).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF6C00),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.recentRoadConditions,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1565C0),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JumpPostFeedScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1E88E5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.viewAll,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentJumpPosts(
    BuildContext context,
    SocialProvider socialProvider,
    bool isDark,
    Color cardColor,
  ) {
    if (socialProvider.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF6C00)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Loading recent conditions...",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final recentPosts = socialProvider.posts.take(3).toList();

    if (recentPosts.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 40,
              color: isDark ? Colors.green[400] : Colors.green[600],
            ),
            const SizedBox(height: 12),
            Text(
              "No recent reports",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "All roads seem clear. Drive safe!",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: recentPosts.map((Post post) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(post: post),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: isDark ? 0.8 : 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author Row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundImage: post.author.imageProvider,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              post.author.name,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            post.timeAgo,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Road Name
                      Text(
                        post.roadName,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFEF6C00), // Orange theme color
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Description
                      Text(
                        post.description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.87)
                              : Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Actions Indicators
                      Row(
                        children: [
                          Icon(
                            post.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 14,
                            color: post.isLiked
                                ? Colors.red
                                : (isDark ? Colors.white54 : Colors.black54),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            post.likes.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 14,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            post.commentsCount.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (post.imageUrl != null || post.videoUrl != null) ...[
                  const SizedBox(width: 12),
                  _buildThumbnail(post.imageUrl ?? ''),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThumbnail(String imageUrl) {
    if (imageUrl.isEmpty) {
      // It's a video but no thumbnail, show a video icon placeholder
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFEF6C00).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(
            Icons.play_circle_outline,
            color: Color(0xFFEF6C00),
            size: 28,
          ),
        ),
      );
    }

    Widget imageWidget;
    if (File(imageUrl).existsSync()) {
      imageWidget = Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 20, color: Colors.grey),
      );
    } else if (imageUrl.startsWith('assets/')) {
      imageWidget = Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 20, color: Colors.grey),
      );
    } else {
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 20, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 64,
        height: 64,
        color: Colors.grey[200],
        child: imageWidget,
      ),
    );
  }
}
