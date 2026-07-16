import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppBannersWidget extends StatefulWidget {
  const AppBannersWidget({super.key});

  @override
  State<AppBannersWidget> createState() => _AppBannersWidgetState();
}

class _AppBannersWidgetState extends State<AppBannersWidget> {
  final List<int> _dismissedBannerIds = [];
  Future<List<Map<String, dynamic>>>? _bannersFuture;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  void _loadBanners() {
    setState(() {
      _bannersFuture = Supabase.instance.client
          .from('app_banners')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .then((data) => List<Map<String, dynamic>>.from(data));
    });
  }

  Color _getSeverityColor(String severity, bool isDark) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.redAccent;
      case 'warning':
        return Colors.orangeAccent;
      case 'info':
      default:
        return isDark ? Colors.blue[300]! : const Color(0xFF007AFF);
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.report_gmailerrorred_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'info':
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _bannersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink(); // Silent load
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        // Filter out session-dismissed banners
        final activeBanners = snapshot.data!
            .where((banner) => !_dismissedBannerIds.contains(banner['id']))
            .toList();

        if (activeBanners.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          height: 140, // Increased height to prevent overflow and support images
          child: PageView.builder(
            itemCount: activeBanners.length,
            itemBuilder: (context, index) {
              final banner = activeBanners[index];
              final bannerId = banner['id'] as int;
              final severity = banner['severity'] as String? ?? 'info';
              final title = banner['title'] as String? ?? 'Announcement';
              final content = banner['content'] as String? ?? '';
              final imageUrl = banner['image_url'] as String?;
              
              final accentColor = _getSeverityColor(severity, isDark);
              final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

              return GestureDetector(
                onTap: () {
                  // Show full details in a dialog when tapped
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Row(
                        children: [
                          Icon(_getSeverityIcon(severity), color: accentColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (imageUrl != null && imageUrl.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Text(
                              content,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Close",
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  color: cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: accentColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Accent line on left side
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 6,
                            color: accentColor,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 40, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                _getSeverityIcon(severity),
                                color: accentColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      title,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      content,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: isDark ? Colors.white70 : Colors.black54,
                                        height: 1.3,
                                      ),
                                      maxLines: imageUrl != null && imageUrl.isNotEmpty ? 3 : 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    imageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image, size: 24),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Dismiss Button
                        Positioned(
                          right: 8,
                          top: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _dismissedBannerIds.add(bannerId);
                              });
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ),
                        // Swipe indicator if multiple banners
                        if (activeBanners.length > 1)
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Text(
                              "${index + 1}/${activeBanners.length}",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white30 : Colors.black38,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
            },
          ),
        );
      },
    );
  }
}
