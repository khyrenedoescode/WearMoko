import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

/// Global Location Tracking Service (Monitoring User)
/// ✅ Accumulates small distances instead of discarding them
/// ✅ Always updates _currentLocation for accurate tracking
/// ✅ Coordinates saves with Device Wearer using lastSavedTimestamp
/// ✅ Enhanced logging to verify which service is saving
class LocationTrackingService {
  static final LocationTrackingService _instance =
      LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  StreamSubscription<DatabaseEvent>? _gpsSubscription;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;
  Timer? _saveTimer;
  LatLng? _lastSavedLocation; // Last location we saved to Firestore
  LatLng? _currentLocation; // Current GPS reading
  bool _isTracking = false;
  String? _deviceWearerId;

  bool _isGeoEnabled = false;
  String? _cachedCircleCode;

  // 🆕 Accumulate small movements
  double _accumulatedDistanceMeters = 0.0;

  static const double _minDistanceThresholdMeters = 50.0;
  static const int _saveCoordinationWindowSeconds =
      10; // 10-second coordination window

  Future<void> startTracking() async {
    if (_isTracking) {
      print('⚠️ [MONITORING] Location tracking already running');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('❌ [MONITORING] No user logged in');
      return;
    }

    final uid = currentUser.uid;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    final role = userDoc.data()?['role'] as String?;
    _isGeoEnabled = userDoc.data()?['geolocationEnabled'] as bool? ?? false;

    if (role != 'Monitoring User') {
      print('⚠️ [MONITORING] User is not a Monitoring User');
      return;
    }

    if (!_isGeoEnabled) {
      print('⛔ [MONITORING] Geolocation is disabled');
      return;
    }

    final joinedCircleCode = userDoc.data()?['joinedCircleCode'] as String?;
    _cachedCircleCode = joinedCircleCode;

    if (joinedCircleCode == null || joinedCircleCode.isEmpty) {
      print('⚠️ [MONITORING] Monitoring User has not joined any circle');
      return;
    }

    await _findDeviceWearer(joinedCircleCode);

    if (_deviceWearerId == null) {
      print(
          '❌ [MONITORING] No Device Wearer found in circle: $joinedCircleCode');
      return;
    }

    // ✅ Set flag on Device Wearer to indicate Monitoring User is tracking
    await _setMonitoringActiveFlag(true);

    // ✅ Load the last saved location from Firestore
    await _loadLastSavedLocation();

    print('✅ [MONITORING] Found Device Wearer: $_deviceWearerId');
    print(
        '✅ [MONITORING] Starting global location tracking (Monitoring User: $uid)');

    _isTracking = true;
    _setupPermissionListener(uid);
    _startGPSTracking();
    _startPeriodicSaving();
  }

  Future<void> _loadLastSavedLocation() async {
    if (_deviceWearerId == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_deviceWearerId!)
          .get();

      if (!userDoc.exists) return;

      final data = userDoc.data();
      if (data == null || !data.containsKey('lastLocations')) return;

      final lastLocations = data['lastLocations'] as Map<String, dynamic>?;
      if (lastLocations == null || lastLocations.isEmpty) return;

      final entries = lastLocations.entries
          .where((e) => e.value is Map<String, dynamic>)
          .toList();

      entries.sort((a, b) {
        final t1 = (a.value['timestamp'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final t2 = (b.value['timestamp'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return t2.compareTo(t1);
      });

      if (entries.isNotEmpty) {
        final lastEntry = entries.first.value as Map<String, dynamic>;
        final lat = lastEntry['latitude'] as double?;
        final lng = lastEntry['longitude'] as double?;

        if (lat != null && lng != null) {
          _lastSavedLocation = LatLng(lat, lng);
          print('✅ [MONITORING] Loaded last saved location: $lat, $lng');
        }
      }
    } catch (e) {
      print('❌ [MONITORING] Error loading last saved location: $e');
    }
  }

  Future<void> _findDeviceWearer(String circleCode) async {
    try {
      final deviceWearerQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Device Wearer')
          .where('circleCode', isEqualTo: circleCode)
          .limit(1)
          .get();

      if (deviceWearerQuery.docs.isNotEmpty) {
        _deviceWearerId = deviceWearerQuery.docs.first.id;
      }
    } catch (e) {
      print('❌ [MONITORING] Error finding Device Wearer: $e');
    }
  }

  Future<void> _setMonitoringActiveFlag(bool isActive) async {
    if (_deviceWearerId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_deviceWearerId!)
          .update({
        'monitoringUserTracking': isActive,
      });
      print(
          '✅ [MONITORING] Set monitoringUserTracking=$isActive on Device Wearer');
    } catch (e) {
      print('❌ [MONITORING] Error setting monitoring flag: $e');
    }
  }

  void _setupPermissionListener(String uid) {
    _userDocSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;

      final newGeoEnabled = data['geolocationEnabled'] as bool? ?? false;
      final newCircleCode = data['joinedCircleCode'] as String?;

      if (_isGeoEnabled && !newGeoEnabled) {
        print('⛔ [MONITORING] Geolocation disabled - stopping tracking');
        stopTracking();
        return;
      }

      if (_cachedCircleCode != newCircleCode && newCircleCode != null) {
        print('🔄 [MONITORING] Circle changed - updating Device Wearer');
        _cachedCircleCode = newCircleCode;

        await _setMonitoringActiveFlag(false);
        await _findDeviceWearer(newCircleCode);

        if (_deviceWearerId == null) {
          print(
              '❌ [MONITORING] No Device Wearer in new circle - stopping tracking');
          stopTracking();
        } else {
          await _setMonitoringActiveFlag(true);
          await _loadLastSavedLocation();
          _accumulatedDistanceMeters = 0.0; // Reset accumulation for new device
        }
      }

      _isGeoEnabled = newGeoEnabled;
    });
  }

  // 🆕 IMPROVED: Always updates _currentLocation
  void _startGPSTracking() {
    final dbRef = FirebaseDatabase.instance.ref('GPSLocation');

    _gpsSubscription = dbRef.onValue.listen((DatabaseEvent event) async {
      try {
        if (!_isGeoEnabled) {
          print('⛔ [MONITORING] Geolocation OFF → Not updating location');
          return;
        }

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

        // 🆕 Check if GPS data actually changed
        if (_currentLocation != null) {
          const Distance distanceCalc = Distance();
          final movedMeters = distanceCalc(_currentLocation!, newLocation);

          if (movedMeters < 1.0) {
            // 🆕 FIXED: Always update current location, even if movement is small
            _currentLocation = newLocation;
            return;
          }
          print(
              '📍 [MONITORING] GPS updated: $lat, $lng (moved ${movedMeters.toStringAsFixed(1)}m)');
        } else {
          print('📍 [MONITORING] GPS initial reading: $lat, $lng');
        }

        // 🆕 Always update current location
        _currentLocation = newLocation;
      } catch (e) {
        print('❌ [MONITORING] Error reading GPS: $e');
      }
    });
  }

  void _startPeriodicSaving() {
    _saveTimer = Timer.periodic(const Duration(seconds: 90), (timer) async {
      if (!_isGeoEnabled || _currentLocation == null) {
        print('⏸️ [MONITORING] Skipping save - geolocation off or no GPS data');
        return;
      }

      await _saveCurrentLocation();
    });

    print('✅ [MONITORING] Started periodic saving (every 90 seconds)');
  }

  // 🆕 IMPROVED: Check last save timestamp for coordination
  Future<bool> _shouldSaveNow() async {
    if (_deviceWearerId == null) return false;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_deviceWearerId!)
          .get();

      if (!userDoc.exists) return true;

      final data = userDoc.data();
      if (data == null) return true;

      final lastSavedTimestamp = data['lastSavedTimestamp'] as Timestamp?;
      if (lastSavedTimestamp == null) return true;

      final lastSaveTime = lastSavedTimestamp.toDate();
      final now = DateTime.now();
      final secondsSinceLastSave = now.difference(lastSaveTime).inSeconds;

      if (secondsSinceLastSave < _saveCoordinationWindowSeconds) {
        print(
            '⏸️ [MONITORING] Another service saved ${secondsSinceLastSave}s ago - waiting');
        return false;
      }

      return true;
    } catch (e) {
      print('⚠️ [MONITORING] Error checking save coordination: $e');
      return true; // If check fails, allow save
    }
  }

  Future<void> _saveCurrentLocation() async {
    if (_currentLocation == null || _deviceWearerId == null) return;

    // 🆕 Check save coordination
    if (!await _shouldSaveNow()) {
      return;
    }

    try {
      const Distance distanceCalc = Distance();
      double movedKm = 0.0;

      // 🆕 IMPROVED: Accumulate small distances
      if (_lastSavedLocation != null) {
        final movedMeters =
            distanceCalc(_lastSavedLocation!, _currentLocation!);

        // 🆕 Add to accumulated distance
        _accumulatedDistanceMeters += movedMeters;

        print(
            '📏 [MONITORING] Accumulated distance: ${_accumulatedDistanceMeters.toStringAsFixed(1)}m (threshold: ${_minDistanceThresholdMeters}m)');

        if (_accumulatedDistanceMeters < _minDistanceThresholdMeters) {
          print('⏭️ [MONITORING] Below threshold - not saving yet');
          return;
        }

        movedKm = _accumulatedDistanceMeters / 1000.0;

        if (movedKm > 100) {
          print(
              '⚠️ [MONITORING] REJECTED unrealistic distance: ${movedKm.toStringAsFixed(2)} km - likely GPS error');
          _accumulatedDistanceMeters =
              0.0; // Reset to avoid carrying over error
          return;
        }

        // 🆕 Reset accumulated distance after successful threshold check
        _accumulatedDistanceMeters = 0.0;
      } else {
        print('📍 [MONITORING] First save of this session');
        movedKm = 0.0;
        _accumulatedDistanceMeters = 0.0;
      }

      String landmark = 'Unknown Location';
      try {
        final placemarks = await placemarkFromCoordinates(
            _currentLocation!.latitude, _currentLocation!.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[];
          if (p.name != null && p.name!.trim().isNotEmpty) {
            parts.add(p.name!.trim());
          }
          if (p.subLocality != null && p.subLocality!.trim().isNotEmpty) {
            parts.add(p.subLocality!.trim());
          }
          if (p.locality != null && p.locality!.trim().isNotEmpty) {
            parts.add(p.locality!.trim());
          }
          if (parts.isNotEmpty) {
            landmark = parts.join(', ');
          } else {
            final fallbackParts = <String>[];
            if (p.thoroughfare != null && p.thoroughfare!.trim().isNotEmpty) {
              fallbackParts.add(p.thoroughfare!.trim());
            }
            if (p.administrativeArea != null &&
                p.administrativeArea!.trim().isNotEmpty) {
              fallbackParts.add(p.administrativeArea!.trim());
            }
            if (fallbackParts.isNotEmpty) {
              landmark = fallbackParts.join(', ');
            }
          }
        }
      } catch (e) {
        print('❌ [MONITORING] Reverse geocoding error: $e');
      }

      await _saveLocationToFirestore(
        deviceWearerUid: _deviceWearerId!,
        location: _currentLocation!,
        movedKm: movedKm,
        landmark: landmark,
      );

      // ✅ Update last saved location for next calculation
      _lastSavedLocation = _currentLocation;

      print(
          '💾 [MONITORING] ✅ Location saved: $landmark (${movedKm.toStringAsFixed(2)} km)');
    } catch (e) {
      print('❌ [MONITORING] Error saving location: $e');
    }
  }

  Future<void> _saveLocationToFirestore({
    required String deviceWearerUid,
    required LatLng location,
    required double movedKm,
    required String landmark,
  }) async {
    try {
      final docRef =
          FirebaseFirestore.instance.collection('users').doc(deviceWearerUid);
      final userSnap = await docRef.get();

      Map<String, dynamic> existing = {};
      double currentTotalDistance = 0.0;

      if (userSnap.exists) {
        final data = userSnap.data()!;

        if (data.containsKey('totalDistance')) {
          currentTotalDistance = (data['totalDistance'] is num)
              ? (data['totalDistance'] as num).toDouble()
              : 0.0;
        }

        if (data.containsKey('lastLocations')) {
          existing = Map<String, dynamic>.from(data['lastLocations']);
        }
      }

      // Sort and keep only 10 most recent
      final entries = existing.entries
          .where((e) => e.value is Map<String, dynamic>)
          .toList();
      entries.sort((a, b) {
        final t1 = (a.value['timestamp'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final t2 = (b.value['timestamp'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return t1.compareTo(t2);
      });

      while (entries.length >= 10) {
        final oldest = entries.first.key;
        existing.remove(oldest);
        entries.removeAt(0);
        print('🗑️ [MONITORING] Deleted oldest location entry: $oldest');
      }

      final timestampKey = DateTime.now().millisecondsSinceEpoch.toString();
      final locationData = {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'distance': movedKm,
        'landmark': landmark,
        'timestamp': FieldValue.serverTimestamp(),
        'savedBy': 'MonitoringUser', // 🆕 Track who saved this
      };

      existing[timestampKey] = locationData;

      final newTotalDistance = currentTotalDistance + movedKm;

      // 🆕 Add lastSavedTimestamp for coordination
      await docRef.set({
        'lastLocations': existing,
        'totalDistance': newTotalDistance,
        'lastSavedTimestamp':
            FieldValue.serverTimestamp(), // 🆕 Coordination timestamp
      }, SetOptions(merge: true));

      print(
          '✅ [MONITORING] Updated totalDistance: ${currentTotalDistance.toStringAsFixed(2)} → ${newTotalDistance.toStringAsFixed(2)} km');
    } catch (e) {
      print('❌ [MONITORING] Error saving location to Firestore: $e');
    }
  }

  void stopTracking() {
    if (!_isTracking) return;

    _setMonitoringActiveFlag(false);

    _gpsSubscription?.cancel();
    _gpsSubscription = null;

    _userDocSubscription?.cancel();
    _userDocSubscription = null;

    _saveTimer?.cancel();
    _saveTimer = null;

    _lastSavedLocation = null;
    _currentLocation = null;
    _deviceWearerId = null;
    _cachedCircleCode = null;
    _isGeoEnabled = false;
    _isTracking = false;
    _accumulatedDistanceMeters = 0.0; // 🆕 Reset accumulation

    print('🛑 [MONITORING] Location tracking stopped');
  }

  bool get isTracking => _isTracking;
}
