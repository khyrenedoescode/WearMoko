import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'creatingspace2.dart';

class CreatingASpaceScreen extends StatelessWidget {
  CreatingASpaceScreen({super.key});

  final TextEditingController _circleNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generateRandomCode() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final Random random = Random();
    return List.generate(5, (index) => letters[random.nextInt(letters.length)])
        .join();
  }

  Future<void> _saveCircleName(String circleName) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('circles')
            .add({
          'name': circleName,
          'createdAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error adding circle name to Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const Color backgroundColor = Color(0xFFEAA647);
    const Color boxColor = Colors.white;
    const Color borderColor = Colors.black;
    const Color textColor = Color(0xFF212121);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: const BoxDecoration(
          color: backgroundColor,
          image: DecorationImage(
            image: AssetImage('assets/backgroundsplash.png'),
            fit: BoxFit.cover,
            opacity: 0.9,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.08,
              vertical: screenHeight * 0.05,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.06),
                // Title
                Text(
                  'Name of your Circle',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: screenWidth * 0.055,
                    color: textColor,
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                // Circle Name Input
                Container(
                  width: double.infinity,
                  height: screenHeight * 0.065,
                  decoration: BoxDecoration(
                    color: boxColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _circleNameController,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.045,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.015,
                        horizontal: screenWidth * 0.03,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Next Button
                SizedBox(
                  width: double.infinity,
                  height: screenHeight * 0.07,
                  child: ElevatedButton(
                    onPressed: () async {
                      String circleName = _circleNameController.text.trim();
                      if (circleName.isNotEmpty) {
                        await _saveCircleName(circleName);
                        String randomCode = _generateRandomCode();
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation,
                                    secondaryAnimation) =>
                                CreatingASpaceScreen2(randomCode: randomCode),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                            transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) =>
                                child,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a circle name.'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: boxColor,
                      side: const BorderSide(color: borderColor, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      shadowColor: Colors.black.withOpacity(0.25),
                      elevation: 4,
                    ),
                    child: Text(
                      'Next',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: screenWidth * 0.055,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
