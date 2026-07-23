import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class SOSListener extends StatefulWidget {
  const SOSListener({super.key});

  @override
  State<SOSListener> createState() => _SOSListenerState();
}

class _SOSListenerState extends State<SOSListener> {
  final DatabaseReference _sosRef =
      FirebaseDatabase.instance.ref("GPSLocation");

  bool _isSOSPending = false;
  bool _isInitialDataLoaded = false;
  Timer? _autoResetTimer;

  // ✅ Overlay entry for popup
  OverlayEntry? _overlayEntry;

  static const int LOCK_TIMEOUT_MS = 5 * 60 * 1000;

  @override
  void initState() {
    super.initState();
    print('🚨🚨🚨 ========================================');
    print('🚨 [SOSListener] WIDGET CREATED AND INITIALIZED!');
    print('🚨 [SOSListener] initState() called');
    print('🚨🚨🚨 ========================================');

    _checkRoleAndStartListener();
  }

  Future<void> _checkRoleAndStartListener() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        print('⚠️ [SOSListener] No user logged in yet. Waiting for auth...');

        FirebaseAuth.instance.authStateChanges().listen((User? user) async {
          if (user != null) {
            await _verifyRoleAndStart(user.uid);
          }
        });
        return;
      }

      await _verifyRoleAndStart(currentUser.uid);
    } catch (e, stackTrace) {
      print('❌ [SOSListener] Error checking role: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _verifyRoleAndStart(String uid) async {
    try {
      print('🔍 [SOSListener] Checking role for user: $uid');

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        print('⚠️ [SOSListener] User document not found');
        return;
      }

      final userData = userDoc.data();
      final role = userData?['role'] as String?;

      print('🔍 [SOSListener] User role: "$role"');

      if (role == 'Monitoring User') {
        print(
            '✅ [SOSListener] Monitoring User detected! Starting SOS listener...');
        _listenForSOS();
      } else {
        print(
            '⏸️ [SOSListener] Not a Monitoring User (role: $role). SOSListener disabled.');
      }
    } catch (e, stackTrace) {
      print('❌ [SOSListener] Error verifying role: $e');
      print('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    print('🛑 [SOSListener] Widget disposed, stopping timer');
    _autoResetTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _listenForSOS() {
    print('🔍🔍🔍 ========================================');
    print('🔍 [SOSListener] _listenForSOS() called');
    print('🔍 [SOSListener] Setting up Firebase Realtime DB listener...');
    print('🔍 [SOSListener] Listening to path: GPSLocation');
    print('🔍🔍🔍 ========================================');

    _sosRef.onValue.listen((event) {
      print('📡 [SOSListener] ========================================');
      print('📡 [SOSListener] Firebase Realtime DB EVENT TRIGGERED!');
      print('📡 [SOSListener] Snapshot exists: ${event.snapshot.exists}');

      if (!mounted) {
        print('⚠️ [SOSListener] Widget not mounted, ignoring event');
        return;
      }

      if (!event.snapshot.exists) {
        print('⚠️ [SOSListener] Snapshot does not exist');
        return;
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      print('📡 [SOSListener] Raw data from DB: $data');

      final sosValue = (data['SOS'] ?? "").toString().toLowerCase().trim();
      final processedBy = (data['processedBy'] ?? "").toString();
      final processedAt = data['processedAt'] as int?;

      print('📡 [SOSListener] Parsed values:');
      print('   - SOS: "$sosValue"');
      print('   - Processed by: "$processedBy"');
      print('   - Processed at: $processedAt');
      print('   - Initial data loaded: $_isInitialDataLoaded');
      print('   - Is SOS pending: $_isSOSPending');
      print('📡 [SOSListener] ========================================');

      if (!_isInitialDataLoaded) {
        print('🆕 [SOSListener] This is the INITIAL data load');
        setState(() {
          _isSOSPending = (sosValue == "need help");
          _isInitialDataLoaded = true;
        });

        if (sosValue == "need help" && _shouldReclaimStaleLock(processedAt)) {
          print(
              "⚠️ [SOSListener] Initial SOS found with STALE lock. Attempting to reclaim...");
          _claimSOSAlert(data);
        } else {
          print("✅ [SOSListener] Initial state synced.");
          print("   - SOS: $sosValue");
          print("   - Processed by: $processedBy");
        }
        return;
      }

      // Handle SOS state changes
      if (sosValue == "need help" && !_isSOSPending) {
        print('🚨🚨🚨 [SOSListener] NEW SOS DETECTED! 🚨🚨🚨');
        if (processedBy.isEmpty || _shouldReclaimStaleLock(processedAt)) {
          if (processedBy.isNotEmpty) {
            print(
                "⏰ [SOSListener] Lock timeout detected! Previous processor: $processedBy");
          } else {
            print(
                "🚨 [SOSListener] No processor assigned. Attempting to claim...");
          }
          _claimSOSAlert(data);
        } else {
          print(
              "ℹ️ [SOSListener] SOS already being processed by $processedBy. Skipping.");
          setState(() {
            _isSOSPending = true;
          });
        }
      } else if (sosValue != "need help" && _isSOSPending) {
        print('✅ [SOSListener] SOS Cleared. Ready for new alert.');
        setState(() {
          _isSOSPending = false;
        });

        _removeOverlay();

        if (processedBy.isNotEmpty) {
          print("🔑 [SOSListener] Clearing 'processedBy' lock...");
          _sosRef.update({
            'processedBy': null,
            'processedAt': null,
          });
        }
      } else {
        print('ℹ️ [SOSListener] No state change needed.');
        print('   - Current SOS value: "$sosValue"');
        print('   - Is pending: $_isSOSPending');
      }
    }, onError: (error) {
      print('❌❌❌ [SOSListener] ERROR listening to Firebase Realtime DB!');
      print('❌ Error: $error');
      print('❌❌❌ ========================================');
    });

    print('✅ [SOSListener] Firebase listener setup complete!');
  }

  bool _shouldReclaimStaleLock(int? processedAt) {
    if (processedAt == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final age = now - processedAt;
    return age > LOCK_TIMEOUT_MS;
  }

  Future<void> _claimSOSAlert(Map<String, dynamic> originalData) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    print('🏆 [SOSListener] ========================================');
    print('🏆 [SOSListener] Attempting to CLAIM SOS alert...');
    print('🏆 [SOSListener] My UID: $myUid');
    print('🏆 [SOSListener] ========================================');

    if (myUid == null) {
      print("❌ [SOSListener] Cannot claim SOS: User not logged in.");
      return;
    }

    try {
      final transactionResult =
          await _sosRef.runTransaction((Object? currentData) {
        if (currentData == null) {
          print('⚠️ [SOSListener] Transaction aborted: currentData is null');
          return Transaction.abort();
        }

        Map<String, dynamic> freshData =
            Map<String, dynamic>.from(currentData as Map);

        if ((freshData['SOS'] ?? "").toString().toLowerCase().trim() !=
            "need help") {
          print('⚠️ [SOSListener] Transaction aborted: SOS is not "need help"');
          return Transaction.abort();
        }

        final existingProcessor = freshData['processedBy'];
        final processedAt = freshData['processedAt'] as int?;
        final now = DateTime.now().millisecondsSinceEpoch;

        bool canClaim = false;

        if (existingProcessor == null ||
            (existingProcessor is String && existingProcessor.isEmpty)) {
          canClaim = true;
          print('✅ [SOSListener] Can claim: No existing processor');
        } else if (_shouldReclaimStaleLock(processedAt)) {
          canClaim = true;
          print(
              "🔓 [SOSListener] Can claim: Overriding stale lock from $existingProcessor");
        } else {
          print(
              '⚠️ [SOSListener] Cannot claim: Lock held by $existingProcessor');
        }

        if (canClaim) {
          freshData['processedBy'] = myUid;
          freshData['processedAt'] = now;
          print('✅ [SOSListener] Claiming lock in transaction');
          return Transaction.success(freshData);
        }

        return Transaction.abort();
      });

      if (transactionResult.committed) {
        print("🏆🏆🏆 [SOSListener] THIS CLIENT WON THE LOCK! 🏆🏆🏆");
        print("🏆 [SOSListener] My UID: $myUid");
        print("🏆 [SOSListener] Now processing and sending notifications...");

        setState(() {
          _isSOSPending = true;
        });

        // ✅ Show overlay popup immediately when this client wins the lock
        _showOverlayPopup(originalData);

        await _processAndSendNotifications(originalData);
        _startAutoResetTimer();
      } else {
        print(
            "🔒 [SOSListener] Lock claim FAILED (already held or SOS cleared).");
        setState(() {
          _isSOSPending = true;
        });
      }
    } catch (e, stackTrace) {
      print("❌❌❌ [SOSListener] ERROR during SOS transaction!");
      print("❌ Error: $e");
      print("❌ Stack trace: $stackTrace");
    }
  }

  // ✅ Show overlay popup (called both from SOSListener and NotificationHandler)
  void _showOverlayPopup(Map<String, dynamic> data) {
    if (!mounted) {
      print('⚠️ [SOSListener] Widget not mounted, cannot show overlay');
      return;
    }

    final lat = data['latitude'];
    final lon = data['longitude'];

    final googleMapsUrl = (lat != null && lon != null)
        ? "https://www.google.com/maps/search/?api=1&query=$lat,$lon"
        : null;

    final mapsLink = googleMapsUrl != null ? Uri.parse(googleMapsUrl) : null;

    _removeOverlay(); // Remove existing overlay if any

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildOverlayPopup(
        context,
        title: "🚨 SOS Alert from Your Circle!",
        body: "Emergency detected! The device wearer needs immediate help.",
        mapsLink: mapsLink,
      ),
    );

    // Use post-frame callback to ensure overlay is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final overlay = Overlay.of(context);
        overlay.insert(_overlayEntry!);
        print('✅ [SOSListener] Overlay popup displayed');
      }
    });
  }

  // ✅ PUBLIC METHOD: Can be called from NotificationHandler
  // Add this method to allow external access
  static void showOverlayFromNotification(
      BuildContext context, Map<String, dynamic> data) {
    final lat = data['latitude'];
    final lon = data['longitude'];

    final googleMapsUrl = (lat != null && lon != null)
        ? "https://www.google.com/maps/search/?api=1&query=$lat,$lon"
        : null;

    final mapsLink = googleMapsUrl != null ? Uri.parse(googleMapsUrl) : null;

    late OverlayEntry overlayEntry; // ✅ CHANGED: 'final' to 'late'

    overlayEntry = OverlayEntry(
      builder: (ctx) => _buildStaticOverlayPopup(
        ctx,
        title: "🚨 SOS Alert from Your Circle!",
        body: "Emergency detected! The device wearer needs immediate help.",
        mapsLink: mapsLink,
        onClose: () {
          overlayEntry.remove(); // ✅ ADDED: Actually remove the overlay
          print('🗑️ [SOSListener] Static overlay removed');
        },
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    print('✅ [SOSListener] Overlay popup displayed from notification');
  }

  // ✅ Remove overlay
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    print('🗑️ [SOSListener] Overlay removed');
  }

  // ✅ Build overlay popup widget (instance method)
  Widget _buildOverlayPopup(
    BuildContext context, {
    required String title,
    required String body,
    Uri? mapsLink,
  }) {
    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🎨 Top Yellow Banner with Icon
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFFC107),
                      Color(0xFFF4B315),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emergency_outlined,
                        size: 48,
                        color: Color(0xFFF4B315),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // 📝 Message Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBF5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFF4B315).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFF4B315),
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            body,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    if (mapsLink != null)
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  if (await canLaunchUrl(mapsLink)) {
                                    await launchUrl(
                                      mapsLink,
                                      mode: LaunchMode.externalApplication,
                                    );
                                    print('✅ Opened Google Maps: $mapsLink');
                                  }
                                } catch (e) {
                                  print('❌ Error launching maps: $e');
                                }
                                _removeOverlay();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF4B315),
                                foregroundColor: Colors.white,
                                elevation: 6,
                                shadowColor:
                                    const Color(0xFFF4B315).withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.location_on_rounded,
                                      size: 24),
                                  const SizedBox(width: 10),
                                  Text(
                                    'View Location on Maps',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton(
                              onPressed: () => _removeOverlay(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFF4B315),
                                side: const BorderSide(
                                  color: Color(0xFFF4B315),
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Close',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => _removeOverlay(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF4B315),
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shadowColor:
                                const Color(0xFFF4B315).withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Got It',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Static overlay builder for external calls
  static Widget _buildStaticOverlayPopup(
    BuildContext context, {
    required String title,
    required String body,
    Uri? mapsLink,
    required VoidCallback onClose,
  }) {
    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🎨 Top Yellow Banner with Icon
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFFC107),
                      Color(0xFFF4B315),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emergency_outlined,
                        size: 48,
                        color: Color(0xFFF4B315),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // 📝 Message Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBF5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFF4B315).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFF4B315),
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            body,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    if (mapsLink != null)
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  if (await canLaunchUrl(mapsLink)) {
                                    await launchUrl(
                                      mapsLink,
                                      mode: LaunchMode.externalApplication,
                                    );
                                    print('✅ Opened Google Maps: $mapsLink');
                                  }
                                } catch (e) {
                                  print('❌ Error launching maps: $e');
                                }
                                onClose();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF4B315),
                                foregroundColor: Colors.white,
                                elevation: 6,
                                shadowColor:
                                    const Color(0xFFF4B315).withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.location_on_rounded,
                                      size: 24),
                                  const SizedBox(width: 10),
                                  Text(
                                    'View Location on Maps',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton(
                              onPressed: onClose,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFF4B315),
                                side: const BorderSide(
                                  color: Color(0xFFF4B315),
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Close',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: onClose,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF4B315),
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shadowColor:
                                const Color(0xFFF4B315).withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Got It',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processAndSendNotifications(Map<String, dynamic> data) async {
    print('📤 [SOSListener] ========================================');
    print('📤 [SOSListener] Processing and sending notifications...');

    final lat = data['latitude'];
    final lon = data['longitude'];
    print('📍 [SOSListener] Location: lat=$lat, lon=$lon');

    final googleMapsUrl = (lat != null && lon != null)
        ? "https://www.google.com/maps/search/?api=1&query=$lat,$lon"
        : "Location not available.";

    print('🗺️ [SOSListener] Maps URL: $googleMapsUrl');

    try {
      print('🔍 [SOSListener] Querying Device Wearer...');
      final deviceWearerQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Device Wearer')
          .limit(1)
          .get();

      if (deviceWearerQuery.docs.isEmpty) {
        print("❌ [SOSListener] No Device Wearer found!");
        return;
      }

      final deviceWearerData = deviceWearerQuery.docs.first.data();
      final circleCode = deviceWearerData['circleCode'] as String?;
      print("🔍 [SOSListener] Device Wearer circle code: $circleCode");

      if (circleCode == null || circleCode.isEmpty) {
        print("❌ [SOSListener] Device Wearer has no circleCode!");
        return;
      }

      print(
          '🔍 [SOSListener] Querying Monitoring Users in circle: $circleCode');

      final monitoringUsersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Monitoring User')
          .where('joinedCircleCode', isEqualTo: circleCode)
          .get();

      print(
          "👥 [SOSListener] Found ${monitoringUsersSnapshot.docs.length} Monitoring Users in circle");

      if (monitoringUsersSnapshot.docs.isEmpty) {
        print("⚠️ [SOSListener] No monitoring users found in circle!");
        return;
      }

      int successCount = 0;

      for (var doc in monitoringUsersSnapshot.docs) {
        final userData = doc.data();
        final isLoggedIn = userData['isLoggedIn'] as bool? ?? false;

        print(
            "📲 [SOSListener] Sending to ${doc.id} (logged in: $isLoggedIn)...");

        final success = await _notifyUser(
          userId: doc.id,
          title: "🚨 SOS Alert from Your Circle!",
          body: "Emergency detected! Tap to view location.",
          link: googleMapsUrl,
        );

        if (success) {
          successCount++;
          print("✅ [SOSListener] Successfully sent to ${doc.id}");
        } else {
          print("❌ [SOSListener] Failed to send to ${doc.id}");
        }
      }

      print(
          '✅ [SOSListener] Sent $successCount/${monitoringUsersSnapshot.docs.length} notifications');
    } catch (e, stackTrace) {
      print("❌ [SOSListener] Error fetching users: $e");
      print("❌ Stack trace: $stackTrace");
    }
  }

  void _startAutoResetTimer() {
    _autoResetTimer?.cancel();
    print("⏱️ [SOSListener] Starting 20-second auto-reset timer...");

    _autoResetTimer = Timer(const Duration(seconds: 20), () async {
      print(
          "⏰ [SOSListener] 20 seconds elapsed! Auto-resetting SOS to 'none'...");

      try {
        await _sosRef.update({
          'SOS': 'none',
          'processedBy': null,
          'processedAt': null,
        });
        print("✅ [SOSListener] SOS auto-reset to 'none' successfully!");
      } catch (e) {
        print("❌ [SOSListener] Error auto-resetting SOS: $e");
      }
    });
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
      print("📲 [SOSListener] Attempt 1 for $userId...");
      final response = await http
          .post(url,
              headers: {"Content-Type": "application/json"}, body: requestBody)
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        print("✅ [SOSListener] SUCCESS! Notification sent to $userId");
        return true;
      } else {
        print(
            "❌ [SOSListener] FAILED! Status ${response.statusCode}: ${response.body}");
        return false;
      }
    } on TimeoutException {
      print("⏳ [SOSListener] TIMEOUT on Attempt 1. Retrying...");
      await Future.delayed(const Duration(seconds: 5));

      try {
        print("📲 [SOSListener] Attempt 2 for $userId...");
        final response = await http
            .post(url,
                headers: {"Content-Type": "application/json"},
                body: requestBody)
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          print("✅ [SOSListener] RETRY SUCCESS! Notification sent to $userId");
          return true;
        } else {
          print("❌ [SOSListener] RETRY FAILED! Status ${response.statusCode}");
          return false;
        }
      } catch (e) {
        print("❌ [SOSListener] CRITICAL ERROR on retry: $e");
        return false;
      }
    } catch (e) {
      print("❌ [SOSListener] CRITICAL ERROR: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
