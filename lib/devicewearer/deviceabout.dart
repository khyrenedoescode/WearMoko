import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeviceAbout extends StatefulWidget {
  const DeviceAbout({super.key});

  @override
  _DeviceAboutState createState() => _DeviceAboutState();
}

class _DeviceAboutState extends State<DeviceAbout>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildSection(
                    icon: Icons.groups_rounded,
                    title: 'Who We Are',
                    content:
                        'We are a passionate team of BSIT students from Holy Cross of Davao College. Our mission is to create innovative solutions that prioritize people\'s safety and well-being.',
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    icon: Icons.code_rounded,
                    title: 'Meet the Developers',
                    contentWidget: const Column(
                      children: [
                        AnimatedDeveloperCard(
                            name: 'Khyrene Mae Utanes', delay: 0),
                        AnimatedDeveloperCard(
                            name: 'Alexander Grant Rebusora', delay: 150),
                        AnimatedDeveloperCard(name: 'Ladyly Biyo', delay: 300),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    icon: Icons.lightbulb_outline,
                    title: 'Our Mission',
                    content:
                        'To leverage technology in making communities safer by providing real-time monitoring and emergency response tools for everyone.',
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    icon: Icons.phone_android_rounded,
                    title: 'About the Application',
                    content:
                        'Wearmoko is an IoT-integrated mobile app focused on people\'s safety. It features a GPS module, ESP32, GSM module, and a Raspberry Pi with camera, enabling real-time location tracking and emergency monitoring. The app is designed to be user-friendly, reliable, and accessible for all.',
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF4B315),
      elevation: 1,
      centerTitle: true,
      title: Text(
        'About',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: Colors.black,
        ),
      ),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.only(left: 20),
          child: Image.asset('assets/back.png', fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFC266), Color(0xFFFFD498)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: const Icon(Icons.shield_outlined,
              size: 48, color: Color(0xFFB98000)),
        ),
        const SizedBox(height: 12),
        Text(
          'Wearmoko',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 36,
            color: const Color(0xFFB98000),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    String? content,
    Widget? contentWidget,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: Colors.orange.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFB98000)),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            contentWidget ??
                Text(
                  content ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    height: 1.5,
                    color: const Color(0xFF333333),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

// --- Animated Developer Card ---
class AnimatedDeveloperCard extends StatefulWidget {
  final String name;
  final int delay;
  const AnimatedDeveloperCard(
      {required this.name, required this.delay, super.key});

  @override
  State<AnimatedDeveloperCard> createState() => _AnimatedDeveloperCardState();
}

class _AnimatedDeveloperCardState extends State<AnimatedDeveloperCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(_controller);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Card(
          color: Colors.orange.shade50,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.person, size: 20, color: Color(0xFFB98000)),
                const SizedBox(width: 8),
                Text(
                  widget.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
