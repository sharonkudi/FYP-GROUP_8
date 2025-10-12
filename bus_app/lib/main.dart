import 'dart:async';
import 'package:bus_app/home.dart';
import 'package:bus_app/l10n/app_localizations.dart';
import 'package:bus_app/settings_page.dart';
import 'package:flutter/material.dart';
import 'homepage-listform.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ✅ Settings + Provider
import 'package:provider/provider.dart';
import 'settings_provider.dart';

// ✅ Localization
import 'package:flutter_localizations/flutter_localizations.dart';

// ✅ Added
import 'splash_screen.dart'; // 👈 NEW

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Bus App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light, // ✅ Always light mode now
            textTheme: Theme.of(context).textTheme.apply(
                  fontSizeFactor: settings.fontSize / 14,
                  bodyColor: Colors.black,
                  displayColor: Colors.black,
                ),
            iconTheme: IconThemeData(
              size: settings.iconSize,
              color: Colors.black,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
              ),
            ),
            primarySwatch: Colors.blue,
          ),
          locale: settings.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('ms'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // 👇 Only SplashScreen, then HomePage
          home: !_splashDone
              ? SplashScreen(
                  duration: const Duration(seconds: 2),
                  onFinish: (_) {
                    setState(() {
                      _splashDone = true;
                    });
                  },
                )
              : const HomePage(),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  final int initialTab; // 0 = List Form, 1 = Map Form

  const HomePage({super.key, this.initialTab = 0});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = widget.initialTab; // start at desired tab
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _goToListForm() {
    Navigator.pop(context);
    _tabController.index = 0;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Fetch localized strings
    final localize = AppLocalizations.of(context)!;

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
              // Logo and Menu Title
              Padding(
                padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: const Color(0xFF103A74),
                      child:
                          const Icon(Icons.directions_bus, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'BasKu', // App name can remain hardcoded if desired
                      style: const TextStyle(
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
                      leading: const Icon(Icons.home, color: Colors.white),
                      title: Text(
                        localize.home, // localized
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: _goToListForm,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      selected: _tabController.index == 0,
                      selectedTileColor: Colors.blueAccent,
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings, color: Colors.white),
                      title: Text(
                        localize.settings, // localized
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingsPage()),
                        );
                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ],
                ),
              ),
              // TODO: Profile Section at bottom if needed
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(localize.appName), // localized
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: localize.listForm), // localized
            Tab(text: localize.mapForm), // localized
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
      backgroundColor: const Color(0xFF103A74),
    );
  }
}
