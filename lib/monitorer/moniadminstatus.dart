import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class MoniAdmin extends StatefulWidget {
  const MoniAdmin({super.key});

  @override
  _MoniAdminState createState() => _MoniAdminState();
}

class _MoniAdminState extends State<MoniAdmin> {
  String userName = 'Loading...';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          userName = 'No user logged in';
          isLoading = false;
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        setState(() {
          userName = 'User not found';
          isLoading = false;
        });
        return;
      }

      final joinedCircleCode = userDoc.data()?['joinedCircleCode'] ?? '';
      if (joinedCircleCode.isEmpty) {
        setState(() {
          userName = 'No joined circle found';
          isLoading = false;
        });
        return;
      }

      final circleSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('circleCode', isEqualTo: joinedCircleCode)
          .get();

      if (circleSnapshot.docs.isEmpty) {
        setState(() {
          userName = 'Circle code not found';
          isLoading = false;
        });
        return;
      }

      final deviceUser = circleSnapshot.docs.first;
      final firstName = deviceUser['firstName'] ?? 'Unknown';
      final lastName = deviceUser['lastName'] ?? 'User';

      setState(() {
        userName = '$firstName $lastName';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        userName = 'Error fetching user data';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
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
        'Admin Status',
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
          child: Image.asset(
            'assets/back.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.25)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // User Image
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage('assets/userdash.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Name & Admin label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 100,
                              child: LinearProgressIndicator(
                                color: Color(0xFFFFD498),
                                backgroundColor: Color(0xFFF5F5F5),
                              ),
                            )
                          : Text(
                              userName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                      const SizedBox(height: 4),
                      Text(
                        'Admin',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
