import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wearmokoapp/devicewearer_screen.dart';

class CreatingASpaceScreen2 extends StatefulWidget {
  final String randomCode;

  const CreatingASpaceScreen2({super.key, required this.randomCode});

  @override
  _CreatingASpaceScreen2State createState() => _CreatingASpaceScreen2State();
}

class _CreatingASpaceScreen2State extends State<CreatingASpaceScreen2> {
  final List<TextEditingController> _controllers =
      List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _updateTextFields();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleInputChange(String value, int index) {
    if (value.length == 1 && index < 4) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  void _updateTextFields() {
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].text = widget.randomCode[i];
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(
        text: 'Here is your family invitation code: ${widget.randomCode}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invitation code copied!')),
    );
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
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
                  vertical: screenHeight * 0.05),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.05),
                  Text(
                    'Share the invitation code with your family',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.055,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),
                  // Code Fields Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      5,
                      (index) => Container(
                        width: screenWidth * 0.12,
                        height: screenHeight * 0.06,
                        decoration: BoxDecoration(
                          color: boxColor,
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
                          style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.w700,
                              color: textColor),
                          decoration: const InputDecoration(
                              counterText: '', border: InputBorder.none),
                          onChanged: (value) =>
                              _handleInputChange(value, index),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Copy Code Button
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.07,
                    child: ElevatedButton(
                      onPressed: _copyToClipboard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: boxColor,
                        side: const BorderSide(color: borderColor, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        shadowColor: Colors.black.withOpacity(0.25),
                        elevation: 4,
                      ),
                      child: Text(
                        'Share code',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: screenWidth * 0.05,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  // Done Sharing Text
                  GestureDetector(
                    onTap: () async {
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          final userRef = FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid);

                          await userRef
                              .collection('invitationCodes')
                              .doc()
                              .set({
                            'code': widget.randomCode,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          await userRef.set({'circleCode': widget.randomCode},
                              SetOptions(merge: true));

                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const Device(),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                              transitionsBuilder: (_, __, ___, child) => child,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('User not logged in!')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error saving code: $e')),
                        );
                      }
                    },
                    child: Text(
                      'Done sharing',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: screenWidth * 0.045,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
