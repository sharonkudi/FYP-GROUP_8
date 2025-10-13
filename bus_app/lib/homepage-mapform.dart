// lib/homepage-mapform.dart
import 'dart:async';
import 'dart:ui';

import 'package:bus_app/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:open_route_service/open_route_service.dart';
// 🔸 Localization
import 'package:bus_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

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
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 10),
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
      final from =
          _firebaseStops.firstWhere((s) => s.name == _selectedFromStop);
      final to = _firebaseStops.firstWhere((s) => s.name == _selectedToStop);

      if (from.busName == to.busName) {
        await _drawSingleRoute(from, to);
      } else {
        await _drawTransitRoute(from, to);
      }

      _startEtaTimer(from.busName, to.lat, to.lng, to.name);
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
        (s) =>
            s.name.toLowerCase().contains("kianggeh") &&
            s.busName.contains("Bus A"),
      );
      final yayasanB = _firebaseStops.firstWhere(
        (s) =>
            s.name.toLowerCase().contains("yayasan") &&
            s.busName.contains("Bus B"),
      );

      // Determine direction
      final isAToB =
          from.busName.contains("Bus A") && to.busName.contains("Bus B");
      final isBToA =
          from.busName.contains("Bus B") && to.busName.contains("Bus A");

      List<LatLng> seg1 = [];
      List<LatLng> seg3 = [];
      List<LatLng> walkSeg = [];

      if (isAToB) {
        final r1 = await ors.directionsRouteCoordsGet(
          startCoordinate:
              ORSCoordinate(latitude: from.lat, longitude: from.lng),
          endCoordinate:
              ORSCoordinate(latitude: kianggehA.lat, longitude: kianggehA.lng),
        );

        final r2 = await ors.directionsRouteCoordsGet(
          startCoordinate:
              ORSCoordinate(latitude: yayasanB.lat, longitude: yayasanB.lng),
          endCoordinate: ORSCoordinate(latitude: to.lat, longitude: to.lng),
        );

        seg1 = r1.map((c) => LatLng(c.latitude, c.longitude)).toList();
        seg3 = r2.map((c) => LatLng(c.latitude, c.longitude)).toList();
        walkSeg = [
          LatLng(kianggehA.lat, kianggehA.lng),
          LatLng(yayasanB.lat, yayasanB.lng),
        ];

        debugPrint(
            "Transit A→B: A:${seg1.length} | Walk:${walkSeg.length} | B:${seg3.length}");
      } else if (isBToA) {
        final r1 = await ors.directionsRouteCoordsGet(
          startCoordinate:
              ORSCoordinate(latitude: from.lat, longitude: from.lng),
          endCoordinate:
              ORSCoordinate(latitude: yayasanB.lat, longitude: yayasanB.lng),
        );

        final r2 = await ors.directionsRouteCoordsGet(
          startCoordinate:
              ORSCoordinate(latitude: kianggehA.lat, longitude: kianggehA.lng),
          endCoordinate: ORSCoordinate(latitude: to.lat, longitude: to.lng),
        );

        seg1 = r1.map((c) => LatLng(c.latitude, c.longitude)).toList();
        seg3 = r2.map((c) => LatLng(c.latitude, c.longitude)).toList();
        walkSeg = [
          LatLng(yayasanB.lat, yayasanB.lng),
          LatLng(kianggehA.lat, kianggehA.lng),
        ];

        debugPrint(
            "Transit B→A: B:${seg1.length} | Walk:${walkSeg.length} | A:${seg3.length}");
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
              context,
              "Bus A (BUS001)",
              "Bus B (BUS002)",
              AppLocalizations.of(context)!.routeKianggehYayasan,
            );
          } else {
            _showTransitPopup(
              context,
              "Bus B (BUS002)",
              "Bus A (BUS001)",
              AppLocalizations.of(context)!.routeYayasanKianggeh,
            );
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
              Text(
                info.name,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                "${AppLocalizations.of(context)!.driver}: ${info.assignedTo}",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.features,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
                        const Text(
                          "• ",
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        Expanded(
                          child: Text(
                            f,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black87),
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
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  child: Text(
                    AppLocalizations.of(context)!.close,
                    style: const TextStyle(color: Colors.white),
                  ),
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
        title: Text(
          stop.name,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        content: Text(
          "${AppLocalizations.of(context)!.bus}: ${stop.busName}\n${AppLocalizations.of(context)!.scheduledTime}: ${stop.time}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

// ---------------- ETA INFO POPUP WHEN TAP ----------------
  void _showEtaDetailsPopup(BuildContext context) {
  if (_etaFromStop == null || _etaStopName == null) return;

  final busInfo = _busInfo.values.firstWhere(
    (b) => b.name == _etaFromStop,
    orElse: () => BusInfo(
      docId: "",
      busId: "",
      name: _etaFromStop ?? "",
      assignedTo: AppLocalizations.of(context)!.unknown,
      features: [],
    ),
  );

  // 🔹 Get correct next stop from Firestore (_firebaseStops)
  final nextStop = _firebaseStops.firstWhere(
  (s) => s.name == _etaStopName && s.busName == _etaFromStop,

    orElse: () => StopData(
      name: _etaStopName ?? "",
      lat: 0,
      lng: 0,
      time: "N/A",
      busName: _etaFromStop ?? "",
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
            // 🔸 Bus title
            Text(
              busInfo.name,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.indigo,
                  ),
            ),
            const SizedBox(height: 6),

            // 🔸 Driver
            Text(
              "${AppLocalizations.of(context)!.driver}: ${busInfo.assignedTo}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),

            // 🔸 Bus features
            Text(
              AppLocalizations.of(context)!.busFeatures,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            ...busInfo.features.map((f) => Text("• $f")),
            const Divider(height: 20, color: Colors.black26),

            // 🔸 Firestore-based next stop & schedule
            Text(
              "Next Stop: ${nextStop.name}",
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "Scheduled Time: ${nextStop.time.isNotEmpty ? nextStop.time : 'N/A'}",
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 10),

            // 🔸 ETA status (live)
            Text(
              "Status: $_etaStatus",
              style: const TextStyle(fontSize: 15, color: Colors.deepPurple),
            ),

            const SizedBox(height: 15),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                child: Text(
                  AppLocalizations.of(context)!.close,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


void _startEtaTimer(
    String busName, double stopLat, double stopLng, String userDestination) {
  _etaTimer?.cancel();

  _etaTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
    final busId = busName.contains("A") ? "BUS001" : "BUS002";
    final busPos = _busPositions[busId];
    if (busPos == null) return;

    // 🔹 Get Firestore schedule for this bus
    final busDoc = await _firestore
        .collection('buses')
        .where('bus_id', isEqualTo: busId)
        .get();
    if (busDoc.docs.isEmpty) return;

    final busData = busDoc.docs.first.data();
    final stops = List<Map<String, dynamic>>.from(busData['stops']);
    if (stops.isEmpty) return;

    final distanceCalc = const Distance();

    // 🔹 Find which stop the bus is closest to right now
    int nearestIndex = 0;
    double nearestDist = double.infinity;
    for (int i = 0; i < stops.length; i++) {
      final d = distanceCalc.as(
        LengthUnit.Meter,
        busPos,
        LatLng(stops[i]['lat'], stops[i]['lng']),
      );
      if (d < nearestDist) {
        nearestDist = d;
        nearestIndex = i;
      }
    }

    final currentStop = stops[nearestIndex];
    final nextStopIndex =
        (nearestIndex + 1 < stops.length) ? nearestIndex + 1 : 0;
    final nextStop = stops[nextStopIndex];

    // 🔹 Calculate distance and ETA
    final distToCurrent = distanceCalc.as(
      LengthUnit.Meter,
      busPos,
      LatLng(currentStop['lat'], currentStop['lng']),
    );
    final distToNext = distanceCalc.as(
      LengthUnit.Meter,
      busPos,
      LatLng(nextStop['lat'], nextStop['lng']),
    );

    const avgSpeed = 7.0; // m/s ≈ 25 km/h
    double etaNextMin = (distToNext / (avgSpeed * 60)).clamp(0.1, 60.0);

    // 🕒 Delay logic — simulate staying 1 min at the stop
    // If bus is very close (<40m), hold eta at 0.1min for ~1 min before updating
    bool isAtStop = distToCurrent < 40;
    String status;
    String displayStop;

    if (isAtStop) {
      // ✅ Still at stop — hold ETA near 0.1
      etaNextMin = 0.1;
      status =
          "🟢 Arrived at ${currentStop['name']} (~${etaNextMin.toStringAsFixed(1)} min)";
      displayStop = nextStop['name'];
    } else if (etaNextMin <= 1.5) {
      status =
          "🟡 Arriving soon at ${nextStop['name']} (~${etaNextMin.toStringAsFixed(1)} min)";
      displayStop = nextStop['name'];
    } else {
      status =
          "🕓 En route to ${nextStop['name']} (~${etaNextMin.toStringAsFixed(1)} min)";
      displayStop = nextStop['name'];
    }

    // 🔹 Update the live ETA card
    if (mounted) {
      setState(() {
        _etaFromStop = busName;
        _etaStopName = displayStop;
        _etaStatus = status;
      });
    }
  });
}


  // ---------------- TRANSIT POPUP ----------------
  void _showTransitPopup(
      BuildContext context, String fromBus, String toBus, String stop) {
    final loc = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context, listen: false);

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.transfer_within_a_station,
                  color: Colors.deepPurple,
                  size: settings.iconSize * 1.5, // scalable icon
                ),
                SizedBox(height: settings.fontSize * 0.6),
                Text(
                  loc.transitRequired, // localized
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: settings.fontSize * 1.2,
                    color: Colors.deepPurple,
                  ),
                ),
                SizedBox(height: settings.fontSize * 0.4),
                Text(
                  loc.transitDescription(stop), // localized with placeholder
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: settings.fontSize,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: settings.fontSize * 0.6),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: Text(
                    loc.close, // localized
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: settings.fontSize,
                    ),
                  ),
                ),
              ],
            ),
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
                child: const Icon(Icons.directions_bus,
                    color: Colors.white, size: 22),
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
            TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
            PolylineLayer(polylines: [
              Polyline(
                  points: _routeA, color: Colors.deepPurple, strokeWidth: 5),
              Polyline(
                  points: _walkLine,
                  color: Colors.orange,
                  strokeWidth: 3,
                  isDotted: true),
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
    final loc = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context);
    final double fontSize = settings.fontSize; // if your provider uses fontSize

    return Container(
      color: const Color(0xFF0B1B4D),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Expanded(
          child: DropdownButton<String>(
            value: _selectedFromStop,
            dropdownColor: const Color(0xFF0B1B4D),
            hint: Text(
              AppLocalizations.of(context)!.from,
              style: TextStyle(
                color: Colors.white,
                fontSize: Provider.of<SettingsProvider>(context).fontSize,
              ),
            ),
            style: TextStyle(
              color: Colors.white,
              fontSize: Provider.of<SettingsProvider>(context).fontSize,
            ),
            isExpanded: true,
            items: stops
                .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                .toList(),
            onChanged: (v) => setState(() => _selectedFromStop = v),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButton<String>(
            value: _selectedToStop,
            dropdownColor: const Color(0xFF0B1B4D),
            hint: Text(
              AppLocalizations.of(context)!.to,
              style: TextStyle(
                color: Colors.white,
                fontSize: Provider.of<SettingsProvider>(context).font,
              ),
            ),
            style: TextStyle(
              color: Colors.white,
              fontSize: Provider.of<SettingsProvider>(context).font,
            ),
            isExpanded: true,
            items: stops
                .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                .toList(),
            onChanged: (v) => setState(() => _selectedToStop = v),
          ),
        ),
        IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _generateDropdownRoute)
      ]),
    );
  }
}

// ---------------- ETA CARD ----------------
class _EtaCard extends StatelessWidget {
  final String stop, from, status;
  final VoidCallback onTap;

  const _EtaCard({
    required this.stop,
    required this.from,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Next Stop: $stop",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.directions_bus,
                        color: Colors.white, size: 30),
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
    final settings = Provider.of<SettingsProvider>(context);
    final loc = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Transform.translate(
          offset: Offset(0, _anim.value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bus name container
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  widget.busName, // localize: loc.busName(widget.busName)
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: settings.fontSize * 0.9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: settings.fontSize * 0.4),

              // Bus icon container
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
                padding: EdgeInsets.all(settings.iconSize * 0.4),
                child: Icon(
                  Icons.directions_bus,
                  color: widget.color,
                  size: settings.iconSize,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
