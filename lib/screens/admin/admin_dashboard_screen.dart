import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/database_service.dart';
import 'package:image_picker/image_picker.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient _supabase = Supabase.instance.client;

  // Realtime subscription channels
  RealtimeChannel? _profilesChannel;
  RealtimeChannel? _postsChannel;
  RealtimeChannel? _bannersChannel;

  // Analytics State
  bool _isLoadingAnalytics = true;
  int _totalUsers = 0;
  int _totalPosts = 0;
  int _activeBanners = 0;
  int _suspendedUsers = 0;
  int _adminUsers = 0;

  // Users State
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoadingUsers = true;
  final TextEditingController _userSearchCtrl = TextEditingController();
  String _selectedUserFilter = 'all'; // 'all', 'admin', 'suspended', 'standard'

  // Posts State
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _filteredPosts = [];
  bool _isLoadingPosts = true;
  final TextEditingController _postsSearchCtrl = TextEditingController();

  // Banners State
  List<Map<String, dynamic>> _banners = [];
  bool _isLoadingBanners = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadAnalytics();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _userSearchCtrl.dispose();
    _postsSearchCtrl.dispose();
    _profilesChannel?.unsubscribe();
    _postsChannel?.unsubscribe();
    _bannersChannel?.unsubscribe();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;

    // Refresh tab data when switching
    switch (_tabController.index) {
      case 0:
        _loadAnalytics();
        break;
      case 1:
        _loadUsers();
        break;
      case 2:
        _loadPosts();
        break;
      case 3:
        _loadBanners();
        break;
    }
  }

  void _setupRealtimeListeners() {
    _profilesChannel = _supabase
        .channel('public:profiles-admin')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          callback: (payload) {
            if (mounted) {
              _loadAnalytics(silent: true);
              _loadUsers(silent: true);
            }
          },
        )
        .subscribe();

    _postsChannel = _supabase
        .channel('public:posts-admin')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'posts',
          callback: (payload) {
            if (mounted) {
              _loadAnalytics(silent: true);
              _loadPosts(silent: true);
            }
          },
        )
        .subscribe();

    _bannersChannel = _supabase
        .channel('public:app_banners-admin')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'app_banners',
          callback: (payload) {
            if (mounted) {
              _loadAnalytics(silent: true);
              _loadBanners(silent: true);
            }
          },
        )
        .subscribe();
  }

  // --- DATA LOADING METHODS ---

  Future<void> _loadAnalytics({bool silent = false}) async {
    if (!silent) setState(() => _isLoadingAnalytics = true);
    try {
      final usersRes = await _supabase
          .from('profiles')
          .select('id, is_admin, status');
      final postsRes = await _supabase.from('posts').select('id');
      final bannersRes = await _supabase
          .from('app_banners')
          .select('id')
          .eq('is_active', true);

      final users = List<Map<String, dynamic>>.from(usersRes);
      _totalUsers = users.length;
      _totalPosts = List<Map<String, dynamic>>.from(postsRes).length;
      _activeBanners = List<Map<String, dynamic>>.from(bannersRes).length;

      _suspendedUsers = users.where((u) => u['status'] == 'suspended').length;
      _adminUsers = users.where((u) => u['is_admin'] == true).length;
    } catch (e) {
      debugPrint("Error loading analytics: $e");
    } finally {
      if (mounted) setState(() => _isLoadingAnalytics = false);
    }
  }

  Future<void> _loadUsers({bool silent = false}) async {
    if (!silent) setState(() => _isLoadingUsers = true);
    try {
      final res = await _supabase
          .from('profiles')
          .select()
          .order('name', ascending: true);
      _users = List<Map<String, dynamic>>.from(res);
      _filterUsers(_userSearchCtrl.text);
    } catch (e) {
      _showErrorSnackBar("Error loading users: $e");
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _loadPosts({bool silent = false}) async {
    if (!silent) setState(() => _isLoadingPosts = true);
    try {
      final res = await _supabase
          .from('posts')
          .select('*, profiles!author_id(name, profile_image)')
          .order('created_at', ascending: false);
      _posts = List<Map<String, dynamic>>.from(res);
      _filterPosts(_postsSearchCtrl.text);
    } catch (e) {
      _showErrorSnackBar("Error loading posts: $e");
    } finally {
      if (mounted) setState(() => _isLoadingPosts = false);
    }
  }

  Future<void> _loadBanners({bool silent = false}) async {
    if (!silent) setState(() => _isLoadingBanners = true);
    try {
      final res = await _supabase
          .from('app_banners')
          .select()
          .order('created_at', ascending: false);
      _banners = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      _showErrorSnackBar("Error loading banners: $e");
    } finally {
      if (mounted) setState(() => _isLoadingBanners = false);
    }
  }

  // --- SEARCH/FILTER METHODS ---

  void _filterUsers(String query) {
    setState(() {
      List<Map<String, dynamic>> tempUsers = _users;

      // Apply role/status filter
      if (_selectedUserFilter == 'admin') {
        tempUsers = tempUsers.where((u) => u['is_admin'] == true).toList();
      } else if (_selectedUserFilter == 'suspended') {
        tempUsers = tempUsers.where((u) => u['status'] == 'suspended').toList();
      } else if (_selectedUserFilter == 'standard') {
        tempUsers = tempUsers
            .where(
              (u) => (u['is_admin'] != true) && (u['status'] != 'suspended'),
            )
            .toList();
      }

      if (query.isEmpty) {
        _filteredUsers = tempUsers;
      } else {
        _filteredUsers = tempUsers.where((user) {
          final name = (user['name'] as String? ?? '').toLowerCase();
          final email = (user['email'] as String? ?? '').toLowerCase();
          return name.contains(query.toLowerCase()) ||
              email.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _filterPosts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPosts = _posts;
      } else {
        _filteredPosts = _posts.where((post) {
          final road = (post['road_name'] as String? ?? '').toLowerCase();
          final desc = (post['description'] as String? ?? '').toLowerCase();
          return road.contains(query.toLowerCase()) ||
              desc.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // --- ACTIONS METHODS ---

  Future<void> _toggleAdmin(String userId, bool currentAdmin) async {
    Navigator.pop(context); // Close dialog
    try {
      await _supabase
          .from('profiles')
          .update({'is_admin': !currentAdmin})
          .eq('id', userId);
      _showSuccessSnackBar(
        currentAdmin ? "User demoted from Admin" : "User promoted to Admin",
      );
      _loadUsers();
    } catch (e) {
      _showErrorSnackBar("Failed to update admin status: $e");
    }
  }

  Future<void> _toggleSuspension(String userId, String currentStatus) async {
    Navigator.pop(context); // Close dialog
    final newStatus = currentStatus == 'suspended' ? 'active' : 'suspended';
    try {
      await _supabase
          .from('profiles')
          .update({'status': newStatus})
          .eq('id', userId);
      _showSuccessSnackBar(
        newStatus == 'suspended'
            ? "Account suspended successfully"
            : "Account reactivated",
      );
      _loadUsers();
    } catch (e) {
      _showErrorSnackBar("Failed to update status: $e");
    }
  }

  Future<void> _deletePost(String postId) async {
    try {
      await DatabaseService().deletePost(postId);
      _showSuccessSnackBar("Post deleted successfully");
      _loadPosts();
    } catch (e) {
      _showErrorSnackBar("Failed to delete post: $e");
    }
  }

  Future<void> _deleteBanner(int id) async {
    try {
      await _supabase.from('app_banners').delete().eq('id', id);
      _showSuccessSnackBar("Banner deleted successfully");
      _loadBanners();
    } catch (e) {
      _showErrorSnackBar("Failed to delete banner: $e");
    }
  }

  Future<void> _toggleBannerStatus(int id, bool currentActive) async {
    try {
      await _supabase
          .from('app_banners')
          .update({'is_active': !currentActive})
          .eq('id', id);
      _showSuccessSnackBar(
        !currentActive ? "Banner activated" : "Banner deactivated",
      );
      _loadBanners();
    } catch (e) {
      _showErrorSnackBar("Failed to update banner status: $e");
    }
  }

  Future<void> _createBanner(
    String title,
    String content,
    String severity, {
    String? imageUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      await _supabase.from('app_banners').insert({
        'title': title,
        'content': content,
        'severity': severity,
        'is_active': true,
        'created_by': user?.id,
        'image_url': imageUrl,
      });
      _showSuccessSnackBar("Announcement banner posted successfully");
      _loadBanners();
    } catch (e) {
      _showErrorSnackBar("Failed to post banner: $e");
    }
  }

  // --- SNACKBAR UTILS ---

  void _showSuccessSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(msg, style: GoogleFonts.poppins()),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: GoogleFonts.poppins())),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- DIALOGS AND BOTTOMSHEETS ---

  void _showUserActionDialog(Map<String, dynamic> user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = user['id'] as String;
    final name = user['name'] as String? ?? 'User';
    final isUserAdmin = user['is_admin'] as bool? ?? false;
    final userStatus = user['status'] as String? ?? 'active';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Perform administrative actions on this account. Be careful with modifications.",
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          // Role Change Button
          TextButton.icon(
            onPressed: () => _toggleAdmin(userId, isUserAdmin),
            icon: Icon(
              isUserAdmin ? Icons.admin_panel_settings : Icons.person_outline,
              color: Colors.blueAccent,
            ),
            label: Text(
              isUserAdmin ? "Make standard" : "Make admin",
              style: GoogleFonts.poppins(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Suspend Button
          ElevatedButton.icon(
            onPressed: () => _toggleSuspension(userId, userStatus),
            icon: Icon(
              userStatus == 'suspended' ? Icons.lock_open : Icons.block,
              color: Colors.white,
              size: 18,
            ),
            label: Text(
              userStatus == 'suspended' ? "Unban" : "Ban User",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: userStatus == 'suspended'
                  ? Colors.green
                  : Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateBannerSheet() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedSeverity = 'info';
    File? bannerImageFile;
    final picker = ImagePicker();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Broadcast Announcement",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                     // Title Input
                    TextField(
                      controller: titleCtrl,
                      maxLength: 35,
                      decoration: InputDecoration(
                        labelText: "Banner Title (Max 35)",
                        labelStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Content Input
                    TextField(
                      controller: contentCtrl,
                      maxLines: 3,
                      maxLength: 120,
                      decoration: InputDecoration(
                        labelText: "Announcement Message (Max 120)",
                        labelStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Severity Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedSeverity,
                      decoration: InputDecoration(
                        labelText: "Severity Level",
                        labelStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'info',
                          child: Text("Info (Blue)"),
                        ),
                        DropdownMenuItem(
                          value: 'warning',
                          child: Text("Warning (Orange)"),
                        ),
                        DropdownMenuItem(
                          value: 'critical',
                          child: Text("Critical (Red)"),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedSeverity = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Image Picker & Preview
                    Text(
                      "Banner Image (Optional)",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (bannerImageFile != null)
                      Stack(
                        children: [
                          Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: FileImage(bannerImageFile!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  bannerImageFile = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (picked != null) {
                            setModalState(() {
                              bannerImageFile = File(picked.path);
                            });
                          }
                        },
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(
                          "Add Image",
                          style: GoogleFonts.poppins(),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isDark ? Colors.white30 : Colors.black26,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (titleCtrl.text.isEmpty ||
                                  contentCtrl.text.isEmpty) {
                                _showErrorSnackBar("Please fill out all fields");
                                return;
                              }

                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFEF6C00),
                                    ),
                                  ),
                                ),
                              );

                              try {
                                String? imageUrl;
                                if (bannerImageFile != null) {
                                  final dbService = DatabaseService();
                                  imageUrl = await dbService.uploadMedia(
                                    bannerImageFile!,
                                    'banners',
                                  );
                                }

                                if (context.mounted) {
                                  Navigator.pop(context); // Close loading dialog
                                  Navigator.pop(context); // Close sheet
                                }

                                await _createBanner(
                                  titleCtrl.text,
                                  contentCtrl.text,
                                  selectedSeverity,
                                  imageUrl: imageUrl,
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  Navigator.pop(context); // Close loading dialog
                                }
                                _showErrorSnackBar("Failed to upload image: $e");
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007AFF),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              "Broadcast",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- SCREEN RENDERING ---

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? const Color(0xFF152238)
        : const Color(0xFFF4F6F9);
    final headerColor = isDark
        ? const Color(0xFF0D47A1)
        : const Color(0xFF007AFF);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: headerColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Admin Portal",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(
              text: "Overview",
              icon: Icon(Icons.dashboard_rounded, size: 20),
            ),
            Tab(text: "Users", icon: Icon(Icons.people_alt_rounded, size: 20)),
            Tab(text: "Content", icon: Icon(Icons.article_rounded, size: 20)),
            Tab(text: "Banners", icon: Icon(Icons.campaign_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(isDark),
          _buildUsersTab(isDark),
          _buildContentTab(isDark),
          _buildBannersTab(isDark),
        ],
      ),
      floatingActionButton: _tabController.index == 3
          ? FloatingActionButton(
              onPressed: _showCreateBannerSheet,
              backgroundColor: const Color(0xFFF97316),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // --- TAB BUILDERS ---

  Widget _buildOverviewTab(bool isDark) {
    if (_isLoadingAnalytics) {
      return const Center(child: CircularProgressIndicator());
    }

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final labelColor = isDark ? Colors.white70 : Colors.black54;
    final valueColor = isDark ? Colors.white : Colors.black87;

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "System Operations Summary",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _buildAnalyticsCard(
                  "Total Drivers",
                  _totalUsers.toString(),
                  Icons.people_rounded,
                  [const Color(0xFF007AFF), const Color(0xFF0051A8)],
                  () {
                    setState(() {
                      _selectedUserFilter = 'all';
                      _userSearchCtrl.clear();
                    });
                    _loadUsers();
                    _tabController.animateTo(1);
                  },
                ),
                _buildAnalyticsCard(
                  "Road Reports",
                  _totalPosts.toString(),
                  Icons.warning_amber_rounded,
                  [const Color(0xFFF97316), const Color(0xFFC2410C)],
                  () {
                    _tabController.animateTo(2);
                  },
                ),
                _buildAnalyticsCard(
                  "System Alerts",
                  _activeBanners.toString(),
                  Icons.campaign_rounded,
                  [const Color(0xFF10B981), const Color(0xFF047857)],
                  () {
                    _tabController.animateTo(3);
                  },
                ),
                _buildAnalyticsCard(
                  "Suspended Accounts",
                  _suspendedUsers.toString(),
                  Icons.block_flipped,
                  [const Color(0xFFEF4444), const Color(0xFFB91C1C)],
                  () {
                    setState(() {
                      _selectedUserFilter = 'suspended';
                      _userSearchCtrl.clear();
                    });
                    _loadUsers();
                    _tabController.animateTo(1);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Visual breakdown graphic
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "User Base Distribution",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: valueColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Horizontal custom bar graph representation
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 16,
                      child: Row(
                        children: [
                          // Standard users
                          Expanded(
                            flex: (_totalUsers - _adminUsers - _suspendedUsers)
                                .clamp(1, 999999),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedUserFilter = 'standard';
                                  _userSearchCtrl.clear();
                                });
                                _loadUsers();
                                _tabController.animateTo(1);
                              },
                              child: Container(color: const Color(0xFF007AFF)),
                            ),
                          ),
                          // Administrators
                          Expanded(
                            flex: _adminUsers.clamp(1, 999999),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedUserFilter = 'admin';
                                  _userSearchCtrl.clear();
                                });
                                _loadUsers();
                                _tabController.animateTo(1);
                              },
                              child: Container(color: const Color(0xFF10B981)),
                            ),
                          ),
                          // Suspended users
                          Expanded(
                            flex: _suspendedUsers.clamp(1, 999999),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedUserFilter = 'suspended';
                                  _userSearchCtrl.clear();
                                });
                                _loadUsers();
                                _tabController.animateTo(1);
                              },
                              child: Container(color: const Color(0xFFEF4444)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLegendItem(
                        "Standard",
                        const Color(0xFF007AFF),
                        labelColor,
                        () {
                          setState(() {
                            _selectedUserFilter = 'standard';
                            _userSearchCtrl.clear();
                          });
                          _loadUsers();
                          _tabController.animateTo(1);
                        },
                      ),
                      _buildLegendItem(
                        "Admin",
                        const Color(0xFF10B981),
                        labelColor,
                        () {
                          setState(() {
                            _selectedUserFilter = 'admin';
                            _userSearchCtrl.clear();
                          });
                          _loadUsers();
                          _tabController.animateTo(1);
                        },
                      ),
                      _buildLegendItem(
                        "Suspended",
                        const Color(0xFFEF4444),
                        labelColor,
                        () {
                          setState(() {
                            _selectedUserFilter = 'suspended';
                            _userSearchCtrl.clear();
                          });
                          _loadUsers();
                          _tabController.animateTo(1);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String label,
    String value,
    IconData icon,
    List<Color> colors,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.last.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    String label,
    Color color,
    Color textColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab(bool isDark) {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final valueColor = isDark ? Colors.white : Colors.black87;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _userSearchCtrl,
            onChanged: _filterUsers,
            style: GoogleFonts.poppins(color: valueColor),
            decoration: InputDecoration(
              hintText: "Search driver by name or email...",
              hintStyle: GoogleFonts.poppins(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: cardBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Filter Chips Row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip("All (${_users.length})", 'all', isDark),
                const SizedBox(width: 8),
                _buildFilterChip(
                  "Admins (${_users.where((u) => u['is_admin'] == true).length})",
                  'admin',
                  isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  "Banned (${_users.where((u) => u['status'] == 'suspended').length})",
                  'suspended',
                  isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  "Standard (${_users.where((u) => u['is_admin'] != true && u['status'] != 'suspended').length})",
                  'standard',
                  isDark,
                ),
              ],
            ),
          ),
        ),

        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadUsers,
            child: _filteredUsers.isEmpty
                ? Center(
                    child: Text(
                      "No drivers found",
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final name = user['name'] as String? ?? 'User';
                      final email = user['email'] as String? ?? 'No email';
                      final profileImage =
                          user['profile_image'] as String? ?? '';
                      final isUserAdmin = user['is_admin'] as bool? ?? false;
                      final userStatus = user['status'] as String? ?? 'active';

                      return Card(
                        color: cardBg,
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isDark ? Colors.white10 : Colors.grey[200]!,
                          ),
                        ),
                        child: ListTile(
                          onTap: () => _showUserActionDialog(user),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundImage: profileImage.startsWith('http')
                                ? NetworkImage(profileImage)
                                : const AssetImage('assets/images/logo2.jpg')
                                      as ImageProvider,
                            child: profileImage.isEmpty
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: valueColor,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isUserAdmin) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "Admin",
                                    style: GoogleFonts.poppins(
                                      color: Colors.blue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              if (userStatus == 'suspended') ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "Banned",
                                    style: GoogleFonts.poppins(
                                      color: Colors.redAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            email,
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.more_vert,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String filter, bool isDark) {
    final isSelected = _selectedUserFilter == filter;
    final selectedColor = const Color(0xFF007AFF);
    final unselectedBg = isDark ? const Color(0xFF1E293B) : Colors.grey[200]!;
    final textColor = isSelected
        ? Colors.white
        : (isDark ? Colors.white70 : Colors.black87);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUserFilter = filter;
        });
        _filterUsers(_userSearchCtrl.text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? selectedColor
                : (isDark ? Colors.white10 : Colors.transparent),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildContentTab(bool isDark) {
    if (_isLoadingPosts) {
      return const Center(child: CircularProgressIndicator());
    }

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final valueColor = isDark ? Colors.white : Colors.black87;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _postsSearchCtrl,
            onChanged: _filterPosts,
            style: GoogleFonts.poppins(color: valueColor),
            decoration: InputDecoration(
              hintText: "Search posts by road name or content...",
              hintStyle: GoogleFonts.poppins(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: cardBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadPosts,
            child: _filteredPosts.isEmpty
                ? Center(
                    child: Text(
                      "No posts found",
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredPosts.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemBuilder: (context, index) {
                      final post = _filteredPosts[index];
                      final postId = post['id'].toString();
                      final roadName =
                          post['road_name'] as String? ?? 'Unknown Road';
                      final description = post['description'] as String? ?? '';
                      final author = post['profiles'] as Map? ?? {};
                      final authorName = author['name'] as String? ?? 'Driver';
                      final imageUrl = post['image_url'] as String?;

                      return Card(
                        color: cardBg,
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isDark ? Colors.white10 : Colors.grey[200]!,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundImage:
                                        (author['profile_image'] as String? ??
                                                '')
                                            .startsWith('http')
                                        ? NetworkImage(author['profile_image'])
                                        : null,
                                    child:
                                        (author['profile_image'] as String? ??
                                                '')
                                            .isEmpty
                                        ? const Icon(Icons.person, size: 14)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      authorName,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                  ),
                                  // Delete Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: isDark
                                              ? const Color(0xFF2C2C2C)
                                              : Colors.white,
                                          title: const Text("Delete Post"),
                                          content: const Text(
                                            "Are you sure you want to delete this road condition report? This cannot be undone.",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deletePost(postId);
                                              },
                                              child: const Text(
                                                "Delete",
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                roadName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFF97316),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: GoogleFonts.poppins(
                                  color: valueColor,
                                  fontSize: 13,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const SizedBox.shrink(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannersTab(bool isDark) {
    if (_isLoadingBanners) {
      return const Center(child: CircularProgressIndicator());
    }

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final valueColor = isDark ? Colors.white : Colors.black87;

    return RefreshIndicator(
      onRefresh: _loadBanners,
      child: _banners.isEmpty
          ? Center(
              child: Text(
                "No announcements posted yet.\nTap the + button to broadcast.",
                style: GoogleFonts.poppins(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: _banners.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final banner = _banners[index];
                final id = banner['id'] as int;
                final title = banner['title'] as String? ?? 'Announcement';
                final content = banner['content'] as String? ?? '';
                final severity = banner['severity'] as String? ?? 'info';
                final isActive = banner['is_active'] as bool? ?? true;

                Color badgeColor;
                switch (severity.toLowerCase()) {
                  case 'critical':
                    badgeColor = Colors.redAccent;
                    break;
                  case 'warning':
                    badgeColor = Colors.orangeAccent;
                    break;
                  case 'info':
                  default:
                    badgeColor = Colors.blueAccent;
                    break;
                }

                return Card(
                  color: cardBg,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? Colors.white10 : Colors.grey[200]!,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                severity.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: badgeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                // Toggle active state
                                Switch.adaptive(
                                  value: isActive,
                                  activeTrackColor: Colors.green,
                                  onChanged: (val) =>
                                      _toggleBannerStatus(id, isActive),
                                ),
                                // Delete button
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => _deleteBanner(id),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: valueColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          content,
                          style: GoogleFonts.poppins(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                        if (banner['image_url'] != null && (banner['image_url'] as String).isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              banner['image_url'] as String,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
