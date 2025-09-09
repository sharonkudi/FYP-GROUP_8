import 'package:flutter/material.dart';

class BusSchedulePage extends StatelessWidget {
  const BusSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: const Center(
        child: Text(
          "This is the Bus Schedule Page",
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 22),
        ),
      ),
    );
  }
}