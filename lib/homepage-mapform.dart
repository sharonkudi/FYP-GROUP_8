// lib/homepage-mapform.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:open_route_service/open_route_service.dart';
import 'data/stops.dart';
import 'package:bus_app/l10n/app_localizations.dart';

class MapFormPage extends StatefulWidget {
  final String? focusBusId; // optional bus to focus
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
  LatLng? _devicePosition;
  List<LatLng> _routePoints = [];

  String? _selectedFromStop;
  String? _selectedToStop;

  @override
  void initState() {
    super.initState();
    _listenFirestoreBuses();
    _listenRealtimeGps();
    _initDeviceGps();
  }

  void _initDeviceGps() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      final currentLatLng = LatLng(position.latitude, position.longitude);
      setState(() => _devicePosition = currentLatLng);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          mapController.move(currentLatLng, mapController.camera.zoom);
        } catch (_) {}
      });
    });
  }

  void _listenFirestoreBuses() {
    _firestore.collection('buses').snapshots().listen((snap) {
      final info = <String, BusInfo>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final busId = data['bus_id']?.toString() ?? doc.id;
        info[busId] = BusInfo(
          docId: doc.id,
          busId: busId,
          name: data['bus_name']?.toString() ?? 'Bus $busId',
          route: data['route']?.toString() ?? '',
          schedule: data['time']?.toString() ?? '',
          assignedTo: data['assignedTo']?.toString() ?? '',
        );
      }
      setState(() => _busInfo = info);
    });
  }

  void _listenRealtimeGps() {
    _rtdb.onValue.listen((event) {
      final value = event.snapshot.value;
      final updated = <String, LatLng>{};

      if (value is Map) {
        final mapVal = Map<String, dynamic>.from(value);

        if (mapVal['gpsData'] != null) {
          final gps = Map<String, dynamic>.from(mapVal['gpsData']);
          final lat = _toDouble(gps['latitude']);
          final lng = _toDouble(gps['longitude']);
          if (lat != null && lng != null) {
            updated['BUS001'] = LatLng(lat, lng);
          }
        }

        if (mapVal['gpsData2'] != null) {
          final gps = Map<String, dynamic>.from(mapVal['gpsData2']);
          final lat = _toDouble(gps['latitude']);
          final lng = _toDouble(gps['longitude']);
          if (lat != null && lng != null) {
            updated['BUS002'] = LatLng(lat, lng);
          }
        }
      }

      setState(() => _busPositions = updated);
    });
  }

  static double? _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  void _clearRoute() => setState(() => _routePoints = []);

  Future<void> _generateDropdownRoute() async {
    if (_selectedFromStop == null || _selectedToStop == null) {
      _clearRoute();
      return;
    }
    final from = StopData.coords[_selectedFromStop!]!;
    final to = StopData.coords[_selectedToStop!]!;

    try {
      final client = OpenRouteService(
        apiKey: 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjU4YzVjYzVkZWZiZDRlN2NhM2VhMDI5Mjg3NWViNmFhIiwiaCI6Im11cm11cjY0In0=', // Replace with real ORS API key
      );
      final coords = await client.directionsRouteCoordsGet(
        startCoordinate: ORSCoordinate(
          latitude: from.latitude,
          longitude: from.longitude,
        ),
        endCoordinate: ORSCoordinate(
          latitude: to.latitude,
          longitude: to.longitude,
        ),
      );
      setState(() {
        _routePoints =
            coords.map((c) => LatLng(c.latitude, c.longitude)).toList();
      });
    } catch (e) {
      debugPrint('Route error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final busMarkers = <Marker>[];

    _busPositions.forEach((busId, pos) {
      final info = _busInfo[busId];
      busMarkers.add(Marker(
        width: 80,
        height: 80,
        point: pos,
        child: GestureDetector(
          onTap: () => _showBusDetails(context, busId, info, pos),
          child: const Icon(Icons.directions_bus, color: Colors.red, size: 36),
        ),
      ));
    });

    final stopMarkers = <Marker>[
      for (int i = 0; i < StopData.names.length; i++)
        Marker(
          width: 44,
          height: 44,
          point: StopData.coords[StopData.names[i]]!,
          child: _BlueStopMarker(number: i + 1),
        ),
    ];

    final deviceMarker = _devicePosition != null
        ? Marker(
            width: 40,
            height: 40,
            point: _devicePosition!,
            child: const Icon(Icons.person_pin_circle,
                color: Colors.blue, size: 36),
          )
        : null;

    final initialCenter = _busPositions.isNotEmpty
        ? _busPositions.values.first
        : (_devicePosition ?? StopData.coords.values.first);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.bus_app',
                ),
                MarkerLayer(
                  markers: [
                    ...stopMarkers,
                    ...busMarkers,
                    if (deviceMarker != null) deviceMarker,
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 5,
                    )
                  ],
                ),
              ],
            ),
          ),
          _buildBottomSearch(context),
        ],
      ),
    );
  }

  Widget _buildBottomSearch(BuildContext context) {
    return Container(
      color: const Color(0xFF0B1B4D),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: _selectedFromStop,
              dropdownColor: const Color(0xFF0B1B4D),
              hint: Text(AppLocalizations.of(context)!.from,
                  style: const TextStyle(color: Colors.white)),
              style: const TextStyle(color: Colors.white),
              isExpanded: true,
              items: StopData.names.map((n) {
                return DropdownMenuItem(value: n, child: Text(n));
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedFromStop = val);
                _generateDropdownRoute();
              },
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
              items: StopData.names.map((n) {
                return DropdownMenuItem(value: n, child: Text(n));
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedToStop = val);
                _generateDropdownRoute();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _generateDropdownRoute,
          )
        ],
      ),
    );
  }

  void _showBusDetails(BuildContext context, String busId, BusInfo? info, LatLng pos) {
  // Listen Firestore for this specific bus document
  final Stream<BusInfo?> busStream = _firestore
      .collection('buses')
      .doc(busId.toLowerCase()) // assuming docId matches busId in lowercase
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists || snapshot.data() == null) return null;
    final data = snapshot.data()!;
    return BusInfo(
      docId: snapshot.id,
      busId: data['bus_id']?.toString() ?? busId,
      name: data['bus_name']?.toString() ?? 'Bus $busId',
      route: data['route']?.toString() ?? '',
      schedule: data['time']?.toString() ?? '',
      assignedTo: data['assignedTo']?.toString() ?? '',
    );
  });

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: Colors.white,
    isScrollControlled: true,
    builder: (_) {
      return Padding(
        padding: EdgeInsets.only(
          top: 24,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: StreamBuilder<BusInfo?>(
          stream: busStream,
          builder: (context, snapshot) {
            final currentInfo = snapshot.data ?? info;
            return _BusInfoContent(busId: busId, info: currentInfo, pos: pos);
          },
        ),
      );
    },
  );
}


}

class _BusInfoContent extends StatelessWidget {
  final String busId;
  final BusInfo? info;
  final LatLng pos;

  const _BusInfoContent({
    Key? key,
    required this.busId,
    required this.info,
    required this.pos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (info == null) {
      // Minimal info view
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_bus, size: 40, color: Colors.red),
          const SizedBox(height: 12),
          Text("Bus $busId",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
              "Live: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}",
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          const Text("No additional information available.",
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: const Text("Close", style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      );
    }

    // Full info view
    final routeStops = info!.route.split(" > ");

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(info!.name,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue)),
                Text("Bus No: ${info!.busId}",
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 8),
            // Route
            Row(
              children: [
                const Icon(Icons.route, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(info!.route,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87)),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 0.6),
            // Schedule
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildScheduleList(info!.schedule),
            ),
            const Divider(height: 20, thickness: 0.6),
            // Driver info
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    info!.assignedTo.isNotEmpty
                        ? "Driver: ${info!.assignedTo}"
                        : "Driver: Unassigned",
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.my_location, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Live: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}",
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Back", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildScheduleList(String scheduleStr) {
    if (scheduleStr.isEmpty) return [];
    final schedule = scheduleStr
        .split(RegExp(r'\.\s*'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    return [
      const Text("Schedule:",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      ...schedule.map(
        (entry) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.green),
              const SizedBox(width: 6),
              Expanded(
                child: Text(entry,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.black87)),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}


class BusInfo {
  final String docId;
  final String busId;
  final String name;
  final String route;
  final String schedule;
  final String assignedTo;

  BusInfo({
    required this.docId,
    required this.busId,
    required this.name,
    required this.route,
    required this.schedule,
    required this.assignedTo,
  });
}

class _BlueStopMarker extends StatelessWidget {
  final int number;
  const _BlueStopMarker({required this.number});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFF1C6BE3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
        ),
        Positioned(
          bottom: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
