import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wearmokoapp/user_agreements.dart'; // Make sure this import is correct

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  _PermissionsScreenState createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request multiple permissions
    Map<Permission, PermissionStatus> status = await [
      Permission.location,
      Permission.notification,
    ].request();

    // Use safe null-aware checks
    bool allGranted = status.entries.every((entry) => entry.value.isGranted);

    if (allGranted) {
      // Navigate to UserAgreements if all permissions are granted
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const UserAgreements()),
      );
    } else {
      // Optional: Handle denied permissions (e.g. show dialog)
      print("Not all permissions were granted.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // No UI needed
  }
}
