import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wearmokoapp/usermonitor.dart';

class Monitor1 extends StatelessWidget {
  const Monitor1({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const backgroundColor = Color(0xFFEAA647);

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
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
        child: Container(
          // Semi-transparent overlay to mimic blur effect
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: Container(
              width: screenWidth * 0.9,
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.04,
                horizontal: screenWidth * 0.05,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border.all(color: Colors.black, width: screenWidth * 0.003),
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
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
                      fontSize: screenWidth * 0.08, // scales with screen width
                      color: const Color(0xFFA66D1D),
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  // Scrollable descriptive text
                  SizedBox(
                    height: screenHeight * 0.45,
                    child: SingleChildScrollView(
                      child: Text(
                        '''We are delighted to have you as a member of our community, where your safety and well-being are at the heart of everything we do. WearMoko is the ultimate mobile application for real-time monitoring and emergency response, designed to give you the peace of mind you deserve in any situation. As you begin to explore the app, you'll notice a plethora of intuitive and user-friendly features designed to keep you connected, informed, and secure. 

WearMoko is designed to empower you in your daily life, from tracking your location in real time to accessing private information with a single tap. Whether you're at home, on the go, or out in the community, our app is a reliable companion, ensuring that help is always available. We believe that safety should never be considered a luxury, which is why we developed a platform that puts you in control of your loved one's safety and security.

In addition to real-time monitoring, WearMoko allows you to share your status with loved ones, keeping them informed and involved in your journey. Stay safe, stay connected, and feel empowered on your journey with us!''',
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Monitorer()),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
