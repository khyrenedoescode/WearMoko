import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wearmokoapp/login.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to handle password reset
  Future<void> _resetPassword() async {
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      // Show a message to the user after sending the reset email
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent!')),
      );
      // Navigate to the login page after sending the email
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
    } catch (e) {
      print("Error resetting password: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFEAA647);
    const Color boxColor = Colors.white;
    final Color borderColor = Colors.black.withOpacity(0.8);
    const Color textColorDarker = Color(0xFF212121);

    // Responsive width and height
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Center(
        child: Container(
          width: screenWidth,
          height: screenHeight,
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
              Positioned(
                left: screenWidth * 0.20,
                top: screenHeight * 0.17,
                child: Text(
                  'Forgot Password',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: screenWidth * 0.08,
                    color: textColorDarker,
                    height: 1.33,
                  ),
                ),
              ),

              // Email Text Field
              Positioned(
                left: screenWidth * 0.10,
                top: screenHeight * 0.24,
                child: Container(
                  width: screenWidth * 0.8,
                  height: screenHeight * 0.06,
                  decoration: BoxDecoration(
                    color: boxColor,
                    border: Border.all(color: borderColor, width: 1.5),
                    borderRadius: BorderRadius.circular(5.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 1.0,
                        offset: const Offset(0, 0.5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'Email Address',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                      border: InputBorder.none,
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w400,
                      color: textColorDarker,
                    ),
                  ),
                ),
              ),

              // Send Email Button
              Positioned(
                left: screenWidth * 0.19,
                top: screenHeight * 0.34,
                child: ElevatedButton(
                  onPressed: _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: textColorDarker,
                    minimumSize: Size(screenWidth * 0.6, screenHeight * 0.07),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    side: BorderSide(color: borderColor, width: 1.6),
                    shadowColor: Colors.black.withOpacity(0.25),
                    elevation: 4.0,
                  ),
                  child: Text(
                    'Send Email',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: screenWidth * 0.05,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
