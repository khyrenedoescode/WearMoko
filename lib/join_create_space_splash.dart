import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wearmokoapp/creatingaspace.dart';
import 'package:wearmokoapp/monitorer.dart';
import 'package:google_fonts/google_fonts.dart';

class JoinCreateSpaceSplash extends StatefulWidget {
  const JoinCreateSpaceSplash({super.key});

  @override
  _JoinCreateSpaceSplashState createState() => _JoinCreateSpaceSplashState();
}

class _JoinCreateSpaceSplashState extends State<JoinCreateSpaceSplash> {
  String? firstName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserFirstName();
  }

  Future<void> fetchUserFirstName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            firstName = userDoc['firstName'] ?? 'User';
            isLoading = false;
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
        setState(() {
          firstName = 'User';
          isLoading = false;
        });
      }
    } else {
      setState(() {
        firstName = 'User';
        isLoading = false;
      });
    }
  }

  Future<void> navigateBasedOnRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          String role = userDoc.get('role');
          if (role == 'Device Wearer') {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    CreatingASpaceScreen(),
                transitionDuration: Duration.zero, // No animation
                reverseTransitionDuration: Duration.zero,
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) => child,
              ),
            );
          } else if (role == 'Monitoring User') {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const Monitor1(),
                transitionDuration: Duration.zero, // No animation
                reverseTransitionDuration: Duration.zero,
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) => child,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unknown role')),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error retrieving role: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    Widget buildBackground() {
      return Container(
        width: screenWidth,
        height: screenHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFEAA647),
          image: DecorationImage(
            image: const AssetImage('assets/backgroundsplash.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              const Color(0xFFEAA647).withOpacity(0.9),
              BlendMode.colorBurn,
            ),
          ),
        ),
      );
    }

    if (isLoading) {
      return Scaffold(
        body: Stack(
          children: [
            buildBackground(),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              buildBackground(),

              // World image
              Positioned(
                left: screenWidth * 0.14,
                top: screenHeight * 0.31,
                child: Image.asset(
                  'assets/world.png',
                  width: screenWidth * 0.71,
                  height: screenHeight * 0.32,
                ),
              ),

              // Bold greeting
              Positioned(
                left: screenWidth * 0.14,
                top: screenHeight * 0.13,
                child: SizedBox(
                  width: screenWidth * 0.71,
                  child: Text(
                    'Hello, $firstName! You can join or create your own Space',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 32.0,
                      height: 1.31,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              // Description text
              Positioned(
                left: screenWidth * 0.16,
                top: screenHeight * 0.70,
                child: SizedBox(
                  width: screenWidth * 0.71,
                  child: Text(
                    'A Space is a private room only accessible by authorized people like you and your family',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.normal,
                      fontSize: 16.5,
                      height: 1.15,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ),

              // Next button
              Positioned(
                left: screenWidth * 0.14,
                top: screenHeight * 0.83,
                child: ElevatedButton(
                  onPressed: navigateBasedOnRole,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.black),
                    shadowColor: Colors.black.withOpacity(0.25),
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    fixedSize: Size(screenWidth * 0.71, screenHeight * 0.06),
                  ),
                  child: Text(
                    'Next',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.06,
                      color: const Color(0xFF212121),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
