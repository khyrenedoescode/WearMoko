import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:wearmokoapp/monitorer/monilocation.dart';
import 'package:wearmokoapp/monitorer/moninotifications.dart';
import 'package:wearmokoapp/monitorer/moniprofile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MoniHome extends StatefulWidget {
  const MoniHome({super.key});

  @override
  MoniHomeState createState() => MoniHomeState();
}

class MoniHomeState extends State<MoniHome> {
  String firstName = '';
  String? _profileImageUrl;

  String get _currentUserUid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _getUserName();
  }

  // Format timestamp
  String formatGeoTime(Timestamp? ts) {
    if (ts == null) return "Unknown time";
    final date = ts.toDate();
    return DateFormat('h:mm a').format(date); // e.g., 3:45 PM
  }

  // Fetch user's first name and profile image
  Future<void> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              firstName = data['firstName'] ?? 'User';
              _profileImageUrl = data['profileImage'];
            });
          }
        }
      } catch (e) {
        if (mounted) setState(() => firstName = 'User');
      }
    } else {
      if (mounted) setState(() => firstName = 'User');
    }
  }

  // Dynamic greeting
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 12) return 'GOOD MORNING,';
    if (hour >= 12 && hour < 18) return 'GOOD AFTERNOON,';
    return 'GOOD EVENING,';
  }

  // Exit popup
  Future<bool> _onWillPop() async {
    if (!mounted) return false;

    bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Exit App?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    color: const Color(0xFF650000),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Do you really want to close the application?',
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
                        onPressed: () => Navigator.of(context).pop(false),
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
                        onPressed: () => Navigator.of(context).pop(true),
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
      },
    );

    return shouldExit ?? false;
  }

  // Toggle geolocation switch
  Future<void> _updateGeoSwitch(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'geolocationOn': value,
        'lastGeoOnTime': value ? FieldValue.serverTimestamp() : null,
        'totalDistance': value ? 0.0 : 0.0, // reset distance when OFF
      });
    } catch (e) {
      print('Error updating geolocation: $e');
    }
  }

  // User document stream for real-time updates
  Stream<DocumentSnapshot<Map<String, dynamic>>> get _userStream {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 120,
          automaticallyImplyLeading: false,
          title: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : const AssetImage('assets/userdash.png')
                              as ImageProvider,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getGreeting(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AutoSizeText(
                        firstName.isEmpty ? '' : firstName,
                        maxLines: 1,
                        minFontSize: 40,
                        maxFontSize: 40,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEAA647),
                          height: 1.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0, top: 10.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const Moninotif(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) =>
                              child,
                      transitionDuration: Duration.zero,
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/notif.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildMapCard(context),
              _buildDistanceCard(context),
              _buildLastLocationCard(context),
              const SizedBox(height: 30),
            ],
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 1.5, color: const Color(0xFFBBB4B4)),
            BottomAppBar(
              color: Colors.white,
              elevation: 8,
              child: SizedBox(
                height: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBottomNavItem(
                      context,
                      iconAsset: 'assets/home2.png',
                      label: 'Home',
                      targetPage: const MoniHome(),
                      isCurrentPage: true,
                    ),
                    _buildBottomNavItem(
                      context,
                      iconAsset: 'assets/location3.png',
                      label: 'Location',
                      targetPage: const MoniLoc(),
                      isCurrentPage: false,
                    ),
                    _buildBottomNavItem(
                      context,
                      iconAsset: 'assets/user2.png',
                      label: 'Profile',
                      targetPage: const Moniprof(),
                      isCurrentPage: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(BuildContext context,
      {required String iconAsset,
      required String label,
      required Widget targetPage,
      required bool isCurrentPage}) {
    return GestureDetector(
      onTap: () {
        if (isCurrentPage) return;
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => targetPage,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return child;
            },
            transitionDuration: Duration.zero,
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconAsset,
            width: 30,
            height: 30,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isCurrentPage ? const Color(0xFF543509) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------
  // MAP CARD (REAL-TIME)
  // ----------------------
  Widget _buildMapCard(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data()!;
        final bool isGeoEnabled = data['geolocationEnabled'] ?? false;
        final Timestamp? lastTime = data['lastGeoOnTime'];

        String message;
        if (isGeoEnabled) {
          final timeStr =
              lastTime != null ? formatGeoTime(lastTime) : "Unknown time";
          message = "Geolocation is ON since $timeStr";
        } else {
          message = "Geolocation is OFF";
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Container(
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              border: Border.all(color: const Color(0xFFD9D9D9), width: 0.5),
              boxShadow: const [
                BoxShadow(
                  offset: Offset(0, 1),
                  blurRadius: 4,
                  color: Color.fromRGBO(12, 12, 13, 0.1),
                ),
              ],
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              image: const DecorationImage(
                image: AssetImage('assets/map2.png'),
                fit: BoxFit.cover,
                opacity: 0.5,
              ),
            ),
            child: Center(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: const Color(0xFF000000),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ----------------------
  // DISTANCE CARD (REAL-TIME) - Fixed to read totalDistance from Device Wearer
  // ----------------------
  Widget _buildDistanceCard(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = userSnapshot.data!.data()!;
        final bool isGeoEnabled = userData['geolocationEnabled'] ?? false;
        final joinedCircleCode = userData['joinedCircleCode'] as String?;

        if (!isGeoEnabled ||
            joinedCircleCode == null ||
            joinedCircleCode.isEmpty) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(234, 166, 71, 0.7),
                borderRadius: BorderRadius.circular(10),
                image: const DecorationImage(
                  image: AssetImage('assets/locationbar.png'),
                  fit: BoxFit.cover,
                  opacity: 0.3,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Distance',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '0.0',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 45,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'KM',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Find Device Wearer and get their totalDistance field directly
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'Device Wearer')
              .where('circleCode', isEqualTo: joinedCircleCode)
              .limit(1)
              .snapshots(),
          builder: (context, deviceWearerSnapshot) {
            double totalDistance = 0.0;

            if (deviceWearerSnapshot.hasData &&
                deviceWearerSnapshot.data!.docs.isNotEmpty) {
              final deviceWearerData = deviceWearerSnapshot.data!.docs.first
                  .data() as Map<String, dynamic>;

              // Read totalDistance field directly from Device Wearer document
              totalDistance = (deviceWearerData['totalDistance'] ?? 0.0) is num
                  ? (deviceWearerData['totalDistance'] ?? 0.0).toDouble()
                  : 0.0;
            }

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(234, 166, 71, 0.7),
                  borderRadius: BorderRadius.circular(10),
                  image: const DecorationImage(
                    image: AssetImage('assets/locationbar.png'),
                    fit: BoxFit.cover,
                    opacity: 0.3,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Total Distance',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    totalDistance.toStringAsFixed(2),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 45,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'KM',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ----------------------
  // 🆕 FIXED: Now reads from Device Wearer's lastLocations
  // ----------------------
  // Replace your _buildLastLocationCard method in MoniHome with this:

  Widget _buildLastLocationCard(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = userSnapshot.data!.data();
        if (userData == null) return _buildEmptyLastLocationCard();

        final joinedCircleCode = userData['joinedCircleCode'] as String?;
        final bool isGeoEnabled = userData['geolocationEnabled'] ?? false;

        if (joinedCircleCode == null || joinedCircleCode.isEmpty) {
          return _buildEmptyLastLocationCard(isGeoEnabled: isGeoEnabled);
        }

        // 🆕 Find Device Wearer and listen to their lastLocations
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'Device Wearer')
              .where('circleCode', isEqualTo: joinedCircleCode)
              .limit(1)
              .snapshots(),
          builder: (context, deviceWearerSnapshot) {
            if (!deviceWearerSnapshot.hasData ||
                deviceWearerSnapshot.data!.docs.isEmpty) {
              return _buildEmptyLastLocationCard(isGeoEnabled: isGeoEnabled);
            }

            final deviceWearerData = deviceWearerSnapshot.data!.docs.first
                .data() as Map<String, dynamic>;

            final lastLocations =
                deviceWearerData['lastLocations'] as Map<String, dynamic>?;

            if (lastLocations == null || lastLocations.isEmpty) {
              return _buildEmptyLastLocationCard(isGeoEnabled: isGeoEnabled);
            }

            // 🆕 Filter only valid Map entries
            final locationEntries = lastLocations.entries
                .where((e) => e.value is Map<String, dynamic>)
                .toList();

            if (locationEntries.isEmpty) {
              return _buildEmptyLastLocationCard(isGeoEnabled: isGeoEnabled);
            }

            // 🆕 Sort entries by timestamp descending (newest first)
            locationEntries.sort((a, b) {
              final mapA = a.value as Map<String, dynamic>;
              final mapB = b.value as Map<String, dynamic>;
              final t1 = mapA['timestamp'] is Timestamp
                  ? (mapA['timestamp'] as Timestamp).toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);
              final t2 = mapB['timestamp'] is Timestamp
                  ? (mapB['timestamp'] as Timestamp).toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);
              return t2.compareTo(t1);
            });

            // 🆕 Take only 10 most recent entries
            final displayEntries = locationEntries.take(10).toList();

            print(
                '✅ [HOME] Showing ${displayEntries.length} most recent locations');

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🆕 Header with count
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Last Known Locations',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: const Color(0xFF2D2D2D),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const Moninotif(),
                                transitionDuration: Duration.zero,
                                transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) =>
                                    child,
                              ),
                            );
                          },
                          child: Text(
                            'See all',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: const Color(0xFF2D2D2D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 🆕 List of locations
                  SizedBox(
                    height: 400,
                    child: ListView.builder(
                      itemCount: displayEntries.length,
                      itemBuilder: (context, index) {
                        final locationData =
                            displayEntries[index].value is Map<String, dynamic>
                                ? displayEntries[index].value
                                    as Map<String, dynamic>
                                : {};

                        final locationLandmark =
                            locationData['landmark'] ?? "Unknown";

                        // 🆕 Get distance as double (incremental distance for this move)
                        double locationDistance = 0.0;
                        if (locationData['distance'] != null) {
                          if (locationData['distance'] is num) {
                            locationDistance =
                                (locationData['distance'] as num).toDouble();
                          } else if (locationData['distance'] is String) {
                            locationDistance =
                                double.tryParse(locationData['distance']) ??
                                    0.0;
                          }
                        }

                        final locationTimestamp =
                            locationData['timestamp'] is Timestamp
                                ? locationData['timestamp'] as Timestamp
                                : null;
                        final locationTimeStr = locationTimestamp != null
                            ? DateFormat('h:mm a')
                                .format(locationTimestamp.toDate())
                            : "Unknown time";

                        // 🆕 Get savedBy info for debugging
                        final savedBy = locationData['savedBy'] ?? 'Unknown';

                        // 🆕 Determine if "Still at" or "Last stop at"
                        String locationTitle = "Last stop at $locationLandmark";
                        if (index > 0) {
                          final prevLocationData = displayEntries[index - 1]
                                  .value is Map<String, dynamic>
                              ? displayEntries[index - 1].value
                                  as Map<String, dynamic>
                              : {};
                          if (prevLocationData['landmark'] ==
                              locationLandmark) {
                            locationTitle = "Still at $locationLandmark";
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      const Moninotif(),
                                  transitionDuration: Duration.zero,
                                  transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) =>
                                      child,
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(15.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: const Color(0xFFBBB4B4), width: 1),
                                boxShadow: const [
                                  BoxShadow(
                                    offset: Offset(0, 4),
                                    blurRadius: 4,
                                    spreadRadius: -1,
                                    color: Color.fromRGBO(12, 12, 13, 0.1),
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    locationTitle,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: const Color(0xFF2D2D2D),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // 🆕 Show accurate incremental distance
                                  Text(
                                    locationDistance > 0
                                        ? 'Moved: ${locationDistance.toStringAsFixed(2)} km | Time: $locationTimeStr'
                                        : 'Starting point | Time: $locationTimeStr',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w300,
                                      fontSize: 12,
                                      height: 1.2,
                                      color: Colors.black,
                                    ),
                                  ),
                                  // 🆕 Optional: Show who saved this (for debugging)
                                  if (savedBy != 'Unknown')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'Saved by: $savedBy',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: Colors.black38,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyLastLocationCard({bool isGeoEnabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFBBB4B4), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last Known Location',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
                if (isGeoEnabled)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const Moninotif(),
                          transitionDuration: Duration.zero,
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) =>
                                  child,
                        ),
                      );
                    },
                    child: Text(
                      'See all',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: const Color(0xFF2D2D2D),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              isGeoEnabled
                  ? 'No recent location available'
                  : 'Geolocation is OFF',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AutoResizeText extends StatelessWidget {
  final String text;
  final double maxSize;
  final double minSize;
  final TextStyle style;

  const AutoResizeText({
    super.key,
    required this.text,
    this.maxSize = 40,
    this.minSize = 20,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: style.copyWith(fontSize: maxSize),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
