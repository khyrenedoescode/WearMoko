import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wearmokoapp/login.dart';
import 'package:wearmokoapp/monitorer/moniadbout.dart';
import 'package:wearmokoapp/monitorer/monicriclemanagement.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ ADD THIS
import 'package:wearmokoapp/monitorer/monieditpass.dart';
import 'package:wearmokoapp/monitorer/monipersonalinformation.dart';
import 'package:wearmokoapp/monitorer/moniprivandpoli.dart';
import 'package:google_fonts/google_fonts.dart';

class MoniSettings extends StatelessWidget {
  const MoniSettings({super.key});

  void _showMoniLogoutOverlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Log Out',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    color: const Color(0xFF650000),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to log out?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w400,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'No',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _performLogout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB400),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Yes',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ UPDATED: Now clears FCM token before logging out
  Future<void> _performLogout(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      // ✅ NEW: Clear FCM token from Firestore before logging out
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'fcmToken': FieldValue.delete(),
          });
          print('✅ FCM token cleared for user: ${user.uid}');
        } catch (e) {
          print('⚠️ Error clearing FCM token: $e');
          // Continue with logout even if token clearing fails
        }
      }

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Clear SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('rememberMe');

      print('✅ User logged out successfully');

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) => child,
            transitionDuration: Duration.zero,
          ),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('❌ Error during logout: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error logging out. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD498),
        elevation: 1,
        shadowColor: const Color(0xFFA5A5A5),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.only(left: 20.0),
            child: Image.asset('assets/back.png', fit: BoxFit.contain),
          ),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Account Settings'),
            _buildSettingsTile(
              context: context,
              iconAsset: 'assets/user4.png',
              title: 'Personal Information',
              targetPage: const MoniPersonalInfo(),
            ),
            _buildSettingsTile(
              context: context,
              iconAsset: 'assets/pass.png',
              title: 'Password',
              targetPage: const MoniEditPass(),
            ),
            _buildSectionHeader('Others'),
            _buildSettingsTile(
              context: context,
              iconAsset: 'assets/groupcircle.png',
              title: 'Circle Management',
              targetPage: const MoniCircleM(),
            ),
            _buildSettingsTile(
              context: context,
              iconAsset: 'assets/privacy.png',
              title: 'Privacy and Security',
              targetPage: const Monipriandpoli(),
            ),
            _buildSettingsTile(
              context: context,
              iconAsset: 'assets/about.png',
              title: 'About',
              targetPage: const MoniAbout(),
            ),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 27.0, vertical: 8.0),
              leading: Image.asset('assets/logout.png',
                  width: 20, height: 20, fit: BoxFit.contain),
              title: Text(
                'Log Out',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              trailing: Image.asset('assets/nextbutton.png',
                  width: 10.26, height: 12.91, fit: BoxFit.cover),
              onTap: () => _showMoniLogoutOverlay(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(27, 20, 27, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEBE9E9), width: 1),
          top: BorderSide(color: Color(0xFFEBE9E9), width: 1),
        ),
        boxShadow: [
          BoxShadow(
              offset: Offset(0, 1),
              blurRadius: 4,
              color: Color.fromRGBO(12, 12, 13, 0.05)),
        ],
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 18,
          color: const Color(0xFF5B5B5B),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required String iconAsset,
    required String title,
    required Widget targetPage,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 27.0, vertical: 8.0),
      leading:
          Image.asset(iconAsset, width: 20, height: 20, fit: BoxFit.contain),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          fontSize: 18,
          color: const Color(0xFF1A1A1A),
        ),
      ),
      trailing: Image.asset('assets/nextbutton.png',
          width: 10.26, height: 12.91, fit: BoxFit.cover),
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => targetPage,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) => child,
            transitionDuration: Duration.zero,
          ),
        );
      },
    );
  }
}
