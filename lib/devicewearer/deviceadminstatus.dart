import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wearmokoapp/devicewearer/devicenewcode.dart';
import 'package:google_fonts/google_fonts.dart';

class DeviceAdmin extends StatefulWidget {
  const DeviceAdmin({super.key});

  @override
  _DeviceAdminState createState() => _DeviceAdminState();
}

class _DeviceAdminState extends State<DeviceAdmin> {
  String userName = '';
  String circleCode = '';
  String? _profileImageUrl;

  // 🆕 Real-time Stream para sa Circle Members
  Stream<QuerySnapshot>? _membersStream;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Ito na ang mag-se-set ng _membersStream
    _fetchUserProfileImage();
  }

  // ----------------------------------------------------------------------
  // 1. Fetch User Data and Setup Stream
  // ----------------------------------------------------------------------
  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => userName = 'No user logged in');
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        String firstName = userDoc['firstName'] ?? 'Unknown';
        String lastName = userDoc['lastName'] ?? 'User';
        // Tiyakin na ang field name sa Firestore ay 'circleCode' o 'joinedCircleCode'
        // Gamitin ko 'circleCode' muna, base sa original code mo
        circleCode = userDoc['circleCode'] ?? '';

        setState(() {
          userName = '$firstName $lastName';

          // 🎯 I-set up ang Real-Time Stream para sa members ng circle na ito
          if (circleCode.isNotEmpty) {
            _membersStream = FirebaseFirestore.instance
                .collection('users')
                .where('joinedCircleCode',
                    isEqualTo:
                        circleCode) // Tiyakin na ito ang tama mong field name
                .snapshots();
          }
        });
      } else {
        setState(() => userName = 'User data not found');
      }
    } catch (e) {
      setState(() => userName = 'Error fetching user data: $e');
    }
  }

  // ❌ Tinanggal ang _fetchCircleMembers() dahil pinalitan na ng StreamBuilder

  // ----------------------------------------------------------------------
  // 2. Blocking Logic
  // ----------------------------------------------------------------------
  Future<void> _blockUser(String uid) async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

      // Gumamit ng set(merge: true)
      await userDoc.set({
        'isBlocked': true,
      }, SetOptions(merge: true));

      // Ang StreamBuilder na ang bahala mag-refresh ng list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User blocked successfully. Logout triggered.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to block user: $e')),
        );
      }
    }
  }

  Future<void> _unblockUser(String uid) async {
    try {
      // Gumamit ng update()
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isBlocked': false,
      });

      // Ang StreamBuilder na ang bahala mag-refresh ng list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User unblocked successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unblock user: $e')),
        );
      }
    }
  }

  // ----------------------------------------------------------------------
  // 3. Other Helper Function
  // ----------------------------------------------------------------------
  Future<void> _fetchUserProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()!.containsKey('profileImage')) {
        setState(() => _profileImageUrl = doc.data()?['profileImage']);
      }
    }
  }

  // ----------------------------------------------------------------------
  // 4. Build UI
  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Admin Status',
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
      body: Column(
        children: [
          // User Info Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : const AssetImage('assets/userdash.png')
                          as ImageProvider,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    userName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) =>
                            DeviceNewCode(userName: userName),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                  child: Text(
                    'Admin',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: Colors.red,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Circle Members Header
          Container(
            width: double.infinity,
            color: const Color.fromRGBO(214, 214, 214, 0.2),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Circle members',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),

          // 🎯 Real-Time Member List gamit ang StreamBuilder
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _membersStream,
              builder: (context, snapshot) {
                if (_membersStream == null ||
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: GoogleFonts.poppins()));
                }

                final docs = snapshot.data?.docs ?? [];
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                // I-filter ang sarili (Device Wearer) mula sa listahan
                final filteredDocs =
                    docs.where((doc) => doc.id != currentUserId).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                      child: Text('No other members found in circle.',
                          style: GoogleFonts.poppins()));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final memberDoc = filteredDocs[index];
                    final data = memberDoc.data() as Map<String, dynamic>;

                    String firstName = data['firstName'] ?? 'Unknown';
                    String lastName = data['lastName'] ?? 'User';
                    // Tiyakin na nagbabasa ng isBlocked bilang boolean
                    bool isBlocked = data['isBlocked'] ?? false;
                    String uid = memberDoc.id;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$firstName $lastName',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          // 🎯 Block/Unblock Button Logic
                          GestureDetector(
                            // Kung naka-block (true), i-unblock. Kung hindi (false), i-block.
                            onTap: () =>
                                isBlocked ? _unblockUser(uid) : _blockUser(uid),
                            child: Icon(
                              isBlocked
                                  ? Icons.check_circle
                                  : Icons.remove_circle,
                              color: isBlocked ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
