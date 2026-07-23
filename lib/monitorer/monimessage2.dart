import 'package:flutter/material.dart';

class Monimessage2 extends StatefulWidget {
  const Monimessage2({super.key});

  @override
  State<Monimessage2> createState() => _MonimessageState();
}

class _MonimessageState extends State<Monimessage2> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Orange bar with bottom border
          Positioned(
            left: 0,
            top: 0,
            width: MediaQuery.of(context).size.width,
            height: 100,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF4B315), // #F4B315 color
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFB0AEAE), // #B0AEAE color
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // User Text
          const Positioned(
            left: 85,
            top: 45,
            child: Text(
              'User',
              style: TextStyle(
                fontFamily: 'Roboto Mono',
                fontWeight: FontWeight.w900,
                fontSize: 28,
                color: Color(0xFF000000),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Back Button
          Positioned(
            left: 25,
            top: 43,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context); // Return to previous page
              },
              child: Container(
                width: 44,
                height: 38,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/back.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

          // Main Content Area (e.g., Chat Messages)
          Positioned.fill(
            top: 100,
            bottom: 75,
            child: SingleChildScrollView(
              reverse: true,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: const Column(
                children: [
                  // Main Content (e.g., chat bubbles, message history)
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Bar with Text Field and Send Button
          Positioned(
            left: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width,
            height: 75,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: const Color(0xFFF4B315),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 15, right: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F6F1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFFF4EFEF)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            offset: const Offset(0, 4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Text Message',
                          hintStyle: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w300,
                            fontSize: 14,
                            color: Color(0xFF000000),
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w300,
                          fontSize: 14,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 15), // Move send button more to the left
                    child: GestureDetector(
                      onTap: () {
                        // Implement your send message action here
                        print('Message sent: ${_textController.text}');
                        _textController.clear();
                      },
                      child: Image.asset(
                        'assets/send.png',
                        width: 50,
                        height: 35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
