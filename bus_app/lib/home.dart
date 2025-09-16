// lib/home.dart
import 'package:flutter/material.dart';
import 'homepage-mapform.dart';
import 'stops_list_page.dart';
import 'package:bus_app/data/stops.dart';
import 'homepage-busroute.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomePageState(); // ✅ correct method name
}

enum _PanelMode { none, list, detail }

class _HomePageState extends State<Home> {
  final _mapKey = GlobalKey<MapPageState>();
  int _index = 1;
  String? _fromStop, _toStop;
  _PanelMode _panel = _PanelMode.none;
  int _selectedBusIndex = 0;

  static const Color kBlue = Color(0xFF103A74);
  static const Color kBlueLight = Color(0xFF1C6BE3);
  static const Color kDockBg = kBlue;
  static const Color kChip = Color(0xFFE9EEF7);
  static const Color kCard = Color(0xFFF4F6FA);

  static const double _dockRadius = 16;
  static const double _dockHPad = 12;
  static const double _dockBottomSafe = 8;
  static const double _tabsHeight = 38;

  List<String> get _stopNames => StopData.names;

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

  void _clearRoutePreview() {
    _mapKey.currentState?.clearRoute();
  }

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
          MapPage(key: _mapKey),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum:
            const EdgeInsets.fromLTRB(_dockHPad, 0, _dockHPad, _dockBottomSafe),
        child: Container(
          decoration: BoxDecoration(
            color: kDockBg,
            borderRadius: BorderRadius.circular(_dockRadius),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, -2)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _DockTab(
                      label: 'List Form',
                      selected: _index == 0,
                      onTap: () => setState(() {
                        _index = 0;
                        _panel = _PanelMode.none;
                        _clearRoutePreview();
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DockTab(
                      label: 'Map Form',
                      selected: _index == 1,
                      onTap: () => setState(() => _index = 1),
                    ),
                  ),
                ],
              ),
              if (_index == 1) ...[
                const SizedBox(height: 10),
                _DockSearchBar(
                  from: _fromStop,
                  to: _toStop,
                  items: _stopNames,
                  onFromChanged: (v) => setState(() => _fromStop = v),
                  onToChanged: (v) => setState(() => _toStop = v),
                  onSearch: () {
                    if (_fromStop == null || _toStop == null) return;
                    _mapKey.currentState
                        ?.showRouteBetween(_fromStop!, _toStop!);
                    setState(() => _panel = _PanelMode.list);
                  },
                ),
                if (_panel != _PanelMode.none) ...[
                  const SizedBox(height: 10),
                  if (_panel == _PanelMode.list)
                    _BusListPanel(
                      buses: _buses,
                      onTapBus: (i) => setState(() {
                        _selectedBusIndex = i;
                        _panel = _PanelMode.detail;
                      }),
                    )
                  else
                    _BusDetailPanel(
                      bus: _buses[_selectedBusIndex],
                      onClose: () => setState(() => _panel = _PanelMode.list),
                      onView: () {
                        _mapKey.currentState
                            ?.showRouteBetween(_fromStop!, _toStop!);
                      },
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tab pill
class _DockTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DockTab(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: _HomePageState._tabsHeight,
        alignment: Alignment.center,
        margin: EdgeInsets.only(top: selected ? 0 : 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withOpacity(0.12)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: Colors.white.withOpacity(selected ? 0.6 : 0.25),
              width: selected ? 1.2 : 1),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Search bar
class _DockSearchBar extends StatelessWidget {
  final String? from, to;
  final List<String> items;
  final ValueChanged<String?> onFromChanged, onToChanged;
  final VoidCallback onSearch;

  const _DockSearchBar({
    required this.from,
    required this.to,
    required this.items,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final dd = items
        .map((n) => DropdownMenuItem<String>(
            value: n, child: Text(n, overflow: TextOverflow.ellipsis)))
        .toList();

    return Container(
      height: 52,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: from,
                hint: const Text('From'),
                isExpanded: true,
                items: dd,
                onChanged: onFromChanged,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: to,
                hint: const Text('To'),
                isExpanded: true,
                items: dd,
                onChanged: onToChanged,
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onSearch,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 44,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _HomePageState.kBlue,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.search, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bus List Panel
class _BusListPanel extends StatelessWidget {
  final List<Map<String, String>> buses;
  final ValueChanged<int> onTapBus;
  const _BusListPanel({required this.buses, required this.onTapBus});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < buses.length; i++)
            InkWell(
              onTap: () => onTapBus(i),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(
                  color: _HomePageState.kCard, // ✅ use kCard
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(buses[i]['name']!,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text("${buses[i]['depart']} - ${buses[i]['arrive']}",
                              style: const TextStyle(fontSize: 12)),
                          Text(buses[i]['route']!,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black87)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _HomePageState.kChip, // ✅ use kChip
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text("ETA: ${buses[i]['eta']}",
                                style: const TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(buses[i]['fare']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bus Detail Panel
class _BusDetailPanel extends StatelessWidget {
  final Map<String, String> bus;
  final VoidCallback onClose;
  final VoidCallback onView;
  const _BusDetailPanel(
      {required this.bus, required this.onClose, required this.onView});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${bus['route']}",
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Depart: ${bus['depart']}"),
          Text("Arrive: ${bus['arrive']}"),
          Text("Bus Number: ${bus['no']}"),
          Text("Driver: ${bus['driver']}",
              style: const TextStyle(
                  color: _HomePageState.kBlueLight, // ✅ use kBlueLight
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onClose,
                  child: const Text("Back"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BusRoutePage(
                          busId: bus['no'] ?? '', // Pass bus number or ID
                          stops: [
                            // Pass your stops data here if needed
                          ],
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text("View Bus"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
