import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class DeviceLocshare extends StatefulWidget {
  const DeviceLocshare({super.key});

  @override
  _DeviceLocshareState createState() => _DeviceLocshareState();
}

class _DeviceLocshareState extends State<DeviceLocshare> {
  bool isSwitched1 = false; // Main switch
  String? _profileImageUrl;
  String firstName = '';
  List<Map<String, dynamic>> circleMembers = [];
  List<bool> memberSwitchStates = [];
  List<String> memberUids = [];
  String circleCode = '';

  // Time formatter
  String formatGeoTime(Timestamp? ts) {
    if (ts == null) return "Unknown time";
    final date = ts.toDate();
    return DateFormat('h:mm a').format(date);
  }

  @override
  void initState() {
    super.initState();
    _loadUserAndMembers();
  }

  // Load user data + circle members
  Future<void> _loadUserAndMembers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!userDoc.exists) return;

      final data = userDoc.data() as Map<String, dynamic>;
      circleCode = data['circleCode'] ?? '';

      setState(() {
        firstName = data['firstName'] ?? 'User';
        _profileImageUrl = data['profileImage'];
        isSwitched1 = data['isSharingLocation'] ?? false;
      });

      // Get circle members
      await _fetchCircleMembers(circleCode, user.uid);
    } catch (e) {
      print('Error loading user or members: $e');
      setState(() {
        firstName = 'Error';
      });
    }
  }

  // Fetch circle members directly with their geolocation status
  Future<void> _fetchCircleMembers(String code, String selfUid) async {
    if (code.isEmpty) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('joinedCircleCode', isEqualTo: code)
          .where('role', isEqualTo: 'Monitoring User')
          .get();

      List<Map<String, dynamic>> members = [];
      List<bool> switches = [];
      List<String> uids = [];

      for (var doc in querySnapshot.docs) {
        if (doc.id == selfUid) continue; // Skip self

        final docData = doc.data();

        final lastGeoTime = docData['lastGeoOnTime'] as Timestamp?;

        members.add({
          'firstName': docData['firstName'] ?? 'User',
          'uid': doc.id,
          'profileImage': docData['profileImage'],
          'lastGeoOnTime': lastGeoTime,
        });

        bool isSharing = docData['geolocationEnabled'] ?? false;
        switches.add(isSharing);
        uids.add(doc.id);
      }

      setState(() {
        circleMembers = members;
        memberSwitchStates = switches;
        memberUids = uids;
      });
    } catch (e) {
      print('Error fetching circle members: $e');
    }
  }

  // Update main switch (your own sharing)
  Future<void> _updateSharingStatus(bool status) async {
    final now = Timestamp.now();

    setState(() {
      isSwitched1 = status;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'isSharingLocation': status,
          'lastGeoOnTime': status ? now : null,
        });
      } catch (e) {
        print('Error updating main sharing: $e');
        setState(() {
          isSwitched1 = !status;
        });
      }
    }
  }

  // Update individual member switch directly on their doc
  Future<void> _updateMemberSharing(
      String memberUid, bool value, int index) async {
    final now = Timestamp.now();

    setState(() {
      memberSwitchStates[index] = value;
      circleMembers[index]['lastGeoOnTime'] = value ? now : null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(memberUid)
          .update({
        'geolocationEnabled': value,
        'lastGeoOnTime': value ? now : null,
      });
    } catch (e) {
      print('Error updating member sharing: $e');
      // Revert local state kung may error
      setState(() {
        memberSwitchStates[index] = !value;
        circleMembers[index]['lastGeoOnTime'] = !value ? now : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4B315), // match DeviceCircleM
        elevation: 1,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.only(left: 20),
            child: Image.asset('assets/back.png', fit: BoxFit.contain),
          ),
        ),
        title: Text(
          'Location Sharing',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          // Main User Sharing
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(214, 214, 214, 0.2),
              border: Border.all(color: const Color(0xFFA5A5A5), width: 1),
            ),
            child: Text(
              'Your location Sharing',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ),
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 26.0, vertical: 10.0),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : const AssetImage('assets/userdash.png')
                          as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            title: Text(
              firstName.isEmpty ? 'User' : firstName,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w500),
            ),
            trailing: Switch(
              value: isSwitched1,
              onChanged: _updateSharingStatus,
              inactiveThumbColor: const Color.fromARGB(255, 255, 255, 255),
              inactiveTrackColor: const Color.fromARGB(255, 121, 116, 116),
              activeTrackColor: Colors.black,
            ),
          ),
          // Circle Members Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
            decoration: const BoxDecoration(
              color: Color.fromRGBO(214, 214, 214, 0.2),
              border: Border(
                  bottom: BorderSide(color: Color(0xFFA5A5A5), width: 0.5)),
            ),
            child: Text(
              'Circle member location',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ),

          // Circle Members List
          Expanded(
            child: circleMembers.isEmpty
                ? Center(
                    child: Text("No circle members found.",
                        style: GoogleFonts.poppins()))
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: circleMembers.length,
                    itemBuilder: (context, index) {
                      final member = circleMembers[index];
                      final memberProfileUrl = member['profileImage'];

                      return Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                              bottom: BorderSide(
                                  color: Color.fromRGBO(0, 0, 0, 0.25))),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 26.0, vertical: 8.0),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: memberProfileUrl != null
                                    ? NetworkImage(memberProfileUrl)
                                    : const AssetImage('assets/userdash.png')
                                        as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          title: Text(
                            member['firstName'] ?? 'User',
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            memberSwitchStates[index]
                                ? 'Sharing Enabled at ${formatGeoTime(circleMembers[index]['lastGeoOnTime'])}'
                                : 'Sharing Disabled',
                            style: GoogleFonts.poppins(
                              color: memberSwitchStates[index]
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Switch(
                            value: memberSwitchStates[index],
                            onChanged: (value) async {
                              await _updateMemberSharing(
                                  memberUids[index], value, index);
                            },
                            inactiveThumbColor:
                                const Color.fromARGB(255, 255, 255, 255),
                            inactiveTrackColor:
                                const Color.fromARGB(255, 121, 116, 116),
                            activeTrackColor: Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
