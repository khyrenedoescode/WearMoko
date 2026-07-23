// main.dart - WITH ENHANCED DEBUG LOGGING AND PROPER ERROR HANDLING
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'package:wearmokoapp/block_listener.dart';
import 'package:wearmokoapp/lastLocationListener.dart';
import 'package:wearmokoapp/splash_screen.dart';
import 'package:wearmokoapp/notification_handler.dart';
import 'package:wearmokoapp/devicewearer/deviceSOS.dart';
import 'package:wearmokoapp/location_tracking_service.dart';
import 'package:wearmokoapp/device_wearer_location_service.dart';

// Global Key declarations
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<OverlayState> overlayKey = GlobalKey<OverlayState>();

Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized.');
  } else {
    print('⚠️ Firebase already initialized. Skipping core initialization.');
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _listenersInitialized = false;
  bool _notificationHandlerInitialized = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initLocalNotifications();
    _initializeFirebase();
  }

  // ✅ UPDATED: Proper error handling that continues even if Firebase is already initialized
  Future<void> _initializeFirebase() async {
    try {
      print('🔍 [DEBUG] Starting Firebase initialization...');
      await _initializeApp();
      print('🔍 [DEBUG] Firebase initialized successfully');
    } catch (e) {
      print(
          '⚠️ [DEBUG] Firebase initialization error (likely already initialized): $e');
      // Continue anyway - Firebase is probably already initialized
    }

    // ✅ ALWAYS set initialized state and continue, even if there was an error
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }

    print('🔍 [DEBUG] Setting up Firebase listeners...');
    _setupFirebaseListeners();

    // ✅ ALWAYS call device tracking setup
    print('🔍 [DEBUG] About to call _startDeviceWearerTracking()...');
    try {
      await _startDeviceWearerTracking();
      print('🔍 [DEBUG] _startDeviceWearerTracking() completed successfully');
    } catch (e, stackTrace) {
      print('❌ [DEBUG] Error in _startDeviceWearerTracking: $e');
      print('❌ [DEBUG] Stack trace: $stackTrace');
    }
  }

  // ✅ UPDATED: Enhanced debug logging with error handling
  Future<void> _startDeviceWearerTracking() async {
    try {
      print('🔍 [DEBUG] === ENTERING _startDeviceWearerTracking ===');
      print('🔍 [DEBUG] Setting up Device Wearer tracking listener...');

      // Wait a bit to ensure auth state is ready
      print('🔍 [DEBUG] Waiting 500ms for auth state...');
      await Future.delayed(const Duration(milliseconds: 500));
      print('🔍 [DEBUG] Wait completed');

      // Check current auth state immediately
      final currentUser = FirebaseAuth.instance.currentUser;
      print('🔍 [DEBUG] Current user at setup: ${currentUser?.uid ?? "null"}');

      // Listen to auth state changes
      print('🔍 [DEBUG] Setting up authStateChanges listener...');
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        try {
          print('🔍 [DEBUG] === AUTH STATE CHANGE TRIGGERED ===');
          print('🔍 [DEBUG] Auth state changed. User: ${user?.uid ?? "null"}');

          if (user != null) {
            print('🔍 [DEBUG] User is not null, proceeding...');
            print('🔍 [DEBUG] Fetching user document for: ${user.uid}');

            // User is logged in, check if they're a Device Wearer
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

            print('🔍 [DEBUG] User document exists: ${userDoc.exists}');

            if (!userDoc.exists) {
              print('⚠️ [DEBUG] User document does not exist!');
              return;
            }

            final userData = userDoc.data();
            print('🔍 [DEBUG] User data keys: ${userData?.keys.toList()}');
            print('🔍 [DEBUG] Full user data: $userData');

            final role = userData?['role'] as String?;
            print('🔍 [DEBUG] User role: "$role"');

            if (role == 'Device Wearer') {
              print('✅ [DEBUG] Role matches! Starting tracking...');
              // Start tracking for Device Wearer
              await DeviceWearerLocationService().startTracking();
              print('✅ [DEBUG] Device Wearer location tracking started');
            } else {
              print(
                  'ℹ️ [DEBUG] User role is "$role", not "Device Wearer". Skipping tracking.');
            }
          } else {
            print('🔍 [DEBUG] User is null, stopping tracking');
            // User logged out, stop tracking
            DeviceWearerLocationService().stopTracking();
            print('🛑 [DEBUG] User logged out, stopped Device Wearer tracking');
          }
        } catch (e, stackTrace) {
          print('❌ [DEBUG] Error in authStateChanges listener: $e');
          print('❌ [DEBUG] Stack trace: $stackTrace');
        }
      }, onError: (error) {
        print('❌ [DEBUG] authStateChanges stream error: $error');
      });

      print('🔍 [DEBUG] Auth state listener set up complete');
      print('🔍 [DEBUG] === EXITING _startDeviceWearerTracking ===');
    } catch (e, stackTrace) {
      print(
          '❌ [DEBUG] Error in _startDeviceWearerTracking outer try-catch: $e');
      print('❌ [DEBUG] Stack trace: $stackTrace');
    }
  }

  void _initLocalNotifications() {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) async {
        if (response.payload == null || response.payload!.isEmpty) return;
        try {
          final data = jsonDecode(response.payload!);
          final title = data['title'] ?? 'Notification';
          final body = data['body'] ?? '';
          final BuildContext? context = navigatorKey.currentContext;
          if (context != null && context.mounted) {
            NotificationHandler.showNotificationPopup(context, title, body);
          }
        } catch (e) {
          print('❌ Payload decode error: $e');
        }
      },
    );
  }

  void _setupFirebaseListeners() {
    if (_listenersInitialized) return;

    FirebaseMessaging.onMessage.listen((message) {
      print('📩 Foreground message: ${message.messageId}');
      final notification = message.notification;
      final android = notification?.android;
      if (notification == null || android == null) return;
      final payload = jsonEncode({
        'title': notification.title,
        'body': notification.body,
      });
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'your_channel_id',
            'your_channel_name',
            channelDescription: 'your_channel_description',
            importance: Importance.max,
            priority: Priority.high,
            icon: android.smallIcon,
          ),
        ),
        payload: payload,
      );
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': newToken});
      print("🔄 New token saved: $newToken");
    });

    _listenersInitialized = true;
    print('✅ Firebase Listeners initialized.');
  }

  void _setupNotificationHandler(BuildContext context) {
    if (!_notificationHandlerInitialized) {
      NotificationHandler.initialize(context, navigatorKey: navigatorKey);
      _notificationHandlerInitialized = true;
      print('✅ NotificationHandler initialized with navigatorKey.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFFEAA647),
          body: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _setupNotificationHandler(context);
        });

        return Overlay(
          key: overlayKey,
          initialEntries: [
            OverlayEntry(
              builder: (context) => BlockListener(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
      home: const Stack(
        children: [
          SplashScreen(),
          SOSListener(),
          LastLocationListener(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    LocationTrackingService().stopTracking();
    DeviceWearerLocationService().stopTracking();
    super.dispose();
  }
}
