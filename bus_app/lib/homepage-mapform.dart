// lib/homepage-mapform.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:open_route_service/open_route_service.dart';
import 'package:bus_app/l10n/app_localizations.dart';

class MapFormPage extends StatefulWidget {
  final String? focusBusId;
  const MapFormPage({super.key, this.focusBusId});

  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends State<MapFormPage> {
  final mapController = MapController();
  final DatabaseReference _rtdb = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, LatLng> _busPositions = {};
  Map<String, BusInfo> _busInfo = {};
  List<StopData> _firebaseStops = [];

  LatLng? _devicePosition;
  List<LatLng> _routeA = [];
  List<LatLng> _routeB = [];
  List<LatLng> _walkLine = [];

  String? _selectedFromStop;
  String? _selectedToStop;
  String? _etaStopName;
  String? _etaFromStop;
  String _etaStatus = "";
  Timer? _etaTimer;

  @override
  void initState() {
    super.initState();
    _listenFirestoreBuses();
    _listenRealtimeGps();
    _initDeviceGps();
    _rtdbOneTimeCheck();
  }

  @override
  void dispose() {
    _etaTimer?.cancel();
    super.dispose();
  }

  // ---------------- GPS INIT ----------------
  void _initDeviceGps() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;
    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied) return;
    }
    if (p == LocationPermission.deniedForever) return;

    Geolocator.getPositionStream(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((pos) {
      setState(() => _devicePosition = LatLng(pos.latitude, pos.longitude));
    });
  }

  // ---------------- FIRESTORE ----------------
  void _listenFirestoreBuses() {
    _firestore.collection('buses').snapshots().listen((snap) {
      final info = <String, BusInfo>{};
      final stops = <StopData>[];

      for (final doc in snap.docs) {
        final data = doc.data();
        final busId = data['bus_id'] ?? doc.id;

        info[busId] = BusInfo(
          docId: doc.id,
          busId: busId,
          name: data['bus_name'] ?? 'Bus $busId',
          assignedTo: data['assignedTo'] ?? '',
          features: List<String>.from(data['features'] ?? []),
        );

        if (data['stops'] is List) {
          for (final s in data['stops']) {
            stops.add(StopData(
              name: s['name'] ?? 'Stop',
              lat: (s['lat'] ?? 0).toDouble(),
              lng: (s['lng'] ?? 0).toDouble(),
              time: s['time'] ?? '',
              busName: data['bus_name'] ?? 'Unknown Bus',
            ));
          }
        }
      }

      setState(() {
        _busInfo = info;
        _firebaseStops = stops;
      });
    }, onError: (e) {
      debugPrint('Firestore listen error: $e');
    });
  }

  // ---------------- RTDB ----------------
  void _listenRealtimeGps() {
    _rtdb.onValue.listen((e) {
      final val = e.snapshot.value;
      final updated = <String, LatLng>{};
      if (val == null) return;
      if (val is Map) {
        final data = Map<String, dynamic>.from(val);
        void read(String key, String id) {
          try {
            if (data[key] != null) {
              final gps = Map<String, dynamic>.from(data[key]);
              final lat = _toDouble(gps['latitude']);
              final lng = _toDouble(gps['longitude']);
              if (lat != null && lng != null) {
                updated[id] = LatLng(lat, lng);
              }
            }
          } catch (e) {
            debugPrint('Error reading GPS for $key: $e');
          }
        }

        read('gpsData', 'BUS001');
        read('gpsData2', 'BUS002');
      }
      setState(() => _busPositions = updated);
    });
  }

  Future<void> _rtdbOneTimeCheck() async {
    try {
      final snap = await _rtdb.child('gpsData').get();
      final snap2 = await _rtdb.child('gpsData2').get();
      debugPrint('RTDB gpsData: ${snap.value}');
      debugPrint('RTDB gpsData2: ${snap2.value}');
    } catch (e) {
      debugPrint('RTDB read error: $e');
    }
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

// ---------------- ROUTE LOGIC ----------------
void _clearRoute() {
  setState(() {
    _routeA.clear();
    _routeB.clear();
    _walkLine.clear();
  });
}

Future<void> _generateDropdownRoute() async {
  if (_selectedFromStop == null || _selectedToStop == null) {
    _clearRoute();
    return;
  }

  try {
    final from = _firebaseStops.firstWhere((s) => s.name == _selectedFromStop);
    final to = _firebaseStops.firstWhere((s) => s.name == _selectedToStop);

    if (from.busName == to.busName) {
      await _drawSingleRoute(from, to);
    } else {
      await _drawTransitRoute(from, to);
    }

    _startEtaTimer(from.busName, to.lat, to.lng, from.name);
  } catch (e) {
    debugPrint('Route generation error: $e');
  }
}

// ---------- SINGLE BUS ROUTE ----------
Future<void> _drawSingleRoute(StopData from, StopData to) async {
  try {
    final ors = OpenRouteService(
      apiKey:
          'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjU4YzVjYzVkZWZiZDRlN2NhM2VhMDI5Mjg3NWViNmFhIiwiaCI6Im11cm11cjY0In0=',
    );

    final coords = await ors.directionsRouteCoordsGet(
      startCoordinate: ORSCoordinate(latitude: from.lat, longitude: from.lng),
      endCoordinate: ORSCoordinate(latitude: to.lat, longitude: to.lng),
    );

    if (mounted) {
      setState(() {
        _routeA = coords.map((c) => LatLng(c.latitude, c.longitude)).toList();
        _routeB.clear();
        _walkLine.clear();
      });
    }
  } catch (e) {
    debugPrint("Route error $e");
  }
}

// ---------- TRANSIT ROUTE ----------
Future<void> _drawTransitRoute(StopData from, StopData to) async {
  try {
    final ors = OpenRouteService(
      apiKey:
          'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjU4YzVjYzVkZWZiZDRlN2NhM2VhMDI5Mjg3NWViNmFhIiwiaCI6Im11cm11cjY0In0=',
    );

    // Clear previous route
    if (mounted) {
      setState(() {
        _routeA.clear();
        _routeB.clear();
        _walkLine.clear();
      });
    }

    // Identify transit transfer stops
    final kianggehA = _firebaseStops.firstWhere(
      (s) => s.name.toLowerCase().contains("kianggeh") && s.busName.contains("Bus A"),
    );
    final yayasanB = _firebaseStops.firstWhere(
      (s) => s.name.toLowerCase().contains("yayasan") && s.busName.contains("Bus B"),
    );

    // Determine direction
    final isAToB = from.busName.contains("Bus A") && to.busName.contains("Bus B");
    final isBToA = from.busName.contains("Bus B") && to.busName.contains("Bus A");

    List<LatLng> seg1 = [];
    List<LatLng> seg3 = [];
    List<LatLng> walkSeg = [];

    if (isAToB) {
      final r1 = await ors.directionsRouteCoordsGet(
        startCoordinate: ORSCoordinate(latitude: from.lat, longitude: from.lng),
        endCoordinate: ORSCoordinate(latitude: kianggehA.lat, longitude: kianggehA.lng),
      );

      final r2 = await ors.directionsRouteCoordsGet(
        startCoordinate: ORSCoordinate(latitude: yayasanB.lat, longitude: yayasanB.lng),
        endCoordinate: ORSCoordinate(latitude: to.lat, longitude: to.lng),
      );

      seg1 = r1.map((c) => LatLng(c.latitude, c.longitude)).toList();
      seg3 = r2.map((c) => LatLng(c.latitude, c.longitude)).toList();
      walkSeg = [
        LatLng(kianggehA.lat, kianggehA.lng),
        LatLng(yayasanB.lat, yayasanB.lng),
      ];

      debugPrint("Transit A→B: A:${seg1.length} | Walk:${walkSeg.length} | B:${seg3.length}");
    } else if (isBToA) {
      final r1 = await ors.directionsRouteCoordsGet(
        startCoordinate: ORSCoordinate(latitude: from.lat, longitude: from.lng),
        endCoordinate: ORSCoordinate(latitude: yayasanB.lat, longitude: yayasanB.lng),
      );

      final r2 = await ors.directionsRouteCoordsGet(
        startCoordinate: ORSCoordinate(latitude: kianggehA.lat, longitude: kianggehA.lng),
        endCoordinate: ORSCoordinate(latitude: to.lat, longitude: to.lng),
      );

      seg1 = r1.map((c) => LatLng(c.latitude, c.longitude)).toList();
      seg3 = r2.map((c) => LatLng(c.latitude, c.longitude)).toList();
      walkSeg = [
        LatLng(yayasanB.lat, yayasanB.lng),
        LatLng(kianggehA.lat, kianggehA.lng),
      ];

      debugPrint("Transit B→A: B:${seg1.length} | Walk:${walkSeg.length} | A:${seg3.length}");
    } else {
      debugPrint("❌ No valid transit direction found.");
      return;
    }

    if (seg1.isEmpty || seg3.isEmpty) {
      debugPrint("⚠️ Empty route segment – skipping render.");
      return;
    }

    if (mounted) {
      setState(() {
        _routeA = seg1;
        _walkLine = walkSeg;
        _routeB = seg3;
      });

      // Delay to ensure map renders first before showing popup
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        if (isAToB) {
          _showTransitPopup(
              context, "Bus A (BUS001)", "Bus B (BUS002)", "Kianggeh → Yayasan Complex");
        } else {
          _showTransitPopup(
              context, "Bus B (BUS002)", "Bus A (BUS001)", "Yayasan Complex → Kianggeh");
        }
      });
    }
  } catch (e) {
    debugPrint("Transit route error: $e");
  }
}
// ---------------- INFO POPUPS ----------------
void _showBusInfoPopup(BuildContext context, BusInfo info) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        color: Colors.white.withOpacity(0.95),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(info.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Driver: ${info.assignedTo}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
  "Features:",
  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
),
const SizedBox(height: 8),

Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: info.features.map((f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ",
              style: TextStyle(fontSize: 16, color: Colors.black87)),
          Expanded(
            child: Text(
              f,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }).toList(),
),






            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                child: const Text("Close", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showStopInfoPopup(BuildContext context, StopData stop) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(stop.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Text("Bus: ${stop.busName}\nScheduled Time: ${stop.time}"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    ),
  );
}

// ---------------- ETA INFO POPUP WHEN TAP ----------------
void _showEtaDetailsPopup(BuildContext context) {
  if (_etaFromStop == null || _etaStopName == null) return;

  // Find bus info from Firestore snapshot
  final busInfo = _busInfo.values.firstWhere(
    (b) => b.name == _etaFromStop,
    orElse: () => BusInfo(
      docId: "",
      busId: "",
      name: _etaFromStop ?? "",
      assignedTo: "Unknown",
      features: [],
    ),
  );

  // Find stop info
  final stopInfo = _firebaseStops.firstWhere(
    (s) => s.name == _etaStopName,
    orElse: () => StopData(
      name: _etaStopName ?? "",
      lat: 0,
      lng: 0,
      time: "Unknown",
      busName: busInfo.name,
    ),
  );

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        color: Colors.white.withOpacity(0.95),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(busInfo.name,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo)),
            const SizedBox(height: 6),
            Text("Driver: ${busInfo.assignedTo}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text("Bus Features:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ...busInfo.features.map((f) => Text("• $f")),
            const Divider(height: 20, color: Colors.black26),
            Text("Next Stop: ${stopInfo.name}",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Scheduled Time: ${stopInfo.time}",
                style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 10),
            Text("Status: $_etaStatus",
                style:
                    const TextStyle(fontSize: 15, color: Colors.deepPurple)),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                child:
                    const Text("Close", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


// ---------------- ETA TIMER  ----------------
void _startEtaTimer(String busName, double stopLat, double stopLng, String fromStop) {
  _etaTimer?.cancel();

  _etaTimer = Timer.periodic(const Duration(seconds: 5), (_) {
    final busId = busName.contains("A") ? "BUS001" : "BUS002";
    final busPos = _busPositions[busId];
    if (busPos == null) return;

    // Calculate distance (in meters) between bus and target stop
    final distance = const Distance().as(LengthUnit.Meter, busPos, LatLng(stopLat, stopLng));

    // Assume realistic average speed ~25 km/h (≈ 6.94 m/s)
    final avgSpeed = 6.94;
    final etaMinutes = distance / (avgSpeed * 60);

    String status;
    if (distance < 25) {
      status = "✅ Arrived at destination";
    } else if (distance < 120) {
      status = "🟢 Arriving Soon (${etaMinutes.toStringAsFixed(1)} min)";
    } else {
      status = "🕓 ETA ${etaMinutes.toStringAsFixed(1)} min";
    }

    if (mounted) {
      setState(() {
        _etaStopName = fromStop;
        _etaFromStop = busName;
        _etaStatus = status;
      });
    }
  });
}


  // ---------------- TRANSIT POPUP ----------------
  void _showTransitPopup(BuildContext context, String fromBus, String toBus, String stop) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white.withOpacity(0.95),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.transfer_within_a_station,
                  color: Colors.deepPurple, size: 44),
              const SizedBox(height: 12),
              const Text("Transit Required",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.deepPurple)),
              const SizedBox(height: 8),
              Text(
                "Drop off at $stop and walk (~5 min) to continue your journey.\n\nExtra Fare: BND 1.00",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                child: const Text("Close", style: TextStyle(color: Colors.white)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ---------------- UI BUILD ----------------
  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];

    // Bus icons (make tappable)
_busPositions.forEach((id, pos) {
  final info = _busInfo[id];
  final color = id == "BUS001" ? Colors.red : Colors.blue;

  markers.add(Marker(
    width: 120,
    height: 120,
    point: pos,
    child: GestureDetector(
      onTap: () {
        if (info != null) _showBusInfoPopup(context, info);
      },
      child: _FloatingBusMarker(busName: info?.name ?? id, color: color),
    ),
  ));
});

// Bus stops numbered (make tappable)
int index = 1;
for (var s in _firebaseStops) {
  markers.add(Marker(
    width: 50,
    height: 65,
    point: LatLng(s.lat, s.lng),
    child: GestureDetector(
      onTap: () => _showStopInfoPopup(context, s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: const Icon(Icons.directions_bus, color: Colors.white, size: 22),
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              index.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  ));
  index++;
}



    // User location marker
    if (_devicePosition != null) {
      markers.add(Marker(
        width: 40,
        height: 40,
        point: _devicePosition!,
        child:
            const Icon(Icons.person_pin_circle, color: Colors.green, size: 38),
      ));
    }

    final center = _busPositions.isNotEmpty
        ? _busPositions.values.first
        : const LatLng(4.9, 114.9);

    return Scaffold(
      body: Stack(children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(initialCenter: center, initialZoom: 13),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
            PolylineLayer(polylines: [
              Polyline(points: _routeA, color: Colors.deepPurple, strokeWidth: 5),
              Polyline(points: _walkLine, color: Colors.orange, strokeWidth: 3, isDotted: true),
              Polyline(points: _routeB, color: Colors.teal, strokeWidth: 5),
            ]),
            MarkerLayer(markers: markers),
          ],
        ),
        if (_etaStopName != null)
  Positioned(
    left: 0,
    right: 0,
    bottom: 65,
    child: _EtaCard(
      stop: _etaStopName!,
      from: _etaFromStop!,
      status: _etaStatus,
      onTap: () => _showEtaDetailsPopup(context),
    ),
  ),

Positioned(
  bottom: 0,
  left: 0,
  right: 0,
  child: _buildBottomSearch(context), // ✅ bring back search bar
),


      ]),
    );
  }

  Widget _buildBottomSearch(BuildContext context) {
    final stops = _firebaseStops.map((s) => s.name).toSet().toList();
    return Container(
      color: const Color(0xFF0B1B4D),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Expanded(
          child: DropdownButton<String>(
            value: _selectedFromStop,
            dropdownColor: const Color(0xFF0B1B4D),
            hint: Text(AppLocalizations.of(context)!.from,
                style: const TextStyle(color: Colors.white)),
            style: const TextStyle(color: Colors.white),
            isExpanded: true,
            items: stops.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
            onChanged: (v) => setState(() => _selectedFromStop = v),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButton<String>(
            value: _selectedToStop,
            dropdownColor: const Color(0xFF0B1B4D),
            hint: Text(AppLocalizations.of(context)!.to,
                style: const TextStyle(color: Colors.white)),
            style: const TextStyle(color: Colors.white),
            isExpanded: true,
            items: stops.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
            onChanged: (v) => setState(() => _selectedToStop = v),
          ),
        ),
        IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: _generateDropdownRoute)
      ]),
    );
  }
}

// ---------------- ETA CARD ----------------
class _EtaCard extends StatelessWidget {
  final String stop, from, status;
  final VoidCallback onTap; // 👈 new line added

  const _EtaCard({
    required this.stop,
    required this.from,
    required this.status,
    required this.onTap, // 👈 new line added
  });


@override
Widget build(BuildContext context) => GestureDetector(
      onTap: onTap, // 👈 use callback instead of _showEtaDetailsPopup(context)

      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stop,
                          style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(status,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white70)),
                    ],
                  ),
                  const Icon(Icons.directions_bus,
                      color: Colors.white, size: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );

}

// ---------------- DATA MODELS ----------------
class BusInfo {
  final String docId, busId, name, assignedTo;
  final List<String> features;
  BusInfo({
    required this.docId,
    required this.busId,
    required this.name,
    required this.assignedTo,
    required this.features,
  });
}

class StopData {
  final String name;
  final double lat, lng;
  final String time, busName;
  StopData({
    required this.name,
    required this.lat,
    required this.lng,
    required this.time,
    required this.busName,
  });
}

// ---------------- FLOATING BUS MARKER ----------------
class _FloatingBusMarker extends StatefulWidget {
  final String busName;
  final Color color;
  const _FloatingBusMarker({required this.busName, required this.color});

  @override
  State<_FloatingBusMarker> createState() => _FloatingBusMarkerState();
}

class _FloatingBusMarkerState extends State<_FloatingBusMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: -6)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Transform.translate(
          offset: Offset(0, _anim.value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  widget.busName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.directions_bus,
                    color: widget.color, size: 30),
              ),
            ],
          ),
        );
      },
    );
  }
}
