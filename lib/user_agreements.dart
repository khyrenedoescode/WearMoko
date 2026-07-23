import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_signup_choice.dart';

class UserAgreements extends StatefulWidget {
  const UserAgreements({super.key});

  @override
  _UserAgreementsState createState() => _UserAgreementsState();
}

class _UserAgreementsState extends State<UserAgreements> {
  bool _isChecked = false;
  String _selectedContent = 'terms';

  final String _termsContent = '''
Our mobile application has been carefully designed to provide users with a comprehensive and user-friendly experience for monitoring and managing their tracking necklace device, all while adhering to the Unified Theory of Acceptance and Use of Technology (UTAUT) and the legal standards established by Philippine data privacy laws. The application includes a robust set of features designed to enhance user interaction and ensure optimal functionality.

The app enables users to effortlessly track the real-time location of their necklace device. This feature keeps you informed about the device's location at all times, providing peace of mind and security. In addition to location tracking, the app allows users to easily access recorded video and voice files captured by the necklace device. This feature is especially useful for reviewing any interactions or environmental details recorded by the device, providing users with valuable insights and a complete picture of the device's activity.

To ensure a smooth and efficient user experience, the app integrates with your phone's settings to enable critical features such as Location Services, Notifications, Files and Media access, and Contacts synchronization. Location Services are essential for accurate and real-time necklace tracking, while the Notifications feature allows users to set up alerts for a variety of scenarios, such as when the device leaves designated boundaries or experiences technical difficulties. This ensures that users are informed and can take appropriate action when necessary.

In accordance with Philippine data privacy laws, the application prioritizes user consent and data protection. It is intended to handle user data securely, with explicit consent protocols and transparent data practices. This adherence to legal standards ensures that all data handling is done in a way that protects user privacy and complies with regulatory requirements.
''';

  final String _privacyPolicyContent = '''
Welcome to WearMoko. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application (“App”) for tracking your necklace device. We are committed to protecting your privacy and ensuring that your personal information is handled securely and in compliance with applicable laws, including the data privacy laws of the Philippines. By using our App, you consent to the practices described in this Privacy Policy.

1. Information We Collect

a. Personal Information
We may collect personal information that you voluntarily provide to us, such as:

* Contact Information: Your name, email address, and phone number.
* Account Information: Username, password, and any other details you provide when creating an account.

b. Device Information
We collect information about your device, including:

* Device Identifier: Unique identifiers associated with your device.
* Operating System: The type and version of your mobile operating system.
* Mobile Network Information: Information about your mobile network provider.

c. Location Data
Our App collects real-time location data of your necklace device to provide tracking services. This data includes:

* Geographic Coordinates: Latitude and longitude information.

d. Media and Files
The App may access files and media stored on your device if you upload or view recordings or documents related to your necklace device.

e. Recorded Content
We may collect and store video and voice recordings from your necklace device, which are used to provide the functionality of reviewing interactions and environment.
''';

  void _updateContent(String contentType) {
    setState(() {
      _selectedContent = contentType;
    });
  }

  void _navigateToLoginSignup() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginSignupChoice(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
        maintainState: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double horizontalPadding = screenWidth * 0.08;
    final double containerPadding = screenWidth * 0.04;
    final double containerBorderRadius = screenWidth * 0.03;
    final double buttonHeight = screenHeight * 0.07;
    final double checkboxFontSize = screenWidth * 0.035;
    final double tabFontSize = screenWidth * 0.04;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/backgroundsplash.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
            colorFilter: ColorFilter.mode(
              const Color(0xFFEAA647).withOpacity(0.9),
              BlendMode.colorBurn,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 1),
                Flexible(
                  flex: 10,
                  child: Container(
                    padding: EdgeInsets.all(containerPadding),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(containerBorderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.012,
                            horizontal: screenWidth * 0.04,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBFB),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(containerBorderRadius),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTabButton(
                                  'Terms and Conditions', 'terms', tabFontSize),
                              _buildTabButton(
                                  'Privacy Policy', 'privacy', tabFontSize),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: screenWidth * 0.03,
                              left: screenWidth * 0.03,
                              right: screenWidth * 0.03,
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                _selectedContent == 'terms'
                                    ? _termsContent
                                    : _privacyPolicyContent,
                                style: GoogleFonts.poppins(
                                  fontSize: checkboxFontSize,
                                  fontWeight: FontWeight.w400,
                                  height: 1.5,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.justify,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 1),
                CheckboxListTile(
                  title: Text(
                    'I agree to the Terms and Conditions and Privacy Policy',
                    style: GoogleFonts.poppins(
                      fontSize: checkboxFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: _isChecked,
                  onChanged: (bool? value) {
                    setState(() {
                      _isChecked = value ?? false;
                    });
                  },
                  checkColor: Colors.white,
                  activeColor: const Color(0xFF795009),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                SizedBox(height: screenHeight * 0.03),
                SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: _isChecked ? _navigateToLoginSignup : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.black),
                      shadowColor: Colors.black.withOpacity(0.25),
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                    ),
                    child: Text(
                      'Get Started',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: screenWidth * 0.06,
                        color: const Color(0xFF212121),
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, String contentType, double fontSize) {
    return GestureDetector(
      onTap: () => _updateContent(contentType),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: _selectedContent == contentType
              ? const Color(0xFF543509)
              : const Color(0xFF212121),
          fontSize: fontSize,
          fontWeight: _selectedContent == contentType
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    );
  }
}
