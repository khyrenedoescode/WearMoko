import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen2 extends StatefulWidget {
  const PermissionsScreen2({super.key});

  @override
  _PermissionsScreen2State createState() => _PermissionsScreen2State();
}

class _PermissionsScreen2State extends State<PermissionsScreen2> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  // Requesting permissions
  Future<void> _requestPermissions() async {
    // Request multiple permissions at once
    await [
      Permission.camera,
      Permission.photos,
      Permission.storage,
    ].request();

    // Close the overlay once permissions are requested
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Returns an empty widget with no UI
  }
}
