import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeviceEmergencyContact extends StatefulWidget {
  const DeviceEmergencyContact({super.key});

  @override
  State<DeviceEmergencyContact> createState() => _DeviceEmergencyContactState();
}

class _DeviceEmergencyContactState extends State<DeviceEmergencyContact> {
  String userName = '';
  String circleCode = '';
  String? selectedContactId;
  List<Map<String, String>> circleMembersData = [];
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
        if (mounted) {
          setState(() {
            userName = 'No user logged in';
            isLoading = false;
          });
        }
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        String firstName = data?['firstName'] ?? 'Unknown';
        String lastName = data?['lastName'] ?? 'User';
        circleCode = data?['circleCode'] ?? '';
        selectedContactId = data?['selectedEmergencyContactId'];

        if (mounted) {
          setState(() {
            userName = '$firstName $lastName';
          });
        }

        await _fetchCircleMembers();
      } else {
        if (mounted) {
          setState(() {
            userName = 'User document not found';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error in _fetchUserData: $e');
      if (mounted) {
        setState(() {
          userName = 'Error fetching user data: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchCircleMembers() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        if (mounted) {
          setState(() {
            circleMembersData = [];
            isLoading = false;
          });
        }
        return;
      }

      final userData = userDoc.data();
      String? myRole = userData?['role'];

      // DEBUGGING: Print to console
      print('My Role: $myRole');

      // Only Device Wearers can select emergency contacts
      if (myRole != 'Device Wearer') {
        print('Not a Device Wearer - cannot select emergency contacts');
        if (mounted) {
          setState(() {
            circleMembersData = [];
            isLoading = false;
          });
        }
        return;
      }

      // Get the circle code from Device Wearer's circleCode field
      String myCircleCode = userData?['circleCode'] ?? '';

      print('My Circle Code: $myCircleCode');

      if (myCircleCode.isEmpty) {
        print('Circle code is empty');
        if (mounted) {
          setState(() {
            circleMembersData = [];
            isLoading = false;
          });
        }
        return;
      }

      // Only fetch Monitoring Users who joined this circle (joinedCircleCode field)
      final joinedSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('joinedCircleCode', isEqualTo: myCircleCode)
          .get();

      print(
          'Monitoring Users with joinedCircleCode: ${joinedSnapshot.docs.length}');
      for (var doc in joinedSnapshot.docs) {
        print('  - Found user: ${doc.id} (${doc.data()['firstName']})');
      }

      List<Map<String, String>> members = [];
      for (var doc in joinedSnapshot.docs) {
        final data = doc.data();
        String firstName = data['firstName'] ?? 'Unknown';
        String lastName = data['lastName'] ?? 'User';
        String uid = doc.id;

        print('Adding member: $firstName $lastName ($uid)');
        members.add({'name': '$firstName $lastName', 'uid': uid});
      }

      print('Final members list size: ${members.length}');

      if (mounted) {
        setState(() {
          circleMembersData = members;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _fetchCircleMembers: $e');
      if (mounted) {
        setState(() {
          circleMembersData = [];
          isLoading = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error fetching members: $e', style: GoogleFonts.poppins()),
        ),
      );
    }
  }

  Future<void> _setEmergencyContact(
      String? contactId, String contactName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'selectedEmergencyContactId': contactId});

      if (mounted) {
        setState(() {
          selectedContactId = contactId;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              contactId == null
                  ? 'Emergency contact removed'
                  : 'Emergency contact set to $contactName',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error setting emergency contact: $e',
                  style: GoogleFonts.poppins())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4B315),
        elevation: 1,
        shadowColor: const Color(0xFFA5A5A5),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: Image.asset('assets/back.png', fit: BoxFit.contain),
          ),
        ),
        title: Text(
          'Emergency Contacts',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : circleMembersData.isEmpty
              ? Center(
                  child: Text(
                    'No emergency contacts available in your Circle.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  itemCount: circleMembersData.length,
                  itemBuilder: (context, index) {
                    final member = circleMembersData[index];
                    final isSelected = member['uid'] == selectedContactId;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: Icon(Icons.person,
                            color: isSelected ? Colors.green : Colors.black),
                        title: Text(
                          member['name'] ?? 'Unknown',
                          style: GoogleFonts.poppins(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16,
                            color: isSelected ? Colors.green : Colors.black,
                          ),
                        ),
                        trailing: isSelected
                            ? IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  _setEmergencyContact(null, '');
                                },
                              )
                            : null,
                        onTap: () {
                          _setEmergencyContact(member['uid']!, member['name']!);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
