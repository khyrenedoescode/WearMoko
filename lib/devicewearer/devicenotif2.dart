import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeviceNotif2 extends StatefulWidget {
  const DeviceNotif2({super.key});

  @override
  _DeviceNotif2State createState() => _DeviceNotif2State();
}

class _DeviceNotif2State extends State<DeviceNotif2> {
  bool isSwitched = false; // Master switch for all monitoring users
  String? _profileImageUrl;
  String firstName = '';
  String circleCode = '';
  List<Map<String, dynamic>> circleMembers = [];
  List<bool> memberSwitchStates = [];
  List<String> memberUids = [];

  @override
  void initState() {
    super.initState();
    _listenDeviceWearer();
  }

  void _listenDeviceWearer() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          firstName = data['firstName'] ?? 'User';
          _profileImageUrl = data['profileImage'];
          isSwitched = data['notificationEnabled'] ?? false;
          circleCode = data['circleCode'] ?? '';
        });

        if (circleCode.isNotEmpty) {
          _fetchCircleMembers(circleCode);
        }
      }
    });
  }

  Future<void> _fetchCircleMembers(String code) async {
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
        final data = doc.data();
        members.add({
          'firstName': data['firstName'] ?? 'User',
          'profileImage': data['profileImage'],
        });
        switches.add(data['notificationEnabled'] ?? true); // default true
        uids.add(doc.id);
      }

      if (mounted) {
        setState(() {
          circleMembers = members;
          memberSwitchStates = switches;
          memberUids = uids;
        });
      }
    } catch (e) {
      print('Error fetching circle members: $e');
    }
  }

  Future<void> _updateNotificationSettings(bool value) async {
    setState(() => isSwitched = value);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final batch = FirebaseFirestore.instance.batch();

      // Update device wearer
      batch.update(FirebaseFirestore.instance.collection('users').doc(user.uid),
          {'notificationEnabled': value});

      // Only turn off members if master switch is turned OFF
      if (!value) {
        for (int i = 0; i < memberUids.length; i++) {
          batch.update(
              FirebaseFirestore.instance.collection('users').doc(memberUids[i]),
              {'notificationEnabled': false});
        }
      }

      await batch.commit();

      // Update local UI
      if (!value) {
        setState(() {
          memberSwitchStates =
              List<bool>.filled(memberSwitchStates.length, false);
        });
      }
    } catch (e) {
      print('Error updating notifications: $e');
      if (mounted) setState(() => isSwitched = !value);
    }
  }

  Future<void> _updateMemberNotification(int index, bool value) async {
    final uid = memberUids[index];
    setState(() => memberSwitchStates[index] = value);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'notificationEnabled': value});

      // Remove automatic master switch update
      // Master switch only changes when user toggles it
    } catch (e) {
      print('Error updating individual member notification: $e');
      if (mounted) setState(() => memberSwitchStates[index] = !value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD498),
        elevation: 1,
        shadowColor: const Color(0xFFA5A5A5),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.only(left: 20),
            child: Image.asset('assets/back.png', fit: BoxFit.contain),
          ),
        ),
        title: Text(
          'Notification Management',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900, fontSize: 22, color: Colors.black),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Device Notification'),
          _buildSettingsTile(
            iconAsset: _profileImageUrl ?? 'assets/userdash.png',
            title: firstName.isEmpty ? 'User' : firstName,
            switchValue: isSwitched,
            onSwitchChanged: _updateNotificationSettings,
            isProfileTile: true,
          ),
          _buildSectionHeader('Circle Members Notifications'),
          Expanded(
            child: circleMembers.isEmpty
                ? Center(
                    child: Text("No circle members found.",
                        style: GoogleFonts.poppins()),
                  )
                : ListView.builder(
                    itemCount: circleMembers.length,
                    itemBuilder: (context, index) {
                      final member = circleMembers[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 26.0, vertical: 8.0),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: member['profileImage'] != null
                              ? NetworkImage(member['profileImage'])
                              : const AssetImage('assets/userdash.png')
                                  as ImageProvider,
                        ),
                        title: Text(
                          member['firstName'],
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        trailing: Switch(
                          value: memberSwitchStates[index],
                          onChanged: (val) =>
                              _updateMemberNotification(index, val),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey,
                          activeTrackColor: Colors.black,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(27, 20, 27, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEBE9E9), width: 1),
          top: BorderSide(color: Color(0xFFEBE9E9), width: 1),
        ),
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: const Color(0xFF5B5B5B)),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String iconAsset,
    required String title,
    bool? switchValue,
    Function(bool)? onSwitchChanged,
    bool isProfileTile = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 27, vertical: 8),
      leading: isProfileTile
          ? CircleAvatar(
              radius: 25,
              backgroundImage: iconAsset.startsWith('http')
                  ? NetworkImage(iconAsset) as ImageProvider
                  : AssetImage(iconAsset),
            )
          : Image.asset(iconAsset, width: 20, height: 20, fit: BoxFit.contain),
      title: Text(title,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w400,
              fontSize: 18,
              color: const Color(0xFF1A1A1A))),
      trailing: switchValue != null
          ? Switch(
              value: switchValue,
              onChanged: onSwitchChanged,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey,
              activeTrackColor: Colors.black,
            )
          : null,
    );
  }
}
