import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wearmokoapp/devicewearer/devicedash1.dart';
import 'package:wearmokoapp/forgotpassword.dart';
import 'package:wearmokoapp/monitorer/monihome.dart';
import 'package:wearmokoapp/monitorer/verifycodemoni.dart';
import 'package:wearmokoapp/location_tracking_service.dart'; // ✅ Add this import
import 'signup.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wearmokoapp/device_wearer_location_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isObscure = true;
  bool _rememberMe = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // CLEANUP OLD LASTLOCATIONS FUNCTION
  Future<void> _cleanupOldLastLocations(String userId, String role) async {
    try {
      if (role != 'Monitoring User') {
        print("ℹ️ Not a Monitoring User - skipping cleanup");
        return;
      }

      print("🧹 Checking lastLocations for cleanup...");

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print("⚠️ User document not found");
        return;
      }

      final userData = userDoc.data();
      if (userData == null) return;

      final joinedCircleCode = userData['joinedCircleCode'] as String?;
      if (joinedCircleCode == null || joinedCircleCode.isEmpty) {
        print("⚠️ No circle joined yet");
        return;
      }

      final deviceWearerQuery = await _firestore
          .collection('users')
          .where('circleCode', isEqualTo: joinedCircleCode)
          .where('role', isEqualTo: 'Device Wearer')
          .limit(1)
          .get();

      if (deviceWearerQuery.docs.isEmpty) {
        print("⚠️ No Device Wearer found in circle: $joinedCircleCode");
        return;
      }

      final deviceWearerDoc = deviceWearerQuery.docs.first;
      final deviceWearerData = deviceWearerDoc.data();

      final lastLocations =
          deviceWearerData['lastLocations'] as Map<String, dynamic>?;

      if (lastLocations == null || lastLocations.isEmpty) {
        print("ℹ️ No lastLocations to clean up");
        return;
      }

      print("📍 Found ${lastLocations.length} locations");

      final sortedEntries = lastLocations.entries
          .where((e) => e.value is Map<String, dynamic>)
          .toList();

      sortedEntries.sort((a, b) {
        final t1 = (a.value['timestamp'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final t2 = (b.value['timestamp'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return t2.compareTo(t1);
      });

      if (sortedEntries.length > 10) {
        print("🗑️ Deleting ${sortedEntries.length - 10} old locations...");

        final batch = _firestore.batch();
        final deviceWearerRef =
            _firestore.collection('users').doc(deviceWearerDoc.id);

        for (var i = 10; i < sortedEntries.length; i++) {
          final keyToDelete = sortedEntries[i].key;
          batch.update(deviceWearerRef,
              {'lastLocations.$keyToDelete': FieldValue.delete()});
          print("  🗑️ Deleting: $keyToDelete");
        }

        await batch.commit();
        print("✅ Cleanup complete! Kept 10 newest locations.");
      } else {
        print(
            "✅ No cleanup needed. Only ${sortedEntries.length} locations found.");
      }
    } catch (e) {
      print("❌ Error during lastLocations cleanup: $e");
    }
  }

  Future<void> _startLocationTrackingIfNeeded(String role) async {
    if (role == 'Monitoring User') {
      try {
        await LocationTrackingService().startTracking();
        print('✅ Monitoring User location tracking started after login');
      } catch (e) {
        print('❌ Error starting Monitoring User location tracking: $e');
      }
    } else if (role == 'Device Wearer') {
      try {
        await DeviceWearerLocationService().startTracking();
        print('✅ Device Wearer location tracking started after login');
      } catch (e) {
        print('❌ Error starting Device Wearer location tracking: $e');
      }
    }
  }

  Future<void> _login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isNotEmpty && password.isNotEmpty) {
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        User? user = userCredential.user;

        if (user != null) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('rememberMe', _rememberMe);

          await saveFCMToken();

          DocumentSnapshot userDoc =
              await _firestore.collection('users').doc(user.uid).get();

          if (!userDoc.exists) {
            _showErrorDialog('User data not found. Please contact support.');
            return;
          }

          String role = userDoc.get('role');
          final currentContext = context;

          // Ensure isBlocked and notificationEnabled exist for Monitoring User
          if (role == 'Monitoring User') {
            var data = userDoc.data() as Map<String, dynamic>?;

            Map<String, dynamic> updateData = {};

            if (data != null) {
              if (!data.containsKey('isBlocked')) {
                updateData['isBlocked'] = false;
                print('✅ isBlocked field created for user ${user.uid}');
              }

              if (!data.containsKey('notificationEnabled')) {
                updateData['notificationEnabled'] = true;
                print(
                    '✅ notificationEnabled field created for user ${user.uid}');
              }
            }

            if (updateData.isNotEmpty) {
              await _firestore
                  .collection('users')
                  .doc(user.uid)
                  .update(updateData);
            }

            // Cleanup old locations
            await _cleanupOldLastLocations(user.uid, role);

            // ✅ START LOCATION TRACKING FOR MONITORING USERS
            await _startLocationTrackingIfNeeded(role);
          }

          if (role == 'Device Wearer') {
            Navigator.pushReplacement(
              currentContext,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const DeviceDash(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return child;
                },
                transitionDuration: Duration.zero,
              ),
            );
          } else if (role == 'Monitoring User') {
            bool isBlocked = false;
            var data = userDoc.data() as Map<String, dynamic>?;
            if (data != null && data.containsKey('isBlocked')) {
              isBlocked = data['isBlocked'] ?? false;
            }

            if (isBlocked) {
              ScaffoldMessenger.of(currentContext).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Your account has been blocked by the admin. Please enter a new code to proceed.'),
                  duration: Duration(seconds: 5),
                ),
              );
              Navigator.pushReplacement(
                currentContext,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const Moni1(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return child;
                  },
                  transitionDuration: Duration.zero,
                ),
              );
              return;
            }

            String? joinedCircleCode;
            if (data != null && data.containsKey('joinedCircleCode')) {
              joinedCircleCode = userDoc.get('joinedCircleCode');
            }

            if (joinedCircleCode == null || joinedCircleCode.isEmpty) {
              Navigator.pushReplacement(
                currentContext,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const Moni1(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return child;
                  },
                  transitionDuration: Duration.zero,
                ),
              );
            } else {
              Navigator.pushReplacement(
                currentContext,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const MoniHome(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return child;
                  },
                  transitionDuration: Duration.zero,
                ),
              );
            }
          } else {
            _showErrorDialog('Unknown role');
          }
        }
      } on FirebaseAuthException catch (e) {
        String message;

        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password provided for that user.';
        } else {
          message = e.message ?? 'An error occurred. Please try again later.';
        }
        _showErrorDialog(message);
      } catch (e) {
        _showErrorDialog('An error occurred: $e');
      }
    } else {
      _showErrorDialog('Please enter valid email and password');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Error',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: <Widget>[
          TextButton(
            child: Text('OK', style: GoogleFonts.poppins()),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> saveFCMToken() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'fcmToken': fcmToken});
      print('✅ FCM Token saved: $fcmToken');
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool obscure,
    VoidCallback? toggleVisibility,
    required Color boxColor,
    required Color borderColor,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: boxColor,
        border: Border.all(color: borderColor, width: 1.6),
        borderRadius: BorderRadius.circular(5.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 1.0,
            offset: const Offset(0, 0.5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hintText,
            border: InputBorder.none,
            suffixIcon: toggleVisibility != null
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility : Icons.visibility_off,
                      color: Colors.black,
                    ),
                    onPressed: toggleVisibility,
                  )
                : null,
          ),
          style: GoogleFonts.poppins(
            fontSize: 16.0,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double fontSizeWearMoko = (screenWidth * 0.12).clamp(45.0, 65.0);

    Color boxColor = Colors.white;
    Color borderColor = Colors.black;
    final double horizontalPadding = screenWidth * 0.08;

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Container(
              width: screenWidth,
              height: screenHeight,
              decoration: const BoxDecoration(
                color: Color(0xFFEAA647),
                image: DecorationImage(
                  image: AssetImage('assets/backgroundsplash.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 50),
                    Image.asset(
                      'assets/logo.png',
                      width: screenWidth * 0.4,
                      height: screenHeight * 0.15,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome to',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w400,
                        fontSize: screenWidth * 0.07,
                        color: Colors.black,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.25),
                            offset: const Offset(0, 4),
                            blurRadius: 4.0,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'WearMoko',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        fontSize: fontSizeWearMoko,
                        color: Colors.black,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.25),
                            offset: const Offset(0, 4),
                            blurRadius: 4.0,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildTextField(
                      controller: emailController,
                      hintText: 'Email Address',
                      obscure: false,
                      boxColor: boxColor,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      obscure: _isObscure,
                      toggleVisibility: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                      boxColor: boxColor,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: Text(
                        'Remember Me',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      value: _rememberMe,
                      onChanged: (newValue) {
                        setState(() {
                          _rememberMe = newValue!;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: Colors.black,
                      checkColor: Colors.white,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.038,
                              fontStyle: FontStyle.italic,
                              color: Colors.black.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.black),
                          shadowColor: Colors.black.withOpacity(0.30),
                          elevation: 4.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                        ),
                        child: Text(
                          'Log In',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: screenWidth * 0.055,
                            color: const Color(0xFF212121),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const PersonalInformationPage()),
                        );
                      },
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.038,
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                          ),
                          children: [
                            TextSpan(
                              text: "Sign up",
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.038,
                                color: const Color(0xFF212121),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
