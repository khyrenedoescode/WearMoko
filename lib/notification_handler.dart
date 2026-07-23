import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

// 🔧 FIXED: Remove the import since we'll define the SOS popup here instead
// This avoids circular dependency issues

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class NotificationHandler {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Initialize with navigator key
  static void initialize(BuildContext context,
      {GlobalKey<NavigatorState>? navigatorKey}) {
    _navigatorKey = navigatorKey;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notifications tapped from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Notification tapped from background!');
      if (message.notification != null) {
        final title = message.notification!.title ?? 'Notification';
        final body = message.notification!.body ?? 'No Body';

        final BuildContext? navContext = _navigatorKey?.currentContext;
        if (navContext != null && navContext.mounted) {
          _showAppropriatePopup(navContext, title, body);
        }
      }
    });

    _handleTerminatedApp();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('🔔 Local notification tapped!');

        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            final title = data['title'] ?? 'Notification';
            final body = data['body'] ?? 'No Body';

            final BuildContext? navContext = _navigatorKey?.currentContext;
            if (navContext != null && navContext.mounted) {
              _showAppropriatePopup(navContext, title, body);
            } else {
              print('❌ No valid context found for popup');
            }
          } catch (e) {
            print('❌ Error decoding payload: $e');
          }
        }
      },
    );
  }

  /// Show local in-app notification (for foreground)
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// 🆕 SMART POPUP ROUTER - Detects SOS vs regular alerts
  static void _showAppropriatePopup(
      BuildContext context, String title, String body) {
    print('🔍 [NotificationHandler] Routing popup...');
    print('Title: $title');
    print('Body: $body');

    // Check if this is an SOS alert
    final isSOS = title.toLowerCase().contains('sos') ||
        body.toLowerCase().contains('emergency') ||
        body.toLowerCase().contains('danger');

    if (isSOS) {
      print('🚨 [NotificationHandler] Detected SOS alert! Using SOS popup.');
      final Uri? mapLink = _extractGoogleMapsLink(body);
      final String cleanBody = _getCleanBody(body);

      // Use the beautiful SOS popup
      showSOSPopup(
        context,
        title: title,
        body: cleanBody,
        mapsLink: mapLink,
      );
    } else {
      print(
          '📢 [NotificationHandler] Regular notification. Using standard popup.');
      // Use regular notification popup
      showNotificationPopup(context, title, body);
    }
  }

  /// 🆕 Beautiful SOS Popup (moved here to avoid circular dependency)
  static void showSOSPopup(
    BuildContext context, {
    required String title,
    required String body,
    Uri? mapsLink,
  }) {
    print('🔍 [NotificationHandler] Showing SOS popup...');

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
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
                      // 🚨 Alert Icon
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

                      // 📌 Title
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
                      // Body Text
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

                      // 🔘 Action Buttons
                      if (mapsLink != null)
                        Column(
                          children: [
                            // View Location Button (Primary)
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
                                  if (ctx.mounted) Navigator.of(ctx).pop();
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

                            // Close Button (Secondary)
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(ctx).pop(),
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
                        // Only Close button if no maps link
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
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
        );
      },
    );
  }

  /// Standard notification popup (for non-SOS alerts)
  static void showNotificationPopup(
      BuildContext context, String title, String body) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!context.mounted) {
        print('❌ Context not mounted, cannot show popup');
        return;
      }

      final Uri? mapLink = _extractGoogleMapsLink(body);
      final String cleanBody = _getCleanBody(body);

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext ctx) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🚨 Alert Icon with Yellow Background
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4B315).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notification_important_rounded,
                      size: 50,
                      color: Color(0xFFF4B315),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 📌 Title
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // 📝 Message Body
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF4B315).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      cleanBody,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🔘 Buttons Row
                  Row(
                    children: [
                      // Close Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: Color(0xFFF4B315),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Close',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFF4B315),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      // Google Maps Button (if URL exists)
                      if (mapLink != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _launchGoogleMaps(mapLink, ctx);
                              Navigator.of(ctx).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF4B315),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 4,
                              shadowColor:
                                  const Color(0xFFF4B315).withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.map_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            label: Text(
                              'View Location',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  /// Launch Google Maps external app
  static Future<void> _launchGoogleMaps(Uri uri, BuildContext context) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('✅ Opened Google Maps: $uri');
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not open Google Maps',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error launching maps: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Extract Google Maps link from text
  static Uri? _extractGoogleMapsLink(String text) {
    final regex = RegExp(r'https?://www\.google\.com/maps[^\s]+');
    final match = regex.firstMatch(text);
    if (match != null) {
      try {
        return Uri.parse(match.group(0)!);
      } catch (e) {
        print('❌ Error parsing maps URL: $e');
        return null;
      }
    }
    return null;
  }

  /// Remove Google Maps link from body
  static String _getCleanBody(String text) {
    final regex = RegExp(r'https?://www\.google\.com/maps[^\s]+');
    return text.replaceAll(regex, '').trim();
  }

  /// Handle notification tap from terminated app
  static Future<void> _handleTerminatedApp() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null && initialMessage.notification != null) {
      final title = initialMessage.notification!.title ?? 'Notification';
      final body = initialMessage.notification!.body ?? 'No Body';

      Future.delayed(const Duration(milliseconds: 2000), () {
        final BuildContext? navContext = _navigatorKey?.currentContext;
        if (navContext != null && navContext.mounted) {
          _showAppropriatePopup(navContext, title, body);
        }
      });
    }
  }
}
