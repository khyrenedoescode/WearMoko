import 'package:flutter/material.dart';
import 'package:wearmokoapp/monitorer/moniadminstatus.dart';
import 'package:wearmokoapp/monitorer/verifycodemoni.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class MoniCircleM extends StatelessWidget {
  const MoniCircleM({super.key});

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

  void _showLeaveCircleOverlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MoniLeaveCircle(
          onSuccess: () {
            _showSnackbar(context, "Successfully left the Circle.",
                isError: false);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const Moni1()),
              (Route<dynamic> route) => false,
            );
          },
          onError: (message) {
            _showSnackbar(context, message, isError: true);
          },
        );
      },
    );
  }

  Widget _buildActionRow({
    required String title,
    required VoidCallback onTap,
    Color titleColor = Colors.black,
    IconData trailingIcon = Icons.arrow_forward_ios,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Color.fromRGBO(217, 217, 217, 0.5),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: titleColor,
                ),
              ),
            ),
            Icon(
              trailingIcon,
              size: 16,
              color: titleColor == Colors.red
                  ? Colors.red.withOpacity(0.8)
                  : Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4B315),
        elevation: 1,
        title: Text(
          'Circle Management',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.only(left: 20.0),
            child: Image.asset(
              'assets/back.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildActionRow(
            title: 'Admin Status',
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) =>
                      const MoniAdmin(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            },
            context: context,
          ),
          _buildActionRow(
            title: 'Leave Circle',
            titleColor: Colors.red,
            onTap: () => _showLeaveCircleOverlay(context),
            context: context,
          ),
        ],
      ),
    );
  }
}

class MoniLeaveCircle extends StatelessWidget {
  final VoidCallback onSuccess;
  final Function(String) onError;

  const MoniLeaveCircle({
    super.key,
    required this.onSuccess,
    required this.onError,
  });

  Future<void> _removeJoinedCircleCode(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in.');

      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      await userDocRef.update({
        'joinedCircleCode': FieldValue.delete(),
      });

      Navigator.of(context).pop();
      onSuccess();
    } catch (e) {
      Navigator.of(context).pop();
      onError('Failed to leave circle. Please try again.');
      print('Error removing joined circle code: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 10,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Leaving the Circle',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 22,
                color: const Color(0xFF650000),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to leave the Circle? '
              'All circle functionalities will be disabled.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'No',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _removeJoinedCircleCode(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Yes',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
