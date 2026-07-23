import 'package:flutter/material.dart';
import 'dart:async'; // Para sa Timer
import 'package:wearmokoapp/auth_wrapper.dart'; // 👈 BAGO: Palitan natin 'yung import

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// 👈 BAGO: 'with SingleTickerProviderStateMixin' ay para sa animation
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // 👈 BAGO: Variables para sa animation
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // --- BAGO: Setup para sa Animation ---
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Bilis ng pop-up
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, // Ito 'yung "pop-up" effect
    );

    _controller.forward(); // Simulan ang animation
    // --- Dulo ng Animation Setup ---

    // --- BAGO: Inilipat 'yung delay at navigation dito ---
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // Check kung "buhay" pa 'yung screen
        Navigator.of(context).pushReplacement(
          //
          // ⬇️ BAGO: Pinalitan ng PageRouteBuilder ⬇️
          //
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AuthWrapper(), // Papunta sa AuthWrapper

            // Ito 'yung part na nagsasabing "walang animation"
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return child; // Ibalik lang 'yung page, walang effects
            },

            // Siguraduhin na 0 ang tagal ng transition
            transitionDuration: Duration.zero,
          ),
          // ⬆️ DULO NG PAGBABAGO ⬆️
          //
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // 👈 BAGO: Linisin ang animation
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width and height for responsiveness
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Center(
        child: Container(
          width: screenWidth,
          height: screenHeight,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/backgroundsplash.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                const Color(0xFFEAA647).withOpacity(0.9),
                BlendMode.colorBurn,
              ),
            ),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Center(
            //
            // ⬇️ BAGO: Pinalibutan natin ng "ScaleTransition" 'yung logo ⬇️
            //
            child: ScaleTransition(
              scale: _scaleAnimation, // Gagamitin 'yung animation variable
              child: Image.asset(
                'assets/logo.png',
                width: screenWidth * 0.6,
                height: screenHeight * 0.3,
                fit: BoxFit.contain,
              ),
            ),
            // ⬆️ Dulo ng ScaleTransition ⬆️
            //
          ),
        ),
      ),
    );
  }
}
