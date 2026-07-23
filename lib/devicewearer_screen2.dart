import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wearmokoapp/devicewearer/verifycodedevice.dart';
import 'dart:ui' as ui;

class Device2 extends StatelessWidget {
  const Device2({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const backgroundColor = Color(0xFFEAA647);

    return Scaffold(
      body: Stack(
        children: [
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
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
          ),
          Center(
            child: Container(
              width: screenWidth * 0.9,
              height: screenHeight * 0.7,
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.03,
                horizontal: screenWidth * 0.05,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                border: Border.all(
                  color: Colors.black,
                  width: screenWidth * 0.003,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'As a Device User in WearMoko',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      fontSize: screenWidth * 0.07,
                      color: const Color(0xFFA66D1D),
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text.rich(
                        TextSpan(
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w400,
                            fontSize: screenWidth * 0.035,
                            height: 1.4,
                            color: Colors.black,
                          ),
                          children: const [
                            TextSpan(
                                text:
                                    'You play an important role in ensuring your own safety and well-being. Here are the main aspects of your role:\n\n'),
                            TextSpan(
                                text: 'Real-Time Monitoring: ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(
                                text:
                                    'You wear the StealthWear necklace, which provides continuous real-time monitoring of your location and vital statistics, ensuring that help is always available.\n\n'),
                            TextSpan(
                                text: 'Emergency Alerts: ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(
                                text:
                                    'You can send distress notifications with just a tap. This feature allows for quick communication with your Monitorer or emergency services in the event of an urgent situation.\n\n'),
                            TextSpan(
                                text: 'GPS Control: ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(
                                text:
                                    'You have the freedom to turn on the GPS tracker. This feature lets you choose when and how your location is shared, giving you more control over your privacy.\n\n'),
                            TextSpan(
                                text: 'Permission Management: ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(
                                text:
                                    'You decide who can access your data. Your privacy is extremely important, and you can grant or revoke access to your information at any time, ensuring that only trusted individuals can see your status.\n'),
                          ],
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  SizedBox(
                    width: screenWidth * 0.45,
                    height: screenHeight * 0.06,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const UserDevice(),
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
                          'Continue',
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
