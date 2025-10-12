import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login-register.dart';
import 'driver-list.dart';
import 'bus-schedule.dart';
import 'home-page.dart'; // ✅ to reset session flag

class AdminDrawer extends StatelessWidget {
  final int selectedIndex; // highlight which page is active

  const AdminDrawer({super.key, required this.selectedIndex});

  Future<void> _logout(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // fetch adminId
      final snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      if (snapshot.exists) {
        final adminId = snapshot['admin_id'];

        // write "Logged out"
        await FirebaseFirestore.instance.collection('logs').add({
          'admin_id': adminId,
          'action': "Logged out",
          'timestamp': FieldValue.serverTimestamp(),
          'localTime': DateTime.now(),
        });
      }
    }

    // sign out
    await FirebaseAuth.instance.signOut();

    // reset session flag for next login
    HomePageState.sessionLoginLogged = false;

    // navigate to login page
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AdminLoginPage()),
      (route) => false,
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    int index,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      selected: selectedIndex == index,
      selectedTileColor: Colors.blueAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        Navigator.pop(context); // close drawer
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DriverListPage(),
            ), // Home also reuses DriverListPage
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DriverListPage()),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminBusSchedulePage(
                adminId: 'yourAdminId', // TODO: Replace with actual adminId
                adminName:
                    'yourAdminName', // TODO: Replace with actual adminName
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
            Padding(
              padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
              child: Row(
                children: const [
                  SizedBox(width: 16),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white, // white border
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFF103A74),
                      child: Icon(Icons.directions_bus, color: Colors.white),
                    ),
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
            Expanded(
              child: ListView(
                children: [
                  _buildDrawerItem(context, Icons.home, 'Home', 0),
                  _buildDrawerItem(context, Icons.people, 'Driver List', 1),
                  _buildDrawerItem(context, Icons.schedule, 'Bus Schedule', 2),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
