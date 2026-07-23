import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:wearmokoapp/devicewearer/devicedash1.dart';
import 'package:wearmokoapp/devicewearer/deviceemergencycontact.dart';
import 'package:wearmokoapp/devicewearer/deviceprofile.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';

class DeviceAlert extends StatefulWidget {
  const DeviceAlert({super.key});

  @override
  State<DeviceAlert> createState() => _DeviceAlertState();
}

class _DeviceAlertState extends State<DeviceAlert> {
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserProfileImage();
    _getFCMToken();
  }

  Future<void> _fetchUserProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()!.containsKey('profileImage') && mounted) {
        setState(() {
          _profileImageUrl = doc['profileImage'];
        });
      }
    }
  }

  Future<LocationData?> getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return null;
    }
    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return null;
    }
    return await location.getLocation();
  }

  Future<void> sendEmergencyAlert(String message) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('https://notifsawearmoko.onrender.com/send-notification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': user.uid,
        'title': 'Emergency Alert',
        'body': message,
      }),
    );

    if (response.statusCode == 200) {
      print('✅ Emergency alert sent successfully!');
    } else {
      print('❌ Failed to send emergency alert: ${response.body}');
    }
  }

  void navigateToNextPage(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DeviceEmergencyContact(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
        maintainState: true,
      ),
    );
  }

  Future<void> _getFCMToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      print("FCM Token: $token");

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': token,
        });
      }
    } catch (e) {
      print("Error fetching FCM token: $e");
    }
  }

  Future<Map<String, double>?> getLocationFromRealtimeDB() async {
    try {
      print('🔍 Attempting to fetch location from Realtime DB...');
      final dbRef = FirebaseDatabase.instance.ref('GPSLocation');
      final snapshot = await dbRef.get();

      if (snapshot.exists) {
        print('✅ Snapshot exists');
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        print('📍 Raw data: $data');

        final lat = double.tryParse(data['latitude'].toString());
        final lon = double.tryParse(data['longitude'].toString());

        print('📍 Parsed - Latitude: $lat, Longitude: $lon');

        if (lat != null && lon != null) {
          return {'latitude': lat, 'longitude': lon};
        } else {
          print('⚠️ Latitude or Longitude is null after parsing');
        }
      } else {
        print('⚠️ Snapshot does not exist in Realtime DB');
      }
    } catch (e, stackTrace) {
      print('❌ Error fetching location from Realtime DB: $e');
      print('❌ Stack trace: $stackTrace');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final titleStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w900,
      fontSize: screenWidth * 0.055,
      color: const Color(0xFF000000),
    );

    final bodyStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w400,
      fontSize: screenWidth * 0.038,
      color: Colors.black,
      height: 1.2,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4B315),
        elevation: 1,
        shadowColor: const Color(0xFFA5A5A5),
        title: Text(
          'Alert',
          style: titleStyle,
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // --- Emergency Alert Button ---
              GestureDetector(
                onTap: () async {
                  print("🚨 ========================================");
                  print("🚨 Emergency button tapped");
                  print("🚨 ========================================");

                  // Step 1: Check if user is logged in
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) {
                    print('❌ No user logged in');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('No user logged in',
                            style: GoogleFonts.poppins()),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  print('✅ User logged in: ${currentUser.uid}');

                  try {
                    // Step 2: Get user document
                    print('🔍 Fetching user document...');
                    final userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .get();

                    if (!userDoc.exists) {
                      print('❌ User document does not exist');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('User data not found',
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    print('✅ User document found');

                    // Step 3: Check emergency contact
                    final userData = userDoc.data();
                    print('📄 User data keys: ${userData?.keys.toList()}');

                    if (userData == null ||
                        !userData.containsKey('selectedEmergencyContactId')) {
                      print('❌ No emergency contact selected');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please add an emergency contact first',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    final contactUid = userData['selectedEmergencyContactId'];
                    if (contactUid == null || contactUid.toString().isEmpty) {
                      print('❌ Emergency contact ID is empty or null');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Emergency contact ID is invalid',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    print('✅ Emergency contact ID: $contactUid');

                    // Step 4: Get location
                    print('🔍 Fetching location from Realtime DB...');
                    final location = await getLocationFromRealtimeDB();

                    String message = "I am in danger! Please help.";
                    String locationUrl = "Location not available.";

                    if (location != null) {
                      final lat = location['latitude'];
                      final lon = location['longitude'];

                      print('📍 Location received: lat=$lat, lon=$lon');

                      if (lat != null &&
                          lon != null &&
                          lat != 0.0 &&
                          lon != 0.0) {
                        locationUrl =
                            "https://www.google.com/maps/search/?api=1&query=$lat,$lon";
                        message += " My location: $locationUrl";
                        print('✅ Location URL created: $locationUrl');
                      } else {
                        print('⚠️ Location coordinates are null or zero');
                      }
                    } else {
                      print('⚠️ No location data retrieved from Realtime DB');
                    }

                    // Step 5: Send notification
                    print('📤 ========================================');
                    print('📤 Preparing to send notification');
                    print('📤 Target User ID: $contactUid');
                    print('📤 Message: $message');
                    print('📤 ========================================');

                    final response = await http.post(
                      Uri.parse(
                          "https://notifsawearmoko.onrender.com/send-notification"),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({
                        "userId": contactUid,
                        "title": "Emergency Alert",
                        "body": message,
                      }),
                    );

                    print('📥 Response status: ${response.statusCode}');
                    print('📥 Response body: ${response.body}');

                    if (!mounted) return;

                    if (response.statusCode == 200) {
                      print('✅ Emergency notification sent successfully!');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '✅ Emergency alert sent!',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } else {
                      print('❌ Server returned error status');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to send alert: ${response.body}',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  } catch (e, stackTrace) {
                    print('❌❌❌ CRITICAL ERROR ❌❌❌');
                    print('Error type: ${e.runtimeType}');
                    print('Error message: $e');
                    print('Stack trace:');
                    print(stackTrace);
                    print('❌❌❌ END ERROR ❌❌❌');

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error: ${e.toString()}',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                },
                child: Container(
                  width: screenWidth * 0.75,
                  height: screenWidth * 0.75,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 212, 152, 0.25),
                    border:
                        Border.all(color: const Color(0xFFA9A298), width: 1.5),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(12, 12, 13, 0.1),
                        offset: Offset(0, 1),
                        blurRadius: 4,
                      ),
                      BoxShadow(
                        color: Color.fromRGBO(12, 12, 13, 0.05),
                        offset: Offset(0, 1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/pushalert.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),

              // --- Alert Tap text ---
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: bodyStyle,
                  children: [
                    TextSpan(
                      text: 'Tap the circle ',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: screenWidth * 0.038,
                      ),
                    ),
                    TextSpan(
                      text: 'to send an SOS alert, or ',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w400,
                        fontSize: screenWidth * 0.038,
                      ),
                    ),
                    const TextSpan(text: '\n'),
                    TextSpan(
                      text: 'press and hold.',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: screenWidth * 0.038,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // --- Rectangle for Adding ---
              GestureDetector(
                onTap: () => navigateToNextPage(context),
                child: Container(
                  width: double.infinity,
                  height: screenHeight * 0.11,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9F2),
                    border: Border.all(
                      color: const Color.fromRGBO(153, 153, 153, 0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: screenWidth * 0.11,
                        height: screenWidth * 0.11,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : const AssetImage('assets/userdash.png')
                                    as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Text(
                        'Tap to add emergency contact',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w400,
                          fontSize: screenWidth * 0.037,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 1.5,
            color: const Color(0xFFBBB4B4),
          ),
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
                    targetPage: const DeviceDash(),
                    isCurrentPage: false,
                  ),
                  _buildBottomNavItem(
                    context,
                    iconAsset: 'assets/alert3.png',
                    label: 'Alert',
                    targetPage: const DeviceAlert(),
                    isCurrentPage: true,
                  ),
                  _buildBottomNavItem(
                    context,
                    iconAsset: 'assets/user2.png',
                    label: 'Profile',
                    targetPage: const DeviceProfile(),
                    isCurrentPage: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(BuildContext context,
      {required String iconAsset,
      required String label,
      required Widget targetPage,
      required bool isCurrentPage}) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        if (isCurrentPage) return;
        Navigator.pushReplacement(
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
            width: screenWidth * 0.08,
            height: screenWidth * 0.08,
            fit: BoxFit.contain,
          ),
          SizedBox(height: screenWidth * 0.01),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: screenWidth * 0.035,
              color: isCurrentPage ? const Color(0xFF543509) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
