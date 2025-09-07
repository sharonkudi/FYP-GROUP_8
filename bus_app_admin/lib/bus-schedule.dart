import 'package:flutter/material.dart';

class BusSchedulePage extends StatelessWidget {
  const BusSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF103A74),
      body: const Center(
        child: Text(
          "This is the Bus Schedule Page",
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
      ),
    );
  }
}