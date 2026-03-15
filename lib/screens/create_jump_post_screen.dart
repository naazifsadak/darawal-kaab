import 'dart:io';
import '../services/database_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/social_provider.dart';
import '../providers/user_provider.dart';

class CreateJumpPostScreen extends StatefulWidget {
  const CreateJumpPostScreen({super.key});

  @override
  State<CreateJumpPostScreen> createState() => _CreateJumpPostScreenState();
}

class _CreateJumpPostScreenState extends State<CreateJumpPostScreen> {
  final _descriptionController = TextEditingController();
  final _customRoadController = TextEditingController();
  String? _selectedRoad;
  File? _imageFile;
  File? _videoFile;
  final _picker = ImagePicker();
  bool _isLoading = false;

  // Mock list of roads
  final List<String> _roads = [
    'Makka Al Mukarama Road',
    'Heart of Mogadishu (Wadnaha)',
    'Sodonka Road',
    'Warshadaha Road',
    'Jidka 21 October',
    'Digfer Road',
    'Liido Road',
    'Airport Road',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _customRoadController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _videoFile = null; // Clear video if image is picked
      });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final pickedFile = await _picker.pickVideo(source: source);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
        _imageFile = null; // Clear image if video is picked
      });
    }
  }

  void _showMediaSourceActionSheet(BuildContext context) {
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              child: const Text('Take Photo'),
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Choose Photo from Gallery'),
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Take Video'),
              onPressed: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.camera);
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Choose Video from Gallery'),
              onPressed: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.gallery);
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose Photo from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Take Video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Choose Video from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _submitPost() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final socialProvider = Provider.of<SocialProvider>(context, listen: false);

    String roadName = _selectedRoad ?? '';
    if (_selectedRoad == 'Other') {
      if (_customRoadController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the road name')),
        );
        return;
      }
      roadName = _customRoadController.text.trim();
    } else if (_selectedRoad == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a road')));
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dbService = DatabaseService();

      // Ensure profile exists for this user (handles legacy users)
      await dbService.ensureProfileExists(
        id: userProvider.user.id,
        email: userProvider.email,
        name: userProvider.name,
        profileImage: userProvider.profileImage,
      );

      String? imageUrl;
      String? videoUrl;

      // Upload Media
      if (_imageFile != null) {
        imageUrl = await dbService.uploadMedia(_imageFile!, 'post-images');
      } else if (_videoFile != null) {
        videoUrl = await dbService.uploadMedia(_videoFile!, 'post-videos');
      }

      // Create Post
      await dbService.createPost(
        roadName: roadName,
        description: _descriptionController.text.trim(),
        authorId:
            userProvider.user.id, // Ensure userProvider.user.id is correct
        imageUrl: imageUrl,
        videoUrl: videoUrl,
      );

      // Refresh Feed
      await socialProvider.refreshFeed();

      // Update local profile stats synchronously
      userProvider.incrementPostsCount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jump Post for $roadName Created Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Return to feed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Create Jump Post",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Road Selection Dropdown
            Text(
              "Select Road",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600, // Semi-bold
                color: Colors.black, // Pure black
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedRoad,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1E88E5)),
                ),
              ),
              hint: Text(
                "Choose a road...",
                style: GoogleFonts.poppins(color: Colors.grey[400]),
              ),
              items: _roads.map((road) {
                return DropdownMenuItem(
                  value: road,
                  child: Text(
                    road,
                    style: GoogleFonts.poppins(
                      color: Colors.black, // Strong text
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRoad = value;
                });
              },
            ),
            if (_selectedRoad == 'Other') ...[
              const SizedBox(height: 20),
              TextFormField(
                controller: _customRoadController,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  hintText: "Enter Road Name",
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.black,
                      width: 2,
                    ), // Black focus
                  ),
                ),
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              cursorColor: Colors.black, // Visible cursor
              decoration: InputDecoration(
                hintText: "Description",
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[600], // Darker hint
                  fontWeight: FontWeight.w500,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Colors.black,
                    width: 2,
                  ), // Black focus
                ),
              ),
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.w600, // Semi-bold input
              ),
            ),
            const SizedBox(height: 20),

            // Media Picker Area
            GestureDetector(
              onTap: () => _showMediaSourceActionSheet(context),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.grey[400]!,
                    width: 1.5,
                  ), // Stronger border
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageFile == null && _videoFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: Colors.grey[700], // Darker icon
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Tap to add photo or video",
                            style: GoogleFonts.poppins(
                              color: Colors.black87, // Darker text
                              fontWeight: FontWeight.bold, // Bold
                            ),
                          ),
                        ],
                      )
                    : _imageFile != null
                    ? Stack(
                        children: [
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _imageFile = null;
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
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        // Video Preview Placeholder
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.videocam,
                                  size: 50,
                                  color: Colors.blue,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Video Selected",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _videoFile = null;
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
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 40),

            // Post Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5), // Main Blue
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Post",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
