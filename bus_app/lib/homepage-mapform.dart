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
  List<LatLng> _routePoints = [];

  String? _selectedFromStop;
  String? _selectedToStop;
  String? _transitStop;

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
      final stops = <StopData>[];

      for (final doc in snap.docs) {
        final data = doc.data();
        final busId = data['bus_id']?.toString() ?? doc.id;

        info[busId] = BusInfo(
          docId: doc.id,
          busId: busId,
          name: data['bus_name']?.toString() ?? 'Bus $busId',
          assignedTo: data['assignedTo']?.toString() ?? '',
        );

        if (data['stops'] is List) {
          for (final stop in data['stops']) {
            if (stop is Map) {
              stops.add(StopData(
                name: stop['name'] ?? 'Stop',
                lat: (stop['lat'] ?? 0).toDouble(),
                lng: (stop['lng'] ?? 0).toDouble(),
                time: stop['time'] ?? '',
                busName: data['bus_name'] ?? 'Unknown Bus',
              ));
            }
          }
        }
      }

      setState(() {
        _busInfo = info;
        // 🧭 sort stops by bus then time for proper numbering
        _firebaseStops = List.from(stops)
          ..sort((a, b) {
            final nameComp = a.busName.compareTo(b.busName);
            if (nameComp != 0) return nameComp;
            return a.time.compareTo(b.time);
          });
      });
    });
  }

  void _listenRealtimeGps() {
    _rtdb.onValue.listen((event) {
      final value = event.snapshot.value;
      final updated = <String, LatLng>{};

      if (value is Map) {
        final mapVal = Map<String, dynamic>.from(value);

        void readBus(String key, String id) {
          if (mapVal[key] != null) {
            final gps = Map<String, dynamic>.from(mapVal[key]);
            final lat = _toDouble(gps['latitude']);
            final lng = _toDouble(gps['longitude']);
            if (lat != null && lng != null) {
              updated[id] = LatLng(lat, lng);
            }
          }
        }

        readBus('gpsData', 'BUS001');
        readBus('gpsData2', 'BUS002');
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

    final from = _firebaseStops.firstWhere(
      (s) => s.name == _selectedFromStop,
      orElse: () => _firebaseStops.first,
    );
    final to = _firebaseStops.firstWhere(
      (s) => s.name == _selectedToStop,
      orElse: () => _firebaseStops.last,
    );

    // if different bus -> transit popup
    if (from.busName != to.busName) {
      _transitStop = from.name;
      _showTransitPopup(context, from.busName, to.busName, from.name);
      return;
    } else {
      _transitStop = null;
    }

    try {
      final client = OpenRouteService(
        apiKey:
            'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjU4YzVjYzVkZWZiZDRlN2NhM2VhMDI5Mjg3NWViNmFhIiwiaCI6Im11cm11cjY0In0=',
      );
      final coords = await client.directionsRouteCoordsGet(
        startCoordinate:
            ORSCoordinate(latitude: from.lat, longitude: from.lng),
        endCoordinate: ORSCoordinate(latitude: to.lat, longitude: to.lng),
      );
      setState(() {
        _routePoints =
            coords.map((c) => LatLng(c.latitude, c.longitude)).toList();
      });
    } catch (e) {
      debugPrint('Route error: $e');
    }
  }

  void _showTransitPopup(
      BuildContext context, String fromBus, String toBus, String dropOffStop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.38,
          minChildSize: 0.25,
          maxChildSize: 0.6,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Icon(Icons.transfer_within_a_station,
                            size: 46, color: Colors.deepPurple),
                        const SizedBox(height: 14),
                        Text(
                          'Transit Required',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple[900],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Drop off at $dropOffStop from $fromBus and transfer to $toBus.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.attach_money, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'Extra fare: BND 1.00',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          icon:
                              const Icon(Icons.route, color: Colors.white),
                          label: const Text(
                            'View Route',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final busMarkers = <Marker>[];

    _busPositions.forEach((busId, pos) {
      final info = _busInfo[busId];
      final busName = info?.name ?? 'Bus';
      final chipColor = busName.toLowerCase().contains('a')
          ? Colors.redAccent
          : Colors.blueAccent;

      busMarkers.add(Marker(
        width: 100,
        height: 100,
        point: pos,
        child: _FloatingBusMarker(busName: busName, color: chipColor),
      ));
    });

    // 🟦 stop markers (orange if transit)
    final stopMarkers = _firebaseStops.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final stop = entry.value;
      final isTransit = stop.name == _transitStop;

      return Marker(
        width: 42,
        height: 42,
        point: LatLng(stop.lat, stop.lng),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isTransit ? Colors.orangeAccent : Colors.blueAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            Text(
              '$index',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
          ],
        ),
      );
    }).toList();

    final deviceMarker = _devicePosition != null
        ? Marker(
            width: 40,
            height: 40,
            point: _devicePosition!,
            child: const Icon(Icons.person_pin_circle,
                color: Colors.green, size: 36),
          )
        : null;

    final initialCenter = _busPositions.isNotEmpty
        ? _busPositions.values.first
        : (_devicePosition ??
            (_firebaseStops.isNotEmpty
                ? LatLng(_firebaseStops.first.lat, _firebaseStops.first.lng)
                : const LatLng(4.9, 114.9)));

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
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.bus_app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.deepPurple,
                      strokeWidth: 5,
                    )
                  ],
                ),
                MarkerLayer(
                  markers: [
                    ...stopMarkers,
                    ...busMarkers,
                    if (deviceMarker != null) deviceMarker,
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
    final stopNames = _firebaseStops.map((s) => s.name).toSet().toList();

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
              items: stopNames.map((n) {
                return DropdownMenuItem(value: n, child: Text(n));
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedFromStop = val);
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
              items: stopNames.map((n) {
                return DropdownMenuItem(value: n, child: Text(n));
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedToStop = val);
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
}

// ===========================================================
// DATA CLASSES + FLOATING BUS MARKER
// ===========================================================

class BusInfo {
  final String docId;
  final String busId;
  final String name;
  final String assignedTo;

  BusInfo({
    required this.docId,
    required this.busId,
    required this.name,
    required this.assignedTo,
  });
}

class StopData {
  final String name;
  final double lat;
  final double lng;
  final String time;
  final String busName;

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
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _animation =
        Tween<double>(begin: 0, end: -6).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
