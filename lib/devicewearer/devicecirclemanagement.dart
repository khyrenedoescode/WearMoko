import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wearmokoapp/devicewearer/deviceadminstatus.dart';

class DeviceCircleM extends StatelessWidget {
  const DeviceCircleM({super.key});

  Widget _buildActionRow({
    required String title,
    required VoidCallback onTap,
    Color titleColor = Colors.black,
    IconData trailingIcon = Icons.arrow_forward_ios,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom:
                BorderSide(color: Color.fromRGBO(217, 217, 217, 0.5), width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: titleColor,
                ),
              ),
            ),
            Icon(
              trailingIcon,
              size: 16,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Circle Management',
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
          _buildActionRow(
            title: 'Admin Status',
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) =>
                      const DeviceAdmin(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
