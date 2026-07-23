import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MoniEditPass extends StatefulWidget {
  const MoniEditPass({super.key});

  @override
  _MoniEditPassState createState() => _MoniEditPassState();
}

class _MoniEditPassState extends State<MoniEditPass> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackbar(BuildContext context, String message,
      {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("No authenticated user found.");
      }

      if (user.providerData.every((info) => info.providerId != 'password')) {
        _showSnackbar(
            context, "Password cannot be changed for this login method.");
        setState(() {
          _errorMessage = "Password cannot be changed for this login method.";
        });
        return;
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPassword);

      _showSnackbar(context, 'Password updated successfully!', isError: false);

      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'wrong-password') {
        message = 'The current password you entered is incorrect.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many failed attempts. Please try again later.';
      } else if (e.code == 'user-disabled') {
        message = 'Your account has been disabled.';
      } else if (e.code == 'weak-password') {
        message = 'The new password is too weak.';
      } else {
        message = 'An error occurred: ${e.message}';
      }

      _showSnackbar(context, message);
      if (mounted) {
        setState(() {
          _errorMessage = message;
        });
      }
    } catch (e) {
      String message = 'An unexpected error occurred. Please try again.';
      _showSnackbar(context, message);
      if (mounted) {
        setState(() {
          _errorMessage = message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Change Password',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 22,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Your password must be at least 6 characters and should include a combination of numbers, letters, and special characters (!@#).',
                  textAlign: TextAlign.justify,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w300,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 25),
                _buildPasswordField(
                  controller: _currentPasswordController,
                  hintText: 'Current Password',
                  obscureText: !_isCurrentPasswordVisible,
                  onToggleVisibility: () {
                    setState(() {
                      _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                    });
                  },
                  isPasswordVisible: _isCurrentPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: _newPasswordController,
                  hintText: 'New Password',
                  obscureText: !_isNewPasswordVisible,
                  onToggleVisibility: () {
                    setState(() {
                      _isNewPasswordVisible = !_isNewPasswordVisible;
                    });
                  },
                  isPasswordVisible: _isNewPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password.';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long.';
                    }
                    if (!value.contains(RegExp(r'[a-zA-Z]')) ||
                        !value.contains(RegExp(r'[0-9]'))) {
                      return 'Password must contain letters and numbers.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm New Password',
                  obscureText: !_isConfirmPasswordVisible,
                  onToggleVisibility: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                  isPasswordVisible: _isConfirmPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password.';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                Center(
                  child: GestureDetector(
                    onTap: _isLoading ? null : _savePassword,
                    child: Container(
                      width: 194,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _isLoading
                            ? const Color(0xFFF4B315).withOpacity(0.5)
                            : const Color(0xFFF4B315),
                        border: Border.all(
                            color: const Color(0xFFD9D9D9), width: 0.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Color(0xFF212121))
                            : Text(
                                'Save',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                  color: const Color(0xFF212121),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF4B315),
      elevation: 1,
      centerTitle: true,
      title: Text(
        'Edit Password',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w900,
          fontSize: 22,
          color: Colors.black,
        ),
      ),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.only(left: 20.0),
          child: Image.asset(
            'assets/back.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required bool isPasswordVisible,
    required String? Function(String?) validator,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: Border.all(color: const Color(0xFFBBB4B4), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(12, 12, 13, 0.1),
            offset: Offset(0, 1),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Color.fromRGBO(12, 12, 13, 0.05),
            offset: Offset(0, 1),
            blurRadius: 4,
          ),
        ],
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.only(left: 15),
      alignment: Alignment.center,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w300,
            fontSize: 12,
            color: const Color(0xFF2B2B2B),
          ),
          border: InputBorder.none,
          suffixIcon: GestureDetector(
            onTap: onToggleVisibility,
            child: Opacity(
              opacity: 0.8,
              child: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                size: 24,
                color: const Color(0xFF33363F),
              ),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
        ),
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: Colors.black,
        ),
      ),
    );
  }
}
