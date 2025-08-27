import 'package:bus_app/home.dart';
import 'package:flutter/material.dart';
import 'homepage-listform.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(), // Use HomePage as the entry point
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _goToListForm() {
    Navigator.pop(context); // Close the drawer
    _tabController.index = 0; // Switch to List Form tab
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Container(
          color: const Color(0xFF1A2332), // Dark sidebar background
          child: Column(
            children: [
              // Logo and Menu Title
              Padding(
                padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    // Placeholder for logo
                    CircleAvatar(
                      backgroundColor: Color(0xFF103A74),
                      child: Icon(Icons.directions_bus, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'BasKu',
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
                    ListTile(
                      leading: Icon(Icons.home, color: Colors.white),
                      title: Text('Home', style: TextStyle(color: Colors.white)),
                      onTap: _goToListForm,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      selected: _tabController.index == 0,
                      selectedTileColor: Colors.blueAccent,
                    ),
                    ListTile(
                      leading: Icon(Icons.settings, color: Colors.white),
                      title: Text('Settings', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ],
                ),
              ),
              // Profile section at the bottom
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('BasKu'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'List Form'),
            Tab(text: 'Map Form'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ListFormPage(),
          Home(),
        ],
      ),
      backgroundColor: Color(0xFF103A74),
    );
  }
}
