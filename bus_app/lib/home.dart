import 'package:flutter/material.dart';
import 'homepage-mapform.dart';
import 'stops_list_page.dart';
import 'homepage-busroute.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomePageState();
}

enum _PanelMode { none, list, detail }

class _HomePageState extends State<Home> {
  final _mapKey = GlobalKey<MapPageState>();
  final int _index = 1;
  String? _fromStop, _toStop;
  final _PanelMode _panel = _PanelMode.none;
  final int _selectedBusIndex = 0;

  static const Color kBlue = Color(0xFF103A74);
  static const Color kBlueLight = Color(0xFF1C6BE3);
  static const Color kDockBg = kBlue;
  static const Color kChip = Color(0xFFE9EEF7);
  static const Color kCard = Color(0xFFF4F6FA);

  static const double _dockRadius = 16;
  static const double _dockHPad = 12;
  static const double _dockBottomSafe = 8;
  static const double _tabsHeight = 38;

  List<String> get _stopNames => [];

  final _buses = const [
    {
      'name': 'Bas A',
      'depart': '1:05PM',
      'arrive': '1:35PM',
      'route': 'BS Osp to BS Mall',
      'eta': '1 min',
      'fare': '\$1',
      'no': 'BA1',
      'driver': 'Mr Singh',
      'total': '\$1',
    },
    {
      'name': 'Bas B',
      'depart': '1:45PM',
      'arrive': '2:05PM',
      'route': 'BS Osp to BS Mall',
      'eta': '30 min',
      'fare': '\$1',
      'no': 'BB2',
      'driver': 'Mr Ali',
      'total': '\$1',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(color: kBlue),
              child: Text('Settings',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: [
          const StopsListPage(),
          MapFormPage(key: _mapKey),
        ],
      ),
      // ✅ safely hides the extra dark blue bottom bar
      bottomNavigationBar: const SizedBox.shrink(),
    );
  }
}
