import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // 👈 BAGO: Idinagdag 'to
import 'package:wearmokoapp/monitorer/moniprofile.dart'; // 👈 BAGO: Pinalitan 'yung 'DeviceProfile'

class MoniEditNum extends StatefulWidget {
  const MoniEditNum({super.key});

  @override
  _MoniEditNumState createState() => _MoniEditNumState();
}

class _MoniEditNumState extends State<MoniEditNum> {
  final TextEditingController _phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //
  // ⬇️ BAGO: Idinagdag 'yung 'initState' at 'getUserData' ⬇️
  //
  @override
  void initState() {
    super.initState();
    _getUserData(); // Para ma-load 'yung current phone number
  }

  // Fetch current user data from Firestore
  Future<void> _getUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists && mounted) {
          var userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _phoneController.text = userData['phoneNumber'] ?? '';
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
  }
  // ⬆️ DULO NG BAGO ⬆️
  //

  // Function to save the phone number to Firebase
  Future<void> _savePhoneNumber() async {
    String phoneNumber = _phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      // Show error if the phone number is empty
      _showErrorDialog("Please enter a phone number.");
      return;
    }

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Update the user's phone number in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'phoneNumber': phoneNumber,
        });

        // Show success message
        // ⬇️ BINAGO: 'Yung success dialog, in-update ko ⬇️
        _showSuccessDialog("Phone number updated successfully.");
      }
    } catch (e) {
      // Handle errors
      _showErrorDialog("An error occurred while updating your phone number.");
    }
  }

  // Function to show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to show success dialog
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                //
                // ⬇️ BINAGO: Pinalitan 'yung 'DeviceProfile' ⬇️
                //
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const Moniprof()), // 👈 Dapat 'Moniprof'
                );
                // ⬆️ DULO NG PAGBABAGO ⬆️
                //
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    //
    // ⬇️ BAGO: Pinalitan 'yung buong build method ⬇️
    //
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Ginamit 'yung style ng MoniEditName
        backgroundColor: const Color(0xFFF4B315),
        elevation: 1,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.only(left: 20.0), // Inayos 'yung padding
            child: Image.asset(
              'assets/back.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          'Edit Phone Number',
          style: GoogleFonts.poppins(
            // Ginamit 'yung GoogleFonts
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Title ---
              Text(
                'Edit or Add Phone Number',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 22,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              // --- Subtitle ---
              Text(
                'Manage your mobile number to make sure your contact info is accurate and up to date.',
                textAlign: TextAlign.justify,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w300,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),
              // --- Text Field (Ginaya 'yung style ng MoniEditName) ---
              _buildEditablePhoneRow('Phone Number:', _phoneController),

              const SizedBox(height: 40),

              // --- Save Button (Ginaya 'yung style ng MoniEditName) ---
              GestureDetector(
                onTap: _savePhoneNumber,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA500),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'SAVE',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ⬇️ BAGO: Helper widget para sa text field (gaya ng sa MoniEditName) ⬇️
  Widget _buildEditablePhoneRow(
      String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone, // 👈 Idinagdag para sa phone
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 15,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
