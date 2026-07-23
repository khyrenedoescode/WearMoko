import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // ✅ ADD THIS
import 'package:wearmokoapp/devicewearer/devicedash1.dart';
import 'package:wearmokoapp/monitorer/monihome.dart';
import 'package:wearmokoapp/monitorer/verifycodemoni.dart';
import 'package:wearmokoapp/permissionscreen.dart';
import 'package:wearmokoapp/location_tracking_service.dart';
import 'package:wearmokoapp/device_wearer_location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  // ✅ NEW: Update FCM Token
  Future<void> _updateFCMToken(String userId) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcmToken': fcmToken});

        print('✅ FCM token updated on app start: $fcmToken');
      } else {
        print('⚠️ FCM token is null');
      }
    } catch (e) {
      print('❌ Error updating FCM token: $e');
    }
  }

  Future<void> _checkCurrentUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool shouldRemember = prefs.getBool('rememberMe') ?? false;
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && !shouldRemember) {
      print("User found, but 'Remember Me' was OFF. Logging out...");
      await FirebaseAuth.instance.signOut();
      user = null;
      await prefs.remove('rememberMe');
    }

    if (user == null) {
      if (mounted) {
        setState(() => _isChecking = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PermissionsScreen()),
        );
      }
      return;
    }

    try {
      // ✅ UPDATE FCM TOKEN FIRST (before fetching user doc)
      await _updateFCMToken(user.uid);

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        await prefs.remove('rememberMe');
        if (mounted) {
          setState(() => _isChecking = false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PermissionsScreen()),
          );
        }
        return;
      }

      var data = userDoc.data() as Map<String, dynamic>?;
      String? role = data?['role'];

      // ✅ START LOCATION TRACKING BASED ON ROLE
      if (role == 'Monitoring User') {
        await _startLocationTrackingForMonitoringUser();
      } else if (role == 'Device Wearer') {
        await _startLocationTrackingForDeviceWearer();
      }

      // --- Redirect based on role ---
      if (role == 'Device Wearer') {
        if (mounted) {
          setState(() => _isChecking = false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DeviceDash()),
          );
        }
      } else if (role == 'Monitoring User') {
        bool isBlocked = data?['isBlocked'] ?? false;

        if (isBlocked) {
          if (mounted) {
            setState(() => _isChecking = false);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Moni1()),
            );
          }
          return;
        }

        String? joinedCircleCode = data?['joinedCircleCode'];
        if (joinedCircleCode == null || joinedCircleCode.isEmpty) {
          if (mounted) {
            setState(() => _isChecking = false);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Moni1()),
            );
          }
        } else {
          if (mounted) {
            setState(() => _isChecking = false);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MoniHome()),
            );
          }
        }
      } else {
        await FirebaseAuth.instance.signOut();
        await prefs.remove('rememberMe');
        if (mounted) {
          setState(() => _isChecking = false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PermissionsScreen()),
          );
        }
      }
    } catch (e) {
      print("Error in AuthWrapper: $e");
      await FirebaseAuth.instance.signOut();
      await prefs.remove('rememberMe');
      if (mounted) {
        setState(() => _isChecking = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PermissionsScreen()),
        );
      }
    }
  }

  /// ✅ Start location tracking for Monitoring Users
  Future<void> _startLocationTrackingForMonitoringUser() async {
    try {
      await LocationTrackingService().startTracking();
      print('✅ Monitoring User location tracking started in AuthWrapper');
    } catch (e) {
      print('❌ Error starting Monitoring User location tracking: $e');
    }
  }

  /// ✅ Start location tracking for Device Wearers
  Future<void> _startLocationTrackingForDeviceWearer() async {
    try {
      await DeviceWearerLocationService().startTracking();
      print('✅ Device Wearer location tracking started in AuthWrapper');
    } catch (e) {
      print('❌ Error starting Device Wearer location tracking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isChecking
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFEAA647),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
