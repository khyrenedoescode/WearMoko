import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class DeviceNewCode extends StatefulWidget {
  final String userName;
  const DeviceNewCode({super.key, required this.userName});

  @override
  _DeviceNewCodeState createState() => _DeviceNewCodeState();
}

class _DeviceNewCodeState extends State<DeviceNewCode> {
  bool _showFields = false;
  final TextEditingController _newCodeController = TextEditingController();
  final TextEditingController _confirmCodeController = TextEditingController();
  String _currentCode = "";
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCurrentCode();
    _newCodeController.addListener(_validateInput);
    _confirmCodeController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _newCodeController.dispose();
    _confirmCodeController.dispose();
    super.dispose();
  }

  void _validateInput() {
    final newCode = _newCodeController.text.toUpperCase();
    final confirmCode = _confirmCodeController.text.toUpperCase();
    setState(() {
      if (newCode.length < 5 || confirmCode.length < 5) {
        _errorMessage = "Code must be 5 letters";
      } else if (newCode != confirmCode) {
        _errorMessage = "Codes do not match";
      } else {
        _errorMessage = null;
      }
    });
  }

  Future<void> _fetchCurrentCode() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (snapshot.exists && snapshot.data() != null) {
        setState(() {
          _currentCode = snapshot['circleCode'] ?? 'No code available';
        });
      }
    } catch (e) {
      setState(() => _currentCode = "Error fetching code");
      print("Error fetching circleCode: $e");
    }
  }

  Future<void> _saveNewCode() async {
    final newCode = _newCodeController.text.toUpperCase();
    if (_errorMessage != null || newCode.isEmpty) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'circleCode': newCode,
      });

      await _updateJoinedUsers(newCode);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code updated successfully!')),
      );

      setState(() {
        _showFields = false;
        _currentCode = newCode;
        _newCodeController.clear();
        _confirmCodeController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateJoinedUsers(String newCode) async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('joinedCircleCode', isEqualTo: _currentCode)
          .get();
      for (var doc in usersSnapshot.docs) {
        await doc.reference.update({'joinedCircleCode': newCode});
      }
    } catch (e) {
      print("Error updating joined users: $e");
    }
  }

  Widget _buildCodeField(
      {required TextEditingController controller, required String hintText}) {
    return Container(
      width: double.infinity,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFBBB4B4), width: 0.8),
        borderRadius: BorderRadius.circular(5),
      ),
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.characters,
        maxLength: 5,
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              RegExp(r'[A-Za-z]')), // letters only
          UpperCaseTextFormatter(), // auto-uppercase
        ],
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          counterText: "",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSaveEnabled =
        _errorMessage == null && _newCodeController.text.length == 5;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.userName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF4B315),
        elevation: 1,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.only(left: 20),
            child: Image.asset('assets/back.png', fit: BoxFit.contain),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            "Current Code: $_currentCode",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              setState(() {
                _showFields = !_showFields;
                if (_showFields) _fetchCurrentCode();
              });
            },
            child: Text(
              'Create New Code',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ),
          const Divider(height: 20, color: Colors.grey),
          if (_showFields) ...[
            _buildCodeField(
                controller: _newCodeController, hintText: 'New Code'),
            _buildCodeField(
                controller: _confirmCodeController,
                hintText: 'Confirm New Code'),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: isSaveEnabled ? _saveNewCode : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSaveEnabled ? const Color(0xFFF4B315) : Colors.grey,
                  minimumSize: const Size(200, 50),
                ),
                child: const Text(
                  'Save Code',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// Formatter to auto-uppercase letters
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
