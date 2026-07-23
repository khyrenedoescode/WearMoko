import 'package:flutter/material.dart';
import 'package:wearmokoapp/devicewearer/deviceeditname.dart';
import 'package:wearmokoapp/monitorer/monieditnumber.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart'; // Google Fonts

class DeviceEdit extends StatefulWidget {
  const DeviceEdit({super.key});

  @override
  _DeviceEditState createState() => _DeviceEditState();
}

class _DeviceEditState extends State<DeviceEdit> {
  String fullName = '';
  String email = '';
  String phoneNumber = '';
  String profileImageUrl = 'assets/userdash.png';
  String _selectedMonth = '';
  String _selectedDay = '';
  String _selectedYear = '';

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;

          setState(() {
            fullName = '${userData['firstName']} ${userData['lastName']}';
            email = user.email ?? 'No email';
            phoneNumber = userData['phoneNumber'] ?? 'No phone number';
            profileImageUrl = userData['profileImage'] ?? 'assets/userdash.png';

            if (userData['birthday'] != null) {
              final birthday = userData['birthday'] as Map<String, dynamic>;
              _selectedMonth = birthday['month'] ?? '';
              _selectedDay = birthday['day'] ?? '';
              _selectedYear = birthday['year'] ?? '';
            }

            nameController.text = fullName;
            emailController.text = email;
            phoneController.text = phoneNumber;
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
  }

  String _getFormattedBirthday() {
    if (_selectedMonth.isEmpty ||
        _selectedDay.isEmpty ||
        _selectedYear.isEmpty) {
      return 'No birthdate';
    }
    final monthName = _getMonthName(_selectedMonth);
    return '$monthName ${_selectedDay.padLeft(2, '0')}, $_selectedYear';
  }

  String _getMonthName(String month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final monthIndex = int.tryParse(month) ?? 0;
    if (monthIndex < 1 || monthIndex > 12) return 'Invalid month';
    return monthNames[monthIndex - 1];
  }

  Widget _buildScrollableText(String text) {
    return Expanded(
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.black, Colors.transparent],
          stops: [0.9, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w400,
              fontSize: 15,
              color: const Color(0xFF000000),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(
      String label, String value, VoidCallback? onTap, String? buttonText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                fontSize: 14,
                color: const Color(0xFF000000),
              ),
            ),
          ),
          _buildScrollableText(value),
          if (onTap != null && buttonText != null)
            GestureDetector(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  buttonText,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: const Color(0xFFFF0000),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4B315),
        elevation: 1,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.only(left: 20.0),
            child: Image.asset('assets/back.png', fit: BoxFit.contain),
          ),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Image
            Padding(
              padding: EdgeInsets.only(top: height * 0.03, bottom: 16),
              child: CircleAvatar(
                radius: width * 0.125,
                backgroundImage: profileImageUrl.startsWith('http')
                    ? NetworkImage(profileImageUrl)
                    : const AssetImage('assets/userdash.png') as ImageProvider,
              ),
            ),
            // Profile details
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 16),
              child: Column(
                children: [
                  _buildProfileRow(
                    'Name:',
                    fullName,
                    () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const DevEditName(),
                        transitionsBuilder: (_, __, ___, child) => child,
                        maintainState: true,
                      ),
                    ),
                    'Edit',
                  ),
                  _buildProfileRow(
                      'Birthdate:', _getFormattedBirthday(), null, null),
                  _buildProfileRow('Email Address:', email, null, null),
                  _buildProfileRow(
                    'Phone Number:',
                    phoneNumber,
                    () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const MoniEditNum(),
                        transitionsBuilder: (_, __, ___, child) => child,
                        maintainState: true,
                      ),
                    ),
                    'Add',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
