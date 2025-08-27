// lib/home.dart
import 'package:flutter/material.dart';
import 'homepage-mapform.dart';
import 'stops_list_page.dart';
import 'package:bus_app/data/stops.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState(); // ✅ correct method name
}

enum _PanelMode { none, list, detail }

class _HomeState extends State<Home> {
  // Access MapPage methods (centerBetween + offline preview)
  final _mapKey = GlobalKey<MapPageState>();

  // Tabs
  int _index = 1; // 0 = List, 1 = Map

  // Search selections
  String? _fromStop, _toStop;

  // Bottom panel (inside dock)
  _PanelMode _panel = _PanelMode.none;
  int _selectedBusIndex = 0;

  // ✅ For now: manual offline toggle (no plugins required)
  bool _isOffline = false; // set true to test offline tiles behavior
  bool _forceOfflineBanner = false; // set true to show the demo offline banner

  // Colors to match the mock
  static const Color kBlue = Color(0xFF103A74);
  static const Color kBlueLight = Color(0xFF1C6BE3);
  static const Color kDockBg = kBlue;
  static const Color kChip = Color(0xFFE9EEF7);
  static const Color kCard = Color(0xFFF4F6FA);

  // Layout
  static const double _dockRadius = 16;
  static const double _dockHPad = 12;
  static const double _dockBottomSafe = 8;
  static const double _tabsHeight = 38;

  // Stops
  List<String> get _stopNames => StopData.names;

  // Demo data
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
    _mapKey.currentState?.clearOfflineRoute();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // no AppBar; hamburger sits on the map
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: kBlue),
              child: Text('Settings', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            // Quick manual toggle for testing offline (you can remove this)
            SwitchListTile(
              title: const Text('Force Offline (dev)'),
              value: _isOffline,
              onChanged: (v) => setState(() => _isOffline = v),
            ),
            SwitchListTile(
              title: const Text('Show Offline Banner (dev)'),
              value: _forceOfflineBanner,
              onChanged: (v) => setState(() => _forceOfflineBanner = v),
            ),
          ],
        ),
      ),

      // Pages (keep both for your tab switching)
      body: IndexedStack(
        index: _index,
        children: [
          const StopsListPage(),
          MapPage(
            key: _mapKey,
            offlineMode: _isOffline, // ✅ MapPage will skip online tiles when true
          ),
        ],
      ),

      // the connected bottom dock
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(_dockHPad, 0, _dockHPad, _dockBottomSafe),
        child: Container(
          decoration: BoxDecoration(
            color: kDockBg,
            borderRadius: BorderRadius.circular(_dockRadius),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, -2)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // tabs
              Row(
                children: [
                  Expanded(
                    child: _DockTab(
                      label: 'List Form',
                      selected: _index == 0,
                      onTap: () => setState(() {
                        _index = 0;
                        _panel = _PanelMode.none;
                        _clearRoutePreview(); // clear preview when leaving map
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

              // search + panels (map tab only)
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

                    _mapKey.currentState?.centerBetween(_fromStop!, _toStop!);
                    _mapKey.currentState?.showOfflineRouteByName(_fromStop!, _toStop!);

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
                        // later: live tracking screen
                      },
                    ),
                ],

                // Dev-only offline banner (hidden unless you flip _forceOfflineBanner = true)
                if (_forceOfflineBanner) ...[
                  const SizedBox(height: 10),
                  _OfflineBanner(
                    onCta: () {
                      const from = 'Yayasan Complex';
                      const to = 'Ong Sum Ping';
                      _fromStop = from;
                      _toStop = to;
                      _mapKey.currentState?.centerBetween(from, to);
                      _mapKey.currentState?.showOfflineRouteByName(from, to);
                      setState(() => _panel = _PanelMode.none);
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

/// Raised tab pill
class _DockTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DockTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: _HomeState._tabsHeight,
        alignment: Alignment.center,
        margin: EdgeInsets.only(top: selected ? 0 : 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(selected ? 0.6 : 0.25), width: selected ? 1.2 : 1),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Attached search (no dropdown arrows)
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
        .map((n) => DropdownMenuItem<String>(value: n, child: Text(n, overflow: TextOverflow.ellipsis)))
        .toList();

    return Container(
      height: 52,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: _ArrowlessField(
              leading: Icons.directions_bus,
              value: from,
              hint: 'From: BS Osp',
              items: dd,
              onChanged: onFromChanged,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ArrowlessField(
              leading: Icons.flag,
              value: to,
              hint: 'To: BS Mall',
              items: dd,
              onChanged: onToChanged,
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
              decoration: BoxDecoration(color: _HomeState.kBlue, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.search, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowlessField extends StatelessWidget {
  final IconData leading;
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _ArrowlessField({
    required this.leading,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(color: _HomeState.kCard, borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(leading, size: 18, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text(hint, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                isExpanded: true,
                items: items,
                onChanged: onChanged,
                icon: const SizedBox.shrink(), // removes default arrow
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// List panel — inside dock
class _BusListPanel extends StatelessWidget {
  final List<Map<String, String>> buses;
  final ValueChanged<int> onTapBus;

  const _BusListPanel({required this.buses, required this.onTapBus});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 34,
            decoration: const BoxDecoration(
              color: _HomeState.kBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 6),
          for (int i = 0; i < buses.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: InkWell(
                onTap: () => onTapBus(i),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(color: _HomeState.kCard, borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(buses[i]['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('${buses[i]['depart']} - ${buses[i]['arrive']}', style: const TextStyle(fontSize: 12)),
                            Text(buses[i]['route']!, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: _HomeState.kChip, borderRadius: BorderRadius.circular(8)),
                              child: Text('eta: ${buses[i]['eta']}', style: const TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 3, offset: const Offset(0, 1))],
                            ),
                            child: Text(buses[i]['fare']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.wheelchair_pickup, size: 18, color: Colors.black45),
                              SizedBox(width: 10),
                              Icon(Icons.wifi, size: 18, color: Colors.black45),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Detail panel — inside dock
class _BusDetailPanel extends StatelessWidget {
  final Map<String, String> bus;
  final VoidCallback onClose;
  final VoidCallback onView;

  const _BusDetailPanel({required this.bus, required this.onClose, required this.onView});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 34,
            decoration: const BoxDecoration(
              color: _HomeState.kBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bus['route']!, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _kv('Depart:', bus['depart']!),
                          _kvBold('Arrive:', bus['arrive']!),
                          const SizedBox(height: 4),
                          Text('Bus Number: ${bus['no']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.black87, fontSize: 13),
                              children: [
                                const TextSpan(text: 'Driver: '),
                                TextSpan(text: bus['driver'], style: const TextStyle(fontWeight: FontWeight.w700, color: _HomeState.kBlueLight)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      children: [
                        Text(bus['no']!, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.black87)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _HomeState.kBlue,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              const Text('Total:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                child: Text(bus['total']!, style: const TextStyle(color: _HomeState.kBlue, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onClose,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _HomeState.kBlue,
                          side: const BorderSide(color: _HomeState.kBlue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onView,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF39C26A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text('View Bus', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          children: [
            TextSpan(text: '$k '),
            TextSpan(text: v, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _kvBold(String k, String v) => RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          children: [
            TextSpan(text: '$k '),
            TextSpan(text: v, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

/// offline banner widget (dev only)
class _OfflineBanner extends StatelessWidget {
  final VoidCallback onCta;
  const _OfflineBanner({required this.onCta});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('You Are Offline', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: TextButton(
                onPressed: onCta,
                child: const Text(
                  'Bus Stations and Routes\nNear Your area',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _HomeState.kBlue, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
