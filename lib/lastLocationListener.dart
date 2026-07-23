import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:wearmokoapp/notification_handler.dart';

class LastLocationListener extends StatefulWidget {
  const LastLocationListener({super.key});

  @override
  State<LastLocationListener> createState() => _LastLocationListenerState();
}

class _LastLocationListenerState extends State<LastLocationListener> {
  StreamSubscription? _authSubscription;
  StreamSubscription? _locationSubscription;

  // Track last notified timestamp per location key to avoid spam
  final Map<String, int> _lastNotifiedTimestamps = {};
  static const int _notifyInterval = 20 * 1000; // 20 seconds

  // Store the monitoring user ID
  String? _monitoringUserId;

  @override
  void initState() {
    super.initState();

    // Check if user is already logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print("LastLocationListener: User already logged in. Starting listener.");
      _initializeListener(currentUser.uid);
    }

    // Listen for auth state changes
    _listenToAuthState();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  // -----------------------------------------------------
  // 1. Listen to Auth State Changes
  // -----------------------------------------------------
  void _listenToAuthState() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        print(
            "LastLocationListener: User logged in. Starting location listener.");
        _initializeListener(user.uid);
      } else {
        print("LastLocationListener: User logged out. Stopping listener.");
        _locationSubscription?.cancel();
        _locationSubscription = null;
        _lastNotifiedTimestamps.clear();
        _monitoringUserId = null;
      }
    });
  }

  // -----------------------------------------------------
  // 2. Initialize: Find Monitoring User First
  // -----------------------------------------------------
  Future<void> _initializeListener(String userId) async {
    try {
      // Get current user's role
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final role = userData['role'] as String?;

      // Only start listener for Monitoring Users
      if (role == 'Monitoring User') {
        print(
            "✅ Monitoring User detected - listening to Device Wearer's lastLocations");

        // Find the Device Wearer in the same circle
        final joinedCircleCode = userData['joinedCircleCode'] as String?;

        if (joinedCircleCode == null || joinedCircleCode.isEmpty) {
          print("⚠️ No circle joined yet");
          return;
        }

        // Find Device Wearer with the same circleCode
        final deviceWearerQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('circleCode', isEqualTo: joinedCircleCode)
            .where('role', isEqualTo: 'Device Wearer')
            .limit(1)
            .get();

        if (deviceWearerQuery.docs.isEmpty) {
          print("⚠️ No Device Wearer found in circle: $joinedCircleCode");
          return;
        }

        final deviceWearerId = deviceWearerQuery.docs.first.id;
        print("✅ Found Device Wearer: $deviceWearerId");

        // Store monitoring user ID (yourself)
        _monitoringUserId = userId;

        // Start listening to Device Wearer's lastLocations
        _startLocationListener(deviceWearerId);
      } else {
        print("ℹ️ Not a Monitoring User - LastLocationListener disabled");
      }
    } catch (e) {
      print("❌ Error initializing listener: $e");
    }
  }

  // -----------------------------------------------------
  // 3. Start Firestore Listener on DEVICE WEARER's lastLocations
  // -----------------------------------------------------
  void _startLocationListener(String deviceWearerId) {
    // Cancel existing listener
    _locationSubscription?.cancel();

    // Listen to changes in DEVICE WEARER's lastLocations field
    _locationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(deviceWearerId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || !snapshot.exists) return;

      final data = snapshot.data();
      if (data == null || !data.containsKey('lastLocations')) {
        print("LastLocationListener: No lastLocations field found.");
        return;
      }

      final lastLocations =
          Map<String, dynamic>.from(data['lastLocations'] ?? {});

      // Pass monitoring user ID (to send notification to them)
      if (_monitoringUserId != null) {
        _checkAndNotify(lastLocations, _monitoringUserId!);
      }
    });

    print(
        "LastLocationListener: Listening to Device Wearer's lastLocations field.");
  }

  // -----------------------------------------------------
  // 4. SEND REAL FCM NOTIFICATION VIA BACKEND
  // -----------------------------------------------------
  Future<void> _sendFCMNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      print("📤 Sending FCM notification to Monitoring User: $userId");

      final response = await http.post(
        Uri.parse("https://notifsawearmoko.onrender.com/send-notification"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "title": title,
          "body": body,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ FCM notification sent successfully to Monitoring User!");
      } else {
        print("❌ Failed to send FCM: ${response.body}");
      }
    } catch (e) {
      print("❌ Error sending FCM notification: $e");
    }
  }

  // -----------------------------------------------------
  // 5. 🆕 UPDATED: Check for New Location and ONLY Send Notifications
  // -----------------------------------------------------
  Future<void> _checkAndNotify(
      Map<String, dynamic> lastLocations, String monitoringUserId) async {
    if (lastLocations.isEmpty) {
      print("LastLocationListener: No locations available.");
      return;
    }

    try {
      // Sort locations by timestamp (newest first)
      final sortedEntries = lastLocations.entries
          .where((e) => e.value is Map<String, dynamic>)
          .toList();

      sortedEntries.sort((a, b) {
        final t1 = (a.value['timestamp'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final t2 = (b.value['timestamp'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return t2.compareTo(t1); // Newest first
      });

      if (sortedEntries.isEmpty) return;

      final latestKey = sortedEntries.first.key;
      final latestLocation =
          Map<String, dynamic>.from(sortedEntries.first.value);

      final timestamp =
          (latestLocation['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ??
              0;

      // Check if we should notify (based on 20-second interval per location key)
      final lastNotified = _lastNotifiedTimestamps[latestKey] ?? 0;
      final timeSinceLastNotification = timestamp - lastNotified;

      if (timeSinceLastNotification < _notifyInterval) {
        print("LastLocationListener: Skipping notification for key $latestKey. "
            "Last sent ${(timeSinceLastNotification / 1000).toStringAsFixed(0)} seconds ago.");
        return;
      }

      // Update last notified timestamp for this location key
      _lastNotifiedTimestamps[latestKey] = timestamp;

      // Get coordinates
      final lat = latestLocation['latitude'];
      final lon = latestLocation['longitude'];
      final landmark = latestLocation['landmark'] ?? 'Unknown location';
      final distance = (latestLocation['distance'] ?? 0.0).toStringAsFixed(2);

      if (lat == null || lon == null) {
        print("LastLocationListener: Invalid coordinates.");
        return;
      }

      // Prepare notification
      final googleMapsUrl =
          "https://www.google.com/maps/search/?api=1&query=$lat,$lon";
      const title = "📍 Device Wearer Location Update";
      final body =
          "Device Wearer is now at: $landmark ($distance km moved) $googleMapsUrl";

      print(
          "LastLocationListener: Device Wearer location changed to $landmark ($lat, $lon)!");

      // 🆕 ONLY SEND FCM NOTIFICATION (backend handles it)
      await _sendFCMNotification(
        userId: monitoringUserId,
        title: title,
        body: body,
      );

      // 🆕 ONLY SEND LOCAL NOTIFICATION (for notification tray)
      // NotificationHandler will show popup when user taps it
      NotificationHandler.showLocalNotification(
        title: title,
        body: body,
        payload: jsonEncode({
          "title": title,
          "body": body,
          "link": googleMapsUrl,
        }),
      );

      print("✅ Notifications sent! User can tap to see details.");

      // ❌ REMOVED: No more automatic popups
      // ❌ REMOVED: No more SnackBars
      // User must tap notification to see popup
    } catch (e) {
      print("LastLocationListener ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Invisible listener
  }
}
