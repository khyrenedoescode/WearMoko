import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wearmokoapp/signup3.dart'; // <-- Poppins

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  _PersonalInformationPageState createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _selectedMonth;
  String? _selectedDay;
  String? _selectedYear;
  String? _errorText;
  bool _isButtonEnabled = false;
  bool _isObscure = true;
  bool _isConfirmPasswordVisible = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _validatePassword() {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final passwordPattern = RegExp(r'^[a-zA-Z0-9]{8,}$');

    setState(() {
      if (password.isEmpty || confirmPassword.isEmpty) {
        _errorText = null;
        _isButtonEnabled = false;
      } else if (!passwordPattern.hasMatch(password)) {
        _errorText =
            'Password must be at least 8 characters with letters and numbers only.';
        _isButtonEnabled = false;
      } else if (password != confirmPassword) {
        _errorText = 'Passwords do not match.';
        _isButtonEnabled = false;
      } else {
        _errorText = null;
        _isButtonEnabled = true;
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<void> _signupUser() async {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _selectedMonth == null ||
        _selectedDay == null ||
        _selectedYear == null) {
      _showErrorDialog('Please fill all fields before submitting');
      return;
    }

    _validatePassword();
    if (_errorText != null) {
      _showErrorDialog(_errorText!);
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', false);

      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'birthday': {
          'month': _selectedMonth,
          'day': _selectedDay,
          'year': _selectedYear,
        },
      });

      await saveFCMToken();

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const EmailVerificationPage(),
          transitionDuration: Duration.zero, // no animation
        ),
      );
    } catch (e) {
      String errorMessage = 'An error occurred. Please try again.';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'The email address is already in use.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is not valid.';
            break;
          case 'weak-password':
            errorMessage = 'The password is too weak.';
            break;
        }
      }
      _showErrorDialog(errorMessage);
    }
  }

  Future<void> saveFCMToken() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'fcmToken': fcmToken,
      });
      print('✅ FCM Token saved: $fcmToken');
    }
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hintText,
      bool obscureText = false,
      VoidCallback? toggleVisibility}) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.8), width: 1.6),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 1.0,
            offset: const Offset(0, 0.5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onChanged: (_) => _validatePassword(),
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          suffixIcon: toggleVisibility != null
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.black87,
                  ),
                  onPressed: toggleVisibility,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildDropdown(
      {required String? value,
      required String hint,
      required List<String> items,
      required void Function(String?) onChanged}) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.8), width: 1.6),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 1.0,
            offset: const Offset(0, 0.5),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(hint, style: GoogleFonts.poppins(fontSize: 16)),
        ),
        isExpanded: true,
        underline: Container(),
        items: items.map((e) {
          return DropdownMenuItem<String>(
            value: e,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(e, style: GoogleFonts.poppins(fontSize: 16)),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    const Color backgroundColor = Color(0xFFEAA647);

    return Scaffold(
      backgroundColor: backgroundColor, // ✅ use background color
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: width * 0.08, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Create Account',
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please enter the information needed below',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _firstNameController,
                      hintText: 'First Name',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _lastNameController,
                      hintText: 'Last Name',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTextField(
                  controller: _emailController, hintText: 'Email Address'),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _passwordController,
                hintText: 'Password',
                obscureText: _isObscure,
                toggleVisibility: () {
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm Password',
                obscureText: _isConfirmPasswordVisible,
                toggleVisibility: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _errorText!,
                    style: GoogleFonts.poppins(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      value: _selectedMonth,
                      hint: 'Month',
                      items: List.generate(
                          12, (i) => (i + 1).toString().padLeft(2, '0')),
                      onChanged: (v) => setState(() => _selectedMonth = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDropdown(
                      value: _selectedDay,
                      hint: 'Day',
                      items: List.generate(
                          31, (i) => (i + 1).toString().padLeft(2, '0')),
                      onChanged: (v) => setState(() => _selectedDay = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDropdown(
                      value: _selectedYear,
                      hint: 'Year',
                      items: List.generate(
                          100, (i) => (DateTime.now().year - i).toString()),
                      onChanged: (v) => setState(() => _selectedYear = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isButtonEnabled ? _signupUser : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  side: BorderSide(
                      color: Colors.black.withOpacity(0.8), width: 1.6),
                  shadowColor: Colors.black.withOpacity(0.25),
                  elevation: 4,
                ),
                child: Text(
                  'Submit',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
