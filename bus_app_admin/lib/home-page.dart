import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF103A74), // dark blue background
      body: const Center(
        child: Text(
          "Welcome to Bus Admin Home",
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
