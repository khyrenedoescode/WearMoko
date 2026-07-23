import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'package:wearmokoapp/devicewearer_screen2.dart';

class Device extends StatelessWidget {
  const Device({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const backgroundColor = Color(0xFFEAA647);

    return Scaffold(
      body: Stack(
        children: [
          // Background image with color burn
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: backgroundColor,
                image: DecorationImage(
                  image: AssetImage('assets/backgroundsplash.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    backgroundColor,
                    BlendMode.colorBurn,
                  ),
                ),
              ),
            ),
          ),
          // Blur overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
          ),
          // Centered white container
          Center(
            child: Container(
              width: screenWidth * 0.9,
              padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.04,
                  horizontal: screenWidth * 0.05),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'Greetings from WearMoko',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      fontSize: screenWidth * 0.08,
                      color: const Color(0xFFA66D1D),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // Scrollable descriptive text
                  SizedBox(
                    height: screenHeight * 0.45,
                    child: SingleChildScrollView(
                      child: Text(
                        '''We are delighted to welcome you as a user of our innovative wearable necklace device! WearMoko provides a powerful companion for real-time monitoring and emergency assistance, all designed to improve your safety and well-being. 

Wearing your necklace provides continuous monitoring and connectivity, ensuring that help is always just a tap away. The device integrates effortlessly with our mobile application, allowing you to access critical features such as location tracking and distress notifications.

Your privacy is highly significant to us. Rest assured that your data is only shared with people you trust, and only when you explicitly give permission. This allows you to use your device with confidence while knowing that your personal information is secure.

We encourage you to explore the app and become acquainted with its features, which are intended to empower you in your daily life. Every aspect of WearMoko, from monitoring your status to contacting support, is designed to give you peace of mind.''',
                        textAlign: TextAlign.justify,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w400,
                          fontSize: screenWidth * 0.035,
                          height: 1.4,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  // Next button
                  SizedBox(
                    width: screenWidth * 0.45,
                    height: screenHeight * 0.06,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const Device2(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEAA647),
                        side: BorderSide(
                          color: const Color(0xFFFFD498),
                          width: screenWidth * 0.003,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.03),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Next',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: screenWidth * 0.045,
                            color: const Color(0xFF212121),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
