import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'package:wearmokoapp/devicewearer/devicedash1.dart';

class UserDevice extends StatefulWidget {
  const UserDevice({super.key});

  @override
  State<UserDevice> createState() => _UserDeviceState();
}

class _UserDeviceState extends State<UserDevice> {
  final List<TextEditingController> _controllers =
      List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());

  final List<String> deviceCodes = ['58786', '12292', '43464'];

  Future<void> saveDeviceCode(String code) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      try {
        await userRef.update({'deviceCode': code});
      } catch (e) {
        print("Error saving device code: $e");
      }
    }
  }

  void _handleInputChange(String value, int index) {
    // SAFETY: check if node is still mounted before requesting focus
    if (value.length == 1 && index < 4) {
      if (_focusNodes[index + 1].context != null) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      }
    } else if (value.isEmpty && index > 0) {
      if (_focusNodes[index - 1].context != null) {
        FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
      }
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _submitCode() async {
    FocusScope.of(context).unfocus(); // unfocus all nodes first

    String enteredCode = _controllers.map((c) => c.text).join();

    // 🔹 Check if entered code is in the allowed list
    if (!deviceCodes.contains(enteredCode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid code!')),
      );
      return;
    }

    // 🔹 Check Firestore if the code is already used by another Device Wearer
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Device Wearer')
        .where('deviceCode', isEqualTo: enteredCode)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'This device code is already used by another user. Please try another code.')),
      );
      return;
    }

    // 🔹 Save code for current user
    await saveDeviceCode(enteredCode);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DeviceDash(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  void _skip() {
    FocusScope.of(context).unfocus();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DeviceDash(),
        transitionDuration: Duration.zero,
      ),
    );
  }

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
                  colorFilter:
                      ColorFilter.mode(backgroundColor, BlendMode.colorBurn),
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
                  Text(
                    'To Continue',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      fontSize: screenWidth * 0.08,
                      color: const Color(0xFFA66D1D),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    'Please enter your device code.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w400,
                      fontSize: screenWidth * 0.045,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      return Container(
                        width: screenWidth * 0.12,
                        height: screenHeight * 0.08,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              offset: const Offset(0, 4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          maxLength: 1,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: screenWidth * 0.06,
                              color: Colors.black),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                          ),
                          onChanged: (value) =>
                              _handleInputChange(value, index),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  GestureDetector(
                    onTap: _submitCode,
                    child: Container(
                      width: screenWidth * 0.5,
                      height: screenHeight * 0.07,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAA647),
                        border: Border.all(color: const Color(0xFFA8A8A8)),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Done',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: screenWidth * 0.05,
                            color: const Color(0xFF212121),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  GestureDetector(
                    onTap: _skip,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w400,
                        fontSize: screenWidth * 0.045,
                        color: Colors.black,
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
