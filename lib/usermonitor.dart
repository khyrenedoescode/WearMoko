import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wearmokoapp/monitorer/verifycodemoni.dart';
import 'dart:ui' as ui;

class Monitorer extends StatelessWidget {
  const Monitorer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const backgroundColor = Color(0xFFEAA647);

    return Scaffold(
      body: Stack(
        children: [
          // Base background
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

          // Main content container
          Positioned(
            left: screenWidth * 0.05,
            top: screenHeight * 0.15,
            child: Container(
              width: screenWidth * 0.9,
              height: screenHeight * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.black,
                  width: screenWidth * 0.003,
                ),
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      'As a Monitoring User',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        fontSize: screenWidth * 0.065,
                        color: const Color(0xFFA66D1D),
                        height: 1.17,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // Scrollable description
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text.rich(
                          TextSpan(
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w400,
                              fontSize: screenWidth * 0.037,
                              height: 1.4,
                              color: Colors.black,
                            ),
                            children: const [
                              TextSpan(
                                text:
                                    'You play a crucial part in protecting device users\' health and safety. The following are the main duties and characteristics of your position:\n\n',
                              ),
                              TextSpan(
                                text: 'Real-Time Monitoring: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text:
                                    'In real-time, you will actively monitor users\' vital statistics and status. This involves keeping an eye on health indicators, location, and any potential warnings.\n\n',
                              ),
                              TextSpan(
                                text: 'Emergency Response: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text:
                                    'You will be in charge of promptly determining the circumstances and launching the necessary actions in the event of an emergency. For prompt assistance, this can entail calling emergency services or contacting pre-designated contacts.\n\n',
                              ),
                              TextSpan(
                                text: 'Permission-Based Access Control: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text:
                                    'This regulates access to private data. Only when specifically authorised by the device user can you view sensitive data, protecting their security and privacy.\n\n',
                              ),
                              TextSpan(
                                text: 'No Data Alteration: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text:
                                    'Although you are able to view private data, you are unable to download, remove, or change any of it. This preserves user confidence and safeguards the accuracy of user data.',
                              ),
                            ],
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    // Next Button
                    SizedBox(
                      width: screenWidth * 0.45,
                      height: screenHeight * 0.06,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Moni1()),
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
                              height: 1.33,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
