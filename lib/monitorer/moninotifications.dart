import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class Moninotif extends StatefulWidget {
  const Moninotif({super.key});

  @override
  State<Moninotif> createState() => _MoninotifState();
}

class _MoninotifState extends State<Moninotif> {
  bool adminDisabledNotifications = false;
  List<Map<String, dynamic>> lastLocations = [];
  String? _deviceWearerId;

  // Notification throttle
  int _lastNotifiedTimestamp = 0;
  static const int _notifyInterval = 60 * 60 * 1000; // 1 hour

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  StreamSubscription<QuerySnapshot>? _deviceWearerSub;

  @override
  void initState() {
    super.initState();
    _listenUserDoc();
  }

  // ✅ Listen to Monitoring User's document
  void _listenUserDoc() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) async {
      if (!mounted || !doc.exists) return;

      final data = doc.data()!;

      setState(() {
        adminDisabledNotifications = !(data['notificationEnabled'] ?? true);
      });

      final joinedCircleCode = data['joinedCircleCode'] as String?;

      if (joinedCircleCode != null && joinedCircleCode.isNotEmpty) {
        await _findAndListenToDeviceWearer(joinedCircleCode);
      } else {
        setState(() {
          lastLocations = [];
          _deviceWearerId = null;
        });
        _deviceWearerSub?.cancel();
      }
    });
  }

  // ✅ Find Device Wearer and listen to their lastLocations
  Future<void> _findAndListenToDeviceWearer(String circleCode) async {
    try {
      _deviceWearerSub?.cancel();

      final deviceWearerQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Device Wearer')
          .where('circleCode', isEqualTo: circleCode)
          .limit(1)
          .get();

      if (deviceWearerQuery.docs.isEmpty) {
        print('⚠️ No Device Wearer found in circle: $circleCode');
        setState(() {
          lastLocations = [];
          _deviceWearerId = null;
        });
        return;
      }

      _deviceWearerId = deviceWearerQuery.docs.first.id;
      print('✅ Found Device Wearer for notifications: $_deviceWearerId');

      // ✅ Listen to Device Wearer's document for real-time updates
      _deviceWearerSub = FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Device Wearer')
          .where('circleCode', isEqualTo: circleCode)
          .snapshots()
          .listen((snapshot) {
        if (!mounted || snapshot.docs.isEmpty) return;

        final deviceWearerData = snapshot.docs.first.data();

        final locationsMap =
            deviceWearerData['lastLocations'] as Map<String, dynamic>?;

        if (locationsMap != null && locationsMap.isNotEmpty) {
          // 🆕 Filter only valid Map entries
          final validEntries = locationsMap.entries
              .where((e) => e.value is Map<String, dynamic>)
              .toList();

          print('📍 Processing ${validEntries.length} location entries');

          final locations = validEntries.map((e) {
            final loc = e.value as Map<String, dynamic>;

            // Convert Timestamp to milliseconds
            int tsMillis = 0;
            final ts = loc['timestamp'];
            if (ts is Timestamp) {
              tsMillis = ts.millisecondsSinceEpoch;
            } else if (ts is int) {
              tsMillis = ts;
            }

            // 🆕 Get distance as double (this is the incremental distance for this move)
            double distance = 0.0;
            if (loc['distance'] != null) {
              if (loc['distance'] is num) {
                distance = (loc['distance'] as num).toDouble();
              } else if (loc['distance'] is String) {
                distance = double.tryParse(loc['distance']) ?? 0.0;
              }
            }

            // 🆕 Get savedBy info for debugging
            final savedBy = loc['savedBy'] ?? 'Unknown';

            return {
              'latitude': loc['latitude']?.toString() ?? 'N/A',
              'longitude': loc['longitude']?.toString() ?? 'N/A',
              'timestamp': tsMillis,
              'message': loc['landmark'] ?? 'Unknown location',
              'distance': distance, // Incremental distance in km
              'savedBy': savedBy, // For debugging
            };
          }).toList();

          // 🆕 Sort by timestamp (newest first)
          locations.sort((a, b) =>
              (b['timestamp'] as int).compareTo(a['timestamp'] as int));

          // 🆕 Take only 10 most recent
          final top10 = locations.take(10).toList();

          print('✅ Showing ${top10.length} most recent locations');
          for (var i = 0; i < top10.length && i < 3; i++) {
            print(
                '   ${i + 1}. ${top10[i]['message']} - ${(top10[i]['distance'] as double).toStringAsFixed(2)} km [${top10[i]['savedBy']}]');
          }

          setState(() {
            lastLocations = top10;
          });

          // Send notification for newest location if interval passed
          if (top10.isNotEmpty && !adminDisabledNotifications) {
            final latest = top10.first;
            final ts = latest['timestamp'] as int;
            if (ts - _lastNotifiedTimestamp > _notifyInterval) {
              _sendLocationNotification(latest);
              _lastNotifiedTimestamp = ts;
            }
          }
        } else {
          print('⚠️ No valid locations in lastLocations map');
          setState(() {
            lastLocations = [];
          });
        }
      });
    } catch (e) {
      print('❌ Error finding Device Wearer: $e');
      setState(() {
        lastLocations = [];
        _deviceWearerId = null;
      });
    }
  }

  Future<void> _sendLocationNotification(Map<String, dynamic> location) async {
    try {
      final lat = location['latitude'];
      final lon = location['longitude'];
      final googleMapsUrl = (lat != null && lon != null)
          ? "https://www.google.com/maps/search/?api=1&query=$lat,$lon"
          : "Location not available.";

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Monitoring User')
          .where('isLoggedIn', isEqualTo: true)
          .get();

      for (var doc in usersSnapshot.docs) {
        await _notifyUser(
          userId: doc.id,
          title: "📍 New Location Update",
          body: "A device has a new location. Tap to view.",
          link: googleMapsUrl,
        );
      }
    } catch (e) {
      print("❌ Error sending location notifications: $e");
    }
  }

  Future<bool> _notifyUser({
    required String userId,
    required String title,
    required String body,
    required String link,
  }) async {
    final url =
        Uri.parse("https://notifsawearmoko.onrender.com/send-notification");
    final requestBody = jsonEncode({
      "userId": userId,
      "title": title,
      "body": "$body\n$link",
    });

    try {
      final response = await http
          .post(url,
              headers: {"Content-Type": "application/json"}, body: requestBody)
          .timeout(const Duration(seconds: 25));

      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error notifying $userId: $e");
      return false;
    }
  }

  String formatTimestamp(int timestampMillis) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    return DateFormat('MMM d • hh:mm a').format(date);
  }

  Widget _buildLocationCard(Map<String, dynamic> loc, int index) {
    final message = loc['message'] ?? 'Location update';
    final tsMillis = loc['timestamp'] as int?;
    final lat = loc['latitude'];
    final lon = loc['longitude'];
    final distance = (loc['distance'] as num?)?.toDouble() ?? 0.0;
    final savedBy = loc['savedBy'] ?? 'Unknown';

    final googleMapsUrl = (lat != null && lon != null)
        ? "https://www.google.com/maps/search/?api=1&query=$lat,$lon"
        : null;

    // 🆕 Determine if "Still at" or "Last stop at"
    String locationTitle = "Last stop at $message";
    if (index > 0) {
      final prevLocation = lastLocations[index - 1];
      final prevMessage = prevLocation['message'] ?? '';
      if (prevMessage == message) {
        locationTitle = "Still at $message";
      }
    }

    return GestureDetector(
      onTap: () async {
        if (googleMapsUrl != null &&
            await canLaunchUrl(Uri.parse(googleMapsUrl))) {
          await launchUrl(Uri.parse(googleMapsUrl),
              mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Location not available")),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF4B315),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: const Icon(
                Icons.location_on,
                size: 22,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locationTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 🆕 Show incremental distance for this move
                  Text(
                    distance > 0
                        ? 'Moved: ${distance.toStringAsFixed(2)} km'
                        : 'Starting point',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tsMillis != null
                        ? formatTimestamp(tsMillis)
                        : "Unknown date",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  // 🆕 Optional: Show who saved this (for debugging)
                  if (savedBy != 'Unknown')
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Saved by: $savedBy',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.black38,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.black45,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationList() {
    if (adminDisabledNotifications) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_off,
                size: 80,
                color: Colors.black26,
              ),
              const SizedBox(height: 16),
              Text(
                "Notifications are turned off",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enable notifications in your profile to see location updates",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (lastLocations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_off,
                size: 80,
                color: Colors.black26,
              ),
              const SizedBox(height: 16),
              Text(
                "No location updates yet",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Device Wearer location updates will appear here",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 🆕 Show count of locations
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${lastLocations.length} most recent locations',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: lastLocations.length,
            itemBuilder: (context, index) {
              final loc = lastLocations[index];
              return _buildLocationCard(loc, index);
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _deviceWearerSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4B315),
        elevation: 1,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.only(left: 20.0),
            child: Image.asset('assets/back.png', fit: BoxFit.contain),
          ),
        ),
        title: Text(
          'Last Locations',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildLocationList(),
    );
  }
}
