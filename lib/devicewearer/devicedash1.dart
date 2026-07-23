import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wearmokoapp/devicewearer/deviceadminstatus.dart';
import 'package:wearmokoapp/devicewearer/deviceprofile.dart';
import 'package:wearmokoapp/devicewearer/devicealert.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wearmokoapp/devicewearer/verifycodedevice.dart';
import 'package:auto_size_text/auto_size_text.dart';

class DeviceDash extends StatefulWidget {
  const DeviceDash({super.key});

  @override
  State<DeviceDash> createState() => _DeviceDashState();
}

class _DeviceDashState extends State<DeviceDash>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  String firstName = '';
  String circleCode = '';
  List<String> circleMembers = [];
  String? _profileImageUrl;
  String deviceCode = '';
  bool _isSatellite = false;

  // Real-time GPS Location
  ValueNotifier<LatLng?> currentLocationNotifier = ValueNotifier(null);
  StreamSubscription<DatabaseEvent>? _gpsSubscription;
  LatLng? _currentLocation;

  // Animation controller for smooth marker movement
  AnimationController? _animationController;
  Animation<double>? _latTween;
  Animation<double>? _lngTween;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    _animationController?.dispose();
    currentLocationNotifier.dispose();
    super.dispose();
  }

  void _toggleMapStyle() {
    setState(() {
      _isSatellite = !_isSatellite;
    });
  }

  // EXIT POPUP
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

  // Real-time GPS listening
  void _startLocationDisplay() {
    final dbRef = FirebaseDatabase.instance.ref('GPSLocation');

    _gpsSubscription = dbRef.onValue.listen((DatabaseEvent event) async {
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      double? lat;
      double? lng;

      if (data['latitude'] != null && data['longitude'] != null) {
        lat = double.tryParse(data['latitude'].toString());
        lng = double.tryParse(data['longitude'].toString());
      } else if (data['lastKnown'] != null) {
        final last = data['lastKnown'] as Map;
        lat = double.tryParse(last['latitude'].toString());
        lng = double.tryParse(last['longitude'].toString());
      }

      if (lat == null || lng == null) return;

      final newLocation = LatLng(lat, lng);

      // Update map display with animation
      if (_currentLocation == null) {
        if (!mounted) return;
        _currentLocation = newLocation;
        currentLocationNotifier.value = newLocation;
        _mapController.move(newLocation, 17.0);
      } else if ((_currentLocation!.latitude - newLocation.latitude).abs() >
              0.000001 ||
          (_currentLocation!.longitude - newLocation.longitude).abs() >
              0.000001) {
        _animateMarker(_currentLocation!, newLocation);
      }
    });
  }

  // Smooth marker animation
  void _animateMarker(LatLng from, LatLng to) {
    if ((from.latitude - to.latitude).abs() < 0.00001 &&
        (from.longitude - to.longitude).abs() < 0.00001) return;

    if (_animationController != null) {
      _animationController!.stop();
      _animationController!.reset();
    } else {
      _animationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
    }

    final curved =
        CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut);
    _latTween =
        Tween<double>(begin: from.latitude, end: to.latitude).animate(curved);
    _lngTween =
        Tween<double>(begin: from.longitude, end: to.longitude).animate(curved);

    _animationController!
      ..removeListener(_onAnimate)
      ..addListener(_onAnimate);

    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _currentLocation = to;
        currentLocationNotifier.value = to;
      }
    });

    _animationController!.forward();
  }

  // Animation listener
  void _onAnimate() {
    if (_latTween == null || _lngTween == null) return;
    final interpolated = LatLng(_latTween!.value, _lngTween!.value);
    currentLocationNotifier.value = interpolated;
    try {
      _mapController.move(interpolated, _mapController.camera.zoom);
    } catch (_) {
      _mapController.move(interpolated, 17.0);
    }
  }

  Future<void> _loadDashboardData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        firstName = 'User';
        circleMembers = ['Not logged in'];
      });
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && mounted) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          firstName = data['firstName'] ?? 'User';
          _profileImageUrl = data['profileImage'];
          deviceCode = data['deviceCode'] ?? '';
          circleCode = data['circleCode'] ?? '';
        });

        // Start real-time GPS display
        _startLocationDisplay();

        if (circleCode.isNotEmpty) {
          _fetchCircleMembers();
        } else if (mounted) {
          setState(() => circleMembers = ['No circle joined']);
        }
      } else if (mounted) {
        setState(() {
          firstName = 'User';
          circleMembers = ['Data error'];
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      if (mounted) {
        setState(() {
          firstName = 'User';
          circleMembers = ['Load error'];
        });
      }
    }
  }

  Future<void> _fetchCircleMembers() async {
    if (circleCode.isEmpty) {
      if (mounted) setState(() => circleMembers = ['No circle code']);
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('joinedCircleCode', isEqualTo: circleCode)
          .where('role', isEqualTo: 'Monitoring User')
          .get();

      List<String> members = [];
      for (var doc in querySnapshot.docs) {
        String fName = doc['firstName'] ?? 'Unknown';
        String lName = doc['lastName'] ?? 'User';
        members.add('$fName $lName');
      }

      if (members.isNotEmpty && mounted) {
        final random = Random();
        setState(
            () => circleMembers = [members[random.nextInt(members.length)]]);
      } else if (mounted) {
        setState(() => circleMembers = ['No members found']);
      }
    } catch (e) {
      print("Error fetching circle members: $e");
      if (mounted) setState(() => circleMembers = ['Error fetching members']);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 12) return 'GOOD MORNING,';
    if (hour >= 12 && hour < 18) return 'GOOD AFTERNOON,';
    return 'GOOD EVENING,';
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
          toolbarHeight: 110,
          automaticallyImplyLeading: false,
          title: Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 8.0),
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
                )
              ],
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              children: [
                _buildMapCard(context),
                const SizedBox(height: 20),
                _buildDistanceCard(context),
                const SizedBox(height: 20),
                _buildAddDeviceCard(context),
                const SizedBox(height: 30),
              ],
            ),
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
                      targetPage: const DeviceDash(),
                      isCurrentPage: true,
                    ),
                    _buildBottomNavItem(
                      context,
                      iconAsset: 'assets/alert2.png',
                      label: 'Alert',
                      targetPage: const DeviceAlert(),
                      isCurrentPage: false,
                    ),
                    _buildBottomNavItem(
                      context,
                      iconAsset: 'assets/user2.png',
                      label: 'Profile',
                      targetPage: const DeviceProfile(),
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
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => targetPage,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) => child,
            transitionDuration: Duration.zero,
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(iconAsset, width: 30, height: 30, fit: BoxFit.contain),
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

  // 🆕 FIXED: Real-time animated map with toggle button
  Widget _buildMapCard(BuildContext context) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: ValueListenableBuilder<LatLng?>(
              valueListenable: currentLocationNotifier,
              builder: (context, currentLocation, _) {
                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        currentLocation ?? const LatLng(7.0650, 125.6080),
                    initialZoom: currentLocation != null ? 17.0 : 10.0,
                    minZoom: 2.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _isSatellite
                          ? ""
                          : "",
                      additionalOptions: const {},
                    ),
                    if (currentLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: currentLocation,
                            width: 45,
                            height: 45,
                            child: Image.asset(
                              'assets/pin.png',
                              width: 45,
                              height: 45,
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
          // 🆕 Toggle map view button
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: _toggleMapStyle,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                  image: DecorationImage(
                    image: AssetImage('assets/changeview.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Now reads totalDistance field directly from Device Wearer document
  Widget _buildDistanceCard(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid) // Device Wearer's own document
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 100, child: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data()!;

        // ✅ Read totalDistance field directly
        double totalDistanceValue = 0.0;
        if (data.containsKey('totalDistance')) {
          totalDistanceValue = (data['totalDistance'] is num)
              ? (data['totalDistance'] as num).toDouble()
              : 0.0;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
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
              crossAxisAlignment: CrossAxisAlignment.end,
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
                              child: Text(
                                totalDistanceValue.toStringAsFixed(2),
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
  }

  Widget _buildAddDeviceCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFBBB4B4), width: 1),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: const BoxDecoration(
              color: Color(0xFFFFD498),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Center(
              child: Text(
                'Add Device & People',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: deviceCode.isEmpty
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserDevice()),
                    )
                : null,
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: Row(
                children: [
                  Image.asset('assets/necklace.png', width: 40, height: 40),
                  const SizedBox(width: 20),
                  Text(
                    deviceCode.isEmpty
                        ? 'Add a Device'
                        : 'Device Code: $deviceCode',
                    style: GoogleFonts.poppins(
                      fontWeight: deviceCode.isEmpty
                          ? FontWeight.w400
                          : FontWeight.w700,
                      fontSize: deviceCode.isEmpty ? 15 : 20,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: Divider(
              color: Color.fromRGBO(214, 214, 214, 0.5),
              height: 1,
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'People',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w400,
                        fontSize: 20,
                        color: const Color(0xFF2D2D2D),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const DeviceAdmin(),
                          transitionsBuilder: (_, __, ___, child) => child,
                        ),
                      ),
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
                const SizedBox(height: 15),
                Text(
                  circleMembers.isNotEmpty ? circleMembers[0] : 'Loading...',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 25,
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
}
