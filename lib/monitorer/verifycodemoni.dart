import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wearmokoapp/monitorer/monihome.dart';
import 'package:google_fonts/google_fonts.dart';

class Moni1 extends StatefulWidget {
  const Moni1({super.key});

  @override
  _Moni1State createState() => _Moni1State();
}

class _Moni1State extends State<Moni1> {
  final List<TextEditingController> _controllers =
      List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());
  final List<String> _code = List.filled(5, '');

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
    if (value.isNotEmpty && index < 4) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
    _code[index] = value.toUpperCase();
  }

  Future<void> _verifyCode() async {
    final enteredCode = _code.join();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorDialog('No User', 'You must be logged in to join a circle.');
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      String? previouslyJoinedCode = userDoc.data()?['joinedCircleCode'];

      if (enteredCode == previouslyJoinedCode) {
        _showErrorDialog(
          'Code Reuse Not Allowed',
          'You cannot use the same code that blocked your account. Please use a different code.',
        );
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('circleCode', isEqualTo: enteredCode)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'joinedCircleCode': enteredCode,
          'joinedAt': FieldValue.serverTimestamp(),
          'isBlocked': FieldValue.delete(),
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MoniHome()),
        );
      } else {
        _showErrorDialog('Invalid Code',
            'The entered code is incorrect or not for a device user.');
      }
    } catch (e) {
      _showErrorDialog('Error',
          'You cannot use the same code that blocked your account. Please try again.');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(message,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w400)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Circle Code Required',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Please Insert Code', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const backgroundColor = Color(0xFFEAA647);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  color: backgroundColor,
                  image: DecorationImage(
                    image: AssetImage('assets/backgroundsplash.png'),
                    fit: BoxFit.cover,
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
                      'Please enter the code provided by the device user.',
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
                          ),
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            maxLength: 1,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Za-z0-9]')),
                              TextInputFormatter.withFunction(
                                  (oldValue, newValue) {
                                String upperCaseText =
                                    newValue.text.toUpperCase();
                                _handleInputChange(upperCaseText, index);
                                return TextEditingValue(
                                  text: upperCaseText,
                                  selection: newValue.selection,
                                );
                              }),
                            ],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: screenWidth * 0.06,
                              color: Colors.black,
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    GestureDetector(
                      onTap: _verifyCode,
                      child: Container(
                        width: screenWidth * 0.5,
                        height: screenHeight * 0.07,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          border: Border.all(color: const Color(0xFFA8A8A8)),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            'Proceed',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: screenWidth * 0.05,
                              color: Colors.black,
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
      ),
    );
  }
}
