// block_listener.dart - PROPERLY FIXED VERSION (Using Widget Context)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:wearmokoapp/login.dart';
import 'package:wearmokoapp/main.dart'; // Contains navigatorKey and overlayKey

class BlockListener extends StatefulWidget {
  final Widget child;
  const BlockListener({super.key, required this.child});

  @override
  State<BlockListener> createState() => _BlockListenerState();
}

class _BlockListenerState extends State<BlockListener> {
  bool _dialogShown = false;
  StreamSubscription? _blockSubscription;
  StreamSubscription? _authSubscription;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();

    // Check if user is already logged in and setup stream
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print(
          "BlockListener: Found existing user in initState. Setting up stream for ${currentUser.uid}");
      // Use post frame callback to ensure context is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupBlockStream(currentUser.uid);
      });
    }

    // Listen for future auth state changes
    _listenToAuthState();
  }

  @override
  void dispose() {
    _blockSubscription?.cancel();
    _authSubscription?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  // -----------------------------------------------------
  // 1. Listen to Auth State Changes (Login/Logout)
  // -----------------------------------------------------
  void _listenToAuthState() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        print(
            "BlockListener: User logged in. Starting block stream for ${user.uid}");
        _setupBlockStream(user.uid);
      } else {
        print("BlockListener: User logged out. Stopping stream.");
        _blockSubscription?.cancel();
        _blockSubscription = null;
        _dialogShown = false;
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    });
  }

  // -----------------------------------------------------
  // 2. Setup the Firestore Stream (Overlay Logic)
  // -----------------------------------------------------
  void _setupBlockStream(String uid) {
    // Prevent duplicate subscriptions
    if (_blockSubscription != null) {
      print(
          "BlockListener: Stream already active for $uid. Skipping duplicate setup.");
      return;
    }

    _blockSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      // Better logging for debugging
      if (!snapshot.exists) {
        print("BlockListener: User document doesn't exist for $uid");
        return;
      }

      final data = snapshot.data();
      if (data == null || !data.containsKey('isBlocked')) {
        print("BlockListener: 'isBlocked' field missing in user document");
        return;
      }

      final bool isBlocked = data['isBlocked'] ?? false;

      print(
          "BlockListener Stream: isBlocked = $isBlocked, dialogShown = $_dialogShown, overlayEntry = ${_overlayEntry != null}");

      // 🎯 LOGIC 1: ACCOUNT BLOCKED - Show overlay
      if (isBlocked && !_dialogShown && _overlayEntry == null) {
        print("BlockListener: ACCOUNT BLOCKED! Showing overlay.");
        _showBlockedOverlay();
      }

      // 🎯 LOGIC 2: ACCOUNT UNBLOCKED - Remove overlay if shown
      else if (!isBlocked && _overlayEntry != null) {
        print("BlockListener: Account unblocked. Removing overlay.");
        _overlayEntry?.remove();
        _overlayEntry = null;
        _dialogShown = false;
      }
    });
  }

  // -----------------------------------------------------
  // 3. Show Blocked Overlay (Using Global Overlay Key)
  // -----------------------------------------------------
  void _showBlockedOverlay() {
    // Use addPostFrameCallback to ensure widget tree is ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Small delay to ensure overlay is ready
      await Future.delayed(const Duration(milliseconds: 100));

      // Check if widget is still mounted
      if (!mounted) {
        print('BlockListener: Widget unmounted, cannot show overlay');
        return;
      }

      // 🎯 USE THE GLOBAL OVERLAY KEY instead of context
      final OverlayState? overlayState = overlayKey.currentState;

      if (overlayState == null) {
        print(
            'BlockListener ERROR: OverlayState is null. Cannot show overlay.');
        return;
      }

      // Mark dialog as shown BEFORE creating overlay
      _dialogShown = true;

      // Create the overlay entry
      _overlayEntry = OverlayEntry(
        builder: (context) => Material(
          color: Colors.black54, // Semi-transparent background
          child: Center(
            child: AlertDialog(
              title: Text(
                "Access Revoked",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: Text(
                "Your account has been blocked by the administrator. You will be logged out immediately.",
                style: GoogleFonts.poppins(),
              ),
              actions: [
                TextButton(
                  onPressed: () => _handleBlockedLogout(),
                  child: Text("OK", style: GoogleFonts.poppins()),
                )
              ],
            ),
          ),
        ),
      );

      // Insert the overlay
      try {
        overlayState.insert(_overlayEntry!);
        print("BlockListener: Overlay inserted successfully.");
      } catch (e) {
        print("BlockListener ERROR: Failed to insert overlay: $e");
        _dialogShown = false;
        _overlayEntry = null;
      }
    });
  }

  // -----------------------------------------------------
  // 4. Handle Blocked Logout
  // -----------------------------------------------------
  Future<void> _handleBlockedLogout() async {
    print("BlockListener: User clicked OK. Logging out...");

    // Remove overlay first
    _overlayEntry?.remove();
    _overlayEntry = null;

    // Cancel stream
    _blockSubscription?.cancel();
    _blockSubscription = null;

    // Sign out from Firebase
    try {
      await FirebaseAuth.instance.signOut();
      print("BlockListener: User signed out successfully.");
    } catch (e) {
      print("BlockListener ERROR: Sign out failed: $e");
    }

    // Reset flag
    _dialogShown = false;

    // Navigate to login page using navigatorKey (safe for navigation)
    final BuildContext? navContext = navigatorKey.currentContext;
    if (navContext != null && navContext.mounted) {
      Navigator.pushAndRemoveUntil(
        navContext,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false, // Clear all previous routes
      );
      print("BlockListener: Navigated to LoginPage.");
    } else {
      print("BlockListener ERROR: Cannot navigate - context unavailable.");
    }
  }

  @override
  Widget build(BuildContext context) {
    // This widget only handles background listening, so it returns its child.
    return widget.child;
  }
}
