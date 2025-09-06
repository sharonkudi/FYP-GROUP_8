import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'bus-schedule.dart';
import 'login-register.dart'; // AdminLoginPage

class DriverListPage extends StatefulWidget {
  const DriverListPage({super.key});

  @override
  State<DriverListPage> createState() => _DriverListPageState();
}

class _DriverListPageState extends State<DriverListPage> {
  int _selectedIndex = 1; // default to Driver List when opened

  final List<String> _titles = [
    'Home',
    'Driver List',
    'Bus Schedule',
  ];

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AdminLoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      const Center(
        child: Text(
          "Welcome to Bus Admin Home",
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
      // Driver List Page content (this page itself)
      const Center(
        child: Text(
          "Driver List Page",
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
      // Bus Schedule placeholder (for now)
      const Center(
        child: Text(
          "Bus Schedule Page (Coming Soon)",
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    ];

    return Scaffold(
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Container(
          color: const Color(0xFF1A2332),
          child: Column(
            children: [
              // Logo and Title
              Padding(
                padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
                child: Row(
                  children: const [
                    SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: Color(0xFF103A74),
                      child: Icon(Icons.directions_bus, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Bus Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Menu items
              Expanded(
                child: ListView(
                  children: [
                    _buildDrawerItem(Icons.home, 'Home', 0),
                    _buildDrawerItem(Icons.people, 'Driver List', 1),
                    _buildDrawerItem(Icons.schedule, 'Bus Schedule', 2),
                  ],
                ),
              ),
              // Logout button at the bottom
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text('Logout', style: TextStyle(color: Colors.white)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: _logout,
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: const Color(0xFF103A74),
      ),
      body: _pages[_selectedIndex],
      backgroundColor: const Color(0xFF103A74),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.blueAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context); // close drawer
      },
    );
  }
}
