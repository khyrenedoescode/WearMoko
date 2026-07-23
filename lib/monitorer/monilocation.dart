import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:wearmokoapp/monitorer/monihome.dart';
import 'package:wearmokoapp/monitorer/moniprofile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class MoniLoc extends StatefulWidget {
  const MoniLoc({super.key});

  @override
  _MoniLocState createState() => _MoniLocState();
}

class _MoniLocState extends State<MoniLoc> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  ValueNotifier<LatLng?> currentLocationNotifier = ValueNotifier(null);
  StreamSubscription<DatabaseEvent>? _gpsSubscription;

  bool _isAllowed = false;
  bool _checkedPermission = false;
  bool _isSatelliteView = false;
  LatLng? _currentLocation;
  bool _isMapReady = false;

  // ✅ NEW: Animation improvements
  AnimationController? _animationController;
  Animation<double>? _latTween;
  Animation<double>? _lngTween;

  // ✅ NEW: Queue system for smooth continuous movement
  final List<LatLng> _locationQueue = [];
  bool _isAnimating = false;

  final String streetMapStyleUrl =
      "";
  final String satelliteMapStyleUrl =
      "";

  void _toggleMapStyle() {
    setState(() {
      _isSatelliteView = !_isSatelliteView;
    });
  }

  // Display location on map from Realtime Database
  void _startLocationDisplay() {
    final dbRef = FirebaseDatabase.instance.ref('GPSLocation');

    _gpsSubscription = dbRef.onValue.listen((DatabaseEvent event) async {
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      double? lat;
      double? lng;

      // Try to get current location first
      if (data['latitude'] != null && data['longitude'] != null) {
        lat = double.tryParse(data['latitude'].toString());
        lng = double.tryParse(data['longitude'].toString());
      }
      // Fallback to last known location
      else if (data['lastKnown'] != null) {
        final last = data['lastKnown'] as Map;
        lat = double.tryParse(last['latitude'].toString());
        lng = double.tryParse(last['longitude'].toString());
      }

      if (lat == null || lng == null) return;

      final newLocation = LatLng(lat, lng);

      // First time receiving location - center map
      if (_currentLocation == null) {
        if (!mounted) return;
        _currentLocation = newLocation;
        currentLocationNotifier.value = newLocation;

        if (_isMapReady) {
          _mapController.move(newLocation, 17.0);
        }
      }
      // Location changed - add to queue for smooth animation
      else if ((_currentLocation!.latitude - newLocation.latitude).abs() >
              0.000001 ||
          (_currentLocation!.longitude - newLocation.longitude).abs() >
              0.000001) {
        // ✅ Add new location to queue
        _locationQueue.add(newLocation);

        // ✅ Process queue if not already animating
        if (!_isAnimating) {
          _processLocationQueue();
        }
      }
    });
  }

  // ✅ NEW: Process location queue for continuous smooth movement
  Future<void> _processLocationQueue() async {
    if (_locationQueue.isEmpty || !_isMapReady) return;

    _isAnimating = true;

    while (_locationQueue.isNotEmpty && mounted) {
      final nextLocation = _locationQueue.removeAt(0);

      // Animate to next location
      await _animateMarkerSmooth(_currentLocation!, nextLocation);

      // Small delay between animations for smoother transition
      await Future.delayed(const Duration(milliseconds: 50));
    }

    _isAnimating = false;
  }

  // ✅ IMPROVED: Smooth animation with better interpolation
  Future<void> _animateMarkerSmooth(LatLng from, LatLng to) async {
    // Don't animate if change is too small
    if ((from.latitude - to.latitude).abs() < 0.00001 &&
        (from.longitude - to.longitude).abs() < 0.00001) {
      _currentLocation = to;
      currentLocationNotifier.value = to;
      return;
    }

    // Don't animate if map not ready
    if (!_isMapReady) {
      _currentLocation = to;
      currentLocationNotifier.value = to;
      return;
    }

    // Calculate distance to adjust animation duration
    final distance = _calculateDistance(from, to);

    // ✅ Dynamic duration based on distance (longer for larger distances)
    int durationMs = 800; // Default 800ms
    if (distance > 0.0001) {
      durationMs = 1200; // Slower for long distances
    } else if (distance < 0.00005) {
      durationMs = 500; // Faster for very short distances
    }

    // Initialize or reset animation controller
    if (_animationController != null) {
      _animationController!.stop();
      _animationController!.dispose();
    }

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );

    // ✅ Use easeInOutCubic for smoother, more natural movement
    final curved = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOutCubic, // More natural than easeInOut
    );

    _latTween = Tween<double>(
      begin: from.latitude,
      end: to.latitude,
    ).animate(curved);

    _lngTween = Tween<double>(
      begin: from.longitude,
      end: to.longitude,
    ).animate(curved);

    // ✅ Create completer to await animation completion
    final completer = Completer<void>();

    _animationController!
      ..removeListener(_onAnimateSmooth)
      ..addListener(_onAnimateSmooth);

    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _currentLocation = to;
        currentLocationNotifier.value = to;
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    _animationController!.forward();

    // Wait for animation to complete
    await completer.future;
  }

  // ✅ NEW: Calculate distance between two points
  double _calculateDistance(LatLng from, LatLng to) {
    final latDiff = (from.latitude - to.latitude).abs();
    final lngDiff = (from.longitude - to.longitude).abs();
    return latDiff + lngDiff;
  }

  // ✅ IMPROVED: Smoother map movement during animation
  void _onAnimateSmooth() {
    if (_latTween == null || _lngTween == null || !_isMapReady) return;

    final interpolated = LatLng(_latTween!.value, _lngTween!.value);
    currentLocationNotifier.value = interpolated;

    try {
      // ✅ Keep the map centered on the moving marker
      final currentZoom = _mapController.camera.zoom;
      _mapController.move(interpolated, currentZoom);
    } catch (e) {
      // If move fails, skip this frame
      print('⚠️ Map move failed: $e');
    }
  }

  Future<void> _checkPermission() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) setState(() => _checkedPermission = true);
      return;
    }

    final uid = currentUser.uid;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final data = doc.data();
      _isAllowed = data?['geolocationEnabled'] as bool? ?? false;
    } catch (e) {
      print('❌ Error checking permission: $e');
      _isAllowed = false;
    }

    if (mounted) setState(() => _checkedPermission = true);

    // Start displaying location if allowed
    if (_isAllowed) {
      print('✅ Geolocation enabled - starting location display');
      _startLocationDisplay();
    } else {
      print('⛔ Geolocation disabled');
    }
  }

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    _animationController?.dispose();
    currentLocationNotifier.dispose();
    _locationQueue.clear();
    super.dispose();
  }

  Widget _buildFlutterMap() {
    return ValueListenableBuilder<LatLng?>(
      valueListenable: currentLocationNotifier,
      builder: (context, currentLocation, _) {
        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: currentLocation ?? const LatLng(7.0650, 125.6080),
            initialZoom: currentLocation != null ? 17.0 : 10.0,
            onMapReady: () {
              setState(() {
                _isMapReady = true;
              });
              print('✅ Map is ready');

              // Move to current location if we have it
              if (_currentLocation != null) {
                _mapController.move(_currentLocation!, 17.0);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  _isSatelliteView ? satelliteMapStyleUrl : streetMapStyleUrl,
              additionalOptions: const {},
            ),
            if (currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentLocation,
                    width: 45,
                    height: 45,
                    // ✅ Rotate marker based on direction of movement
                    child: Image.asset('assets/pin.png', width: 45, height: 45),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4B315),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Location',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
      ),
      body: !_checkedPermission
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                _isAllowed
                    ? _buildFlutterMap()
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'Geolocation is disabled. Enable it in your profile to view the device location.',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                if (_isAllowed)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: GestureDetector(
                      onTap: _toggleMapStyle,
                      child: Container(
                        width: 50,
                        height: 50,
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
                    iconAsset: 'assets/home.png',
                    label: 'Home',
                    targetPage: const MoniHome(),
                    isCurrentPage: false,
                  ),
                  _buildBottomNavItem(
                    context,
                    iconAsset: 'assets/location2.png',
                    label: 'Location',
                    targetPage: const MoniLoc(),
                    isCurrentPage: true,
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
    );
  }

  Widget _buildBottomNavItem(
    BuildContext context, {
    required String iconAsset,
    required String label,
    required Widget targetPage,
    required bool isCurrentPage,
  }) {
    return GestureDetector(
      onTap: () {
        if (isCurrentPage) return;
        Navigator.pushReplacement(
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
}
