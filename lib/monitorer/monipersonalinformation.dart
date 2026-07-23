import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart'; // <-- Added Google Fonts

class MoniPersonalInfo extends StatefulWidget {
  const MoniPersonalInfo({super.key});

  @override
  _MoniPersonalInfoState createState() => _MoniPersonalInfoState();
}

class _MoniPersonalInfoState extends State<MoniPersonalInfo> {
  String fullName = 'Loading...';
  String email = 'Loading...';
  String phoneNumber = 'Loading...';
  String _selectedMonth = '';
  String _selectedDay = '';
  String _selectedYear = '';
  String? _profileImageUrl;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          var userData = userDoc.data() as Map<String, dynamic>;

          setState(() {
            fullName =
                '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                    .trim();
            email = user.email ?? 'No email';
            _profileImageUrl = userData['profileImage'];

            if (userData['birthday'] != null) {
              var birthday = userData['birthday'] as Map<String, dynamic>;
              _selectedMonth = birthday['month'] ?? '';
              _selectedDay = birthday['day'] ?? '';
              _selectedYear = birthday['year'] ?? '';
            } else {
              _selectedMonth = '';
              _selectedDay = '';
              _selectedYear = '';
            }

            phoneNumber = userData['phoneNumber'] ?? 'No phone number';
          });

          nameController.text = fullName;
          emailController.text = email;
          phoneController.text = phoneNumber;
        } else if (mounted) {
          setState(() {
            fullName = 'User';
            email = user.email ?? 'No email';
            phoneNumber = 'Not specified';
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
        if (mounted) {
          setState(() {
            fullName = 'Error';
            email = 'Error';
            phoneNumber = 'Error';
          });
        }
      }
    }
  }

  String _getFormattedBirthday() {
    if (_selectedMonth.isEmpty ||
        _selectedDay.isEmpty ||
        _selectedYear.isEmpty) {
      return 'No birthdate';
    }
    String monthName = _getMonthName(_selectedMonth);
    String day = _selectedDay.padLeft(2, '0');
    return '$monthName $day, $_selectedYear';
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
    int monthIndex = int.tryParse(month) ?? 0;
    if (monthIndex < 1 || monthIndex > 12) return 'Invalid month';
    return monthNames[monthIndex - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 10),
            _buildDivider(),
            const SizedBox(height: 10),
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF4B315),
      elevation: 1,
      title: Text(
        'Personal Information',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w900,
          fontSize: 22,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.only(left: 20.0),
          child: Image.asset('assets/back.png', fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30.0, 40.0, 30.0, 30.0),
      child: Row(
        children: [
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                fit: BoxFit.cover,
                image: _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : const AssetImage('assets/userdash.png') as ImageProvider,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 22,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w300,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34.0),
      child: Container(
        width: double.infinity,
        height: 1,
        color: const Color.fromRGBO(217, 217, 217, 0.5),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(50.0, 10.0, 30.0, 30.0),
      child: Column(
        children: [
          _buildInfoRow('Name:', fullName),
          _buildInfoRow('Birthdate:', _getFormattedBirthday()),
          _buildInfoRow('Email Address:', email),
          _buildInfoRow('Phone Number:', phoneNumber),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w300,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 15,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
