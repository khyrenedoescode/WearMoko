import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:wearmokoapp/monitorer/monieditprofile.dart';
import 'package:wearmokoapp/monitorer/monihome.dart';
import 'package:wearmokoapp/monitorer/monilocation.dart';
import 'package:wearmokoapp/monitorer/monisettings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class Moniprof extends StatefulWidget {
  const Moniprof({super.key});

  @override
  _MoniprofState createState() => _MoniprofState();
}

class _MoniprofState extends State<Moniprof> {
  String fullName = '';
  String email = '';
  List<Map<String, String>> videoUrls = [];
  String? _profileImageUrl;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _getUserData();
    fetchVideosFromCloudinary();

    // 🔄 AUTO-REFRESH: Check for new videos every 5 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        fetchVideosFromCloudinary();
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel(); // Stop timer when page is closed
    super.dispose();
  }

  Future<void> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          final data = userDoc.data() as Map<String, dynamic>;

          setState(() {
            final firstName = data['firstName'] ?? '';
            final lastName = data['lastName'] ?? '';
            fullName = '$firstName $lastName'.trim();
            email = user.email ?? 'No email';
            _profileImageUrl = data['profileImage'];
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
        if (mounted) {
          setState(() {
            fullName = 'User';
            email = 'No email';
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          fullName = 'User';
          email = 'No email';
        });
      }
    }
  }

  Future<void> fetchVideosFromCloudinary() async {
    const cloudName = 'dgolllpox';
    const apiKey = '799486126273247';
    const apiSecret = 'CziKSdHKng5w3TFDUCfjAQOhN0U';
    final basicAuth =
        'Basic ${base64Encode(utf8.encode('$apiKey:$apiSecret'))}';

    final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/resources/video?max_results=500');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': basicAuth},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (mounted) {
          setState(() {
            videoUrls = List<Map<String, String>>.from(
              (data['resources'] as List).map((resource) {
                String videoUrl = resource['secure_url'] as String;

                String thumbnailUrl = videoUrl.replaceFirst(
                  '/upload/',
                  '/upload/w_200,h_150,c_fill,q_auto/',
                );
                thumbnailUrl =
                    '${thumbnailUrl.substring(0, thumbnailUrl.lastIndexOf('.'))}.jpg';

                return {
                  'url': videoUrl,
                  'date': resource['created_at'] as String,
                  'thumbnail': thumbnailUrl,
                };
              }),
            );
          });
        }
      } else {
        print('Failed to fetch videos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching videos: $e');
    }
  }

  String _formatDate(String isoDate) {
    try {
      final DateTime dt = DateTime.parse(isoDate);
      return DateFormat('MMMM d, y').format(dt);
    } catch (e) {
      return isoDate.split("T").first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const MoniSettings(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return child;
                  },
                  transitionDuration: Duration.zero,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Image.asset(
                'assets/settings.png',
                width: 25,
                height: 25,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchVideosFromCloudinary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildProfileHeader(context),
              _buildVideosSection(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1.5, color: const Color(0xFFBBB4B4)),
          BottomAppBar(
            color: Colors.white,
            elevation: 8,
            child: SizedBox(
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomNavItem(
                    context,
                    iconAsset: 'assets/home.png',
                    label: 'Home',
                    targetPage: const MoniHome(),
                    isCurrentPage: false,
                  ),
                  _buildBottomNavItem(
                    context,
                    iconAsset: 'assets/location3.png',
                    label: 'Location',
                    targetPage: const MoniLoc(),
                    isCurrentPage: false,
                  ),
                  _buildBottomNavItem(
                    context,
                    iconAsset: 'assets/user3.png',
                    label: 'Profile',
                    targetPage: const Moniprof(),
                    isCurrentPage: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              fit: BoxFit.cover,
              image: _profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : const AssetImage('assets/userdash.png') as ImageProvider,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          fullName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          email,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w300,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const MoniEdit(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return child;
                },
                transitionDuration: Duration.zero,
              ),
            );
          },
          child: Container(
            width: 235,
            height: 25,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFF9B9595),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Text(
                'Edit Profile',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildVideosSection(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 30,
          decoration: const BoxDecoration(
            color: Color.fromRGBO(217, 217, 217, 0.21),
            border: Border.symmetric(
              horizontal: BorderSide(
                color: Color(0xFF9B9595),
                width: 0.5,
              ),
            ),
          ),
          child: Center(
            child: Text(
              'Videos',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
          ),
        ),
        videoUrls.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(50.0),
                child: Center(child: CircularProgressIndicator()),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: videoUrls.length,
                itemBuilder: (context, index) {
                  final videoItem = videoUrls[index];
                  final videoUrl = videoItem['url']!;
                  final uploadedDate = videoItem['date']!;
                  final thumbnailUrl = videoItem['thumbnail']!;
                  final formattedDate = _formatDate(uploadedDate);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 23.0, vertical: 15.0),
                    leading: Container(
                      width: 100,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(thumbnailUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          color: Colors.white70,
                          size: 30,
                        ),
                      ),
                    ),
                    title: Text(
                      'Latest Video ${index + 1}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      'Recorded: $formattedDate',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w300,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerScreen(
                            videoUrl: videoUrl,
                            date: formattedDate,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ],
    );
  }

  Widget _buildBottomNavItem(BuildContext context,
      {required String iconAsset,
      required String label,
      required Widget targetPage,
      required bool isCurrentPage}) {
    return GestureDetector(
      onTap: () {
        if (isCurrentPage) return;
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => targetPage,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return child;
            },
            transitionDuration: Duration.zero,
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconAsset,
            width: 30,
            height: 30,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isCurrentPage ? const Color(0xFF543509) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String date;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.date,
  });

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        _controller.play();
      }).catchError((error) {
        print("Error initializing video player: $error");
        if (mounted) setState(() => _isLoading = false);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.date,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : Text(
                    'Error: Could not play video.',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
