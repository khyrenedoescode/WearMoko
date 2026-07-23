import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wearmokoapp/join_create_space_splash.dart';
import 'package:google_fonts/google_fonts.dart';

class AdditionalLayout extends StatefulWidget {
  const AdditionalLayout({super.key});

  @override
  _AdditionalLayoutState createState() => _AdditionalLayoutState();
}

class _AdditionalLayoutState extends State<AdditionalLayout> {
  String selectedOption = '';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _updateUserRole() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // 1. I-standardize ang mga field na gusto mong laging i-update
        Map<String, dynamic> dataToUpdate = {
          'role': selectedOption,
          'isBlocked':
              false, // 🎯 Laging I-set sa false para sa bagong user/role selection
        };

        // 2. I-handle ang notification status batay sa role
        if (selectedOption == 'Monitoring User') {
          // Monitoring User: Gusto mong naka-ON ang notification default
          dataToUpdate['notificationEnabled'] = true;
        } else if (selectedOption == 'Device Wearer') {
          // Device Wearer: Maaari mong i-set sa false o true, depende sa preference.
          // Halimbawa: I-set sa false bilang default.
          dataToUpdate['notificationEnabled'] = false;
        }
        // Kung hindi mo tinukoy ang 'notificationEnabled' sa 'Device Wearer',
        // at nag-e-exist na ang field, mananatili ito dahil sa merge: true.
        // Pero mas maganda kung i-set mo na.

        await _firestore.collection('users').doc(user.uid).set(
              dataToUpdate,
              SetOptions(
                merge: true, // Ito ay nagpapanatili ng iba pang fields
              ),
            );

        print("User role updated to: $selectedOption, isBlocked: false");
      }
    } catch (e) {
      print("Error updating user role: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFEAA647);

    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      body: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          image: DecorationImage(
            image: const AssetImage('assets/backgroundsplash.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              backgroundColor.withOpacity(0.9),
              BlendMode.colorBurn,
            ),
          ),
        ),
        child: Stack(
          children: [
            // Select User Type Text
            Positioned(
              left: width * 0.1,
              top: height * 0.1,
              child: Text(
                'Select User Type',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                  color: const Color(0xFF212121),
                ),
              ),
            ),

            // Monitoring User Button
            Positioned(
              left: width * 0.1,
              top: height * 0.2,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedOption = 'Monitoring User';
                  });
                },
                child: Column(
                  children: [
                    Container(
                      width: 134,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedOption == 'Monitoring User'
                              ? const Color(0xFF543509)
                              : Colors.transparent,
                          width: 5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        image: const DecorationImage(
                          image: AssetImage('assets/usermonitor.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Monitoring User',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: selectedOption == 'Monitoring User'
                            ? Colors.black
                            : Colors.black.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Device User Button
            Positioned(
              left: width * 0.55,
              top: height * 0.2,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedOption = 'Device Wearer';
                  });
                },
                child: Column(
                  children: [
                    Container(
                      width: 134,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedOption == 'Device Wearer'
                              ? const Color(0xFF543509)
                              : Colors.transparent,
                          width: 5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        image: const DecorationImage(
                          image: AssetImage('assets/deviceuser.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Device User',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: selectedOption == 'Device Wearer'
                            ? Colors.black
                            : Colors.black.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Next Button
            Positioned(
              left: width * 0.14,
              top: height * 0.47,
              child: ElevatedButton(
                onPressed: selectedOption.isNotEmpty
                    ? () async {
                        await _updateUserRole();
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const JoinCreateSpaceSplash(),
                            transitionDuration: Duration.zero, // No animation
                            reverseTransitionDuration:
                                Duration.zero, // Optional for back
                            transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) =>
                                child,
                          ),
                        );
                      }
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Please select a role before proceeding'),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF212121),
                  minimumSize: Size(width * 0.70, height * 0.07),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  side: BorderSide(
                      color: Colors.black.withOpacity(0.8), width: 1.5),
                  shadowColor: Colors.black.withOpacity(0.25),
                  elevation: 4.0,
                ),
                child: Text(
                  'Next',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 25,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
