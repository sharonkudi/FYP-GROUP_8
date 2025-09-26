import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:open_route_service/open_route_service.dart';
import 'data/stops.dart';

class MapFormPage extends StatefulWidget {
  const MapFormPage({super.key});

  @override
  // Change this line from _MapFormPageState to MapPageState
  MapPageState createState() => MapPageState();
}

// Change this class name from _MapFormPageState to MapPageState
// and remove the underscore to make it public
class MapPageState extends State<MapFormPage> {
  final mapController = MapController();
  final DatabaseReference _rootRef = FirebaseDatabase.instance.ref();
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
    _rtdbOneTimeCheck();
    _initDeviceGps();
  }

  void _initDeviceGps() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied');
      return;
    }
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (position != null) {
        final currentLatLng = LatLng(position.latitude, position.longitude);
        debugPrint('Device GPS Location updated: $currentLatLng');
        setState(() {
          _devicePosition = currentLatLng;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            mapController.move(currentLatLng, mapController.zoom);
          } catch (e) {
            debugPrint('Map move error: $e');
          }
        });
      }
    });
  }

  void _listenFirestoreBuses() {
    _firestore.collection('buses').snapshots().listen((snap) {
      final info = <String, BusInfo>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final busId = data['bus_id']?.toString() ?? doc.id;
        final name = data['bus_name']?.toString() ?? 'Bus $busId';
        final route = data['route']?.toString() ?? '';
        final schedule = data['time']?.toString() ?? '';
        final assignedTo = data['assignedTo']?.toString() ?? '';
        info[busId] = BusInfo(
          docId: doc.id,
          busId: busId,
          name: name,
          route: route,
          schedule: schedule,
          assignedTo: assignedTo,
        );
      }
      setState(() => _busInfo = info);
      debugPrint('Loaded buses from Firestore: ${_busInfo.keys.toList()}');
    }, onError: (e) {
      debugPrint('Firestore listen error: $e');
    });
  }

  void _listenRealtimeGps() {
    _rootRef.onValue.listen((event) {
      final value = event.snapshot.value;
      final updatedPositions = <String, LatLng>{};
      if (value == null) {
        debugPrint('RTDB: snapshot value is null');
      } else if (value is Map) {
        final mapVal = Map<String, dynamic>.from(value);

        if (mapVal.containsKey('gpsData')) {
          try {
            final gpsRaw = mapVal['gpsData'];
            if (gpsRaw is Map) {
              final gpsMap = Map<String, dynamic>.from(gpsRaw);
              final lat =
                  _toDouble(gpsMap['latitude']) ?? _toDouble(gpsMap['lat']);
              final lng =
                  _toDouble(gpsMap['longitude']) ?? _toDouble(gpsMap['lng']);
              if (lat != null && lng != null)
                updatedPositions['tracker'] = LatLng(lat, lng);
            }
          } catch (e) {
            debugPrint('Error parsing root gpsData: $e');
          }
        }

        if (mapVal.containsKey('buses_gps')) {
          final busesRaw = mapVal['buses_gps'];
          if (busesRaw is Map) {
            busesRaw.forEach((busId, busData) {
              try {
                final busMap =
                    busData is Map ? Map<String, dynamic>.from(busData) : {};
                if (busMap.containsKey('gpsData')) {
                  final gpsRaw = busMap['gpsData'];
                  if (gpsRaw is Map) {
                    final gpsMap = Map<String, dynamic>.from(gpsRaw);
                    final lat = _toDouble(gpsMap['latitude']) ??
                        _toDouble(gpsMap['lat']);
                    final lng = _toDouble(gpsMap['longitude']) ??
                        _toDouble(gpsMap['lng']);
                    if (lat != null && lng != null)
                      updatedPositions[busId.toString()] = LatLng(lat, lng);
                  }
                } else {
                  final lat =
                      _toDouble(busMap['latitude']) ?? _toDouble(busMap['lat']);
                  final lng = _toDouble(busMap['longitude']) ??
                      _toDouble(busMap['lng']);
                  if (lat != null && lng != null)
                    updatedPositions[busId.toString()] = LatLng(lat, lng);
                }
              } catch (e) {
                debugPrint('Error parsing bus $busId: $e');
              }
            });
          }
        }

        if (updatedPositions.isEmpty) {
          mapVal.forEach((key, node) {
            try {
              if (node is Map) {
                final nodeMap = Map<String, dynamic>.from(node);
                if (nodeMap.containsKey('gpsData')) {
                  final gpsRaw = nodeMap['gpsData'];
                  if (gpsRaw is Map) {
                    final lat = _toDouble(gpsRaw['latitude']) ??
                        _toDouble(gpsRaw['lat']);
                    final lng = _toDouble(gpsRaw['longitude']) ??
                        _toDouble(gpsRaw['lng']);
                    if (lat != null && lng != null)
                      updatedPositions[key.toString()] = LatLng(lat, lng);
                  }
                } else {
                  final lat = _toDouble(nodeMap['latitude']) ??
                      _toDouble(nodeMap['lat']);
                  final lng = _toDouble(nodeMap['longitude']) ??
                      _toDouble(nodeMap['lng']);
                  if (lat != null && lng != null)
                    updatedPositions[key.toString()] = LatLng(lat, lng);
                }
              }
            } catch (e) {
              debugPrint('Error parsing top-level key $key: $e');
            }
          });
        }
      } else {
        debugPrint('RTDB: unexpected snapshot type: ${value.runtimeType}');
      }

      debugPrint('Updated positions: $updatedPositions');

      setState(() {
        _busPositions = updatedPositions;
      });

      if (_busPositions.isNotEmpty) {
        final first = _busPositions.values.first;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            mapController.move(first, mapController.zoom);
          } catch (e) {
            debugPrint('Map move error: $e');
          }
        });
      }
    }, onError: (err) {
      debugPrint('RTDB listen error: $err');
    });
  }

  Future<void> _rtdbOneTimeCheck() async {
    try {
      final snap =
          await FirebaseDatabase.instance.ref().child('buses_gps').get();
      debugPrint('RTDB one-time read (buses_gps): ${snap.value}');
      final rootSnap =
          await FirebaseDatabase.instance.ref().child('gpsData').get();
      debugPrint('RTDB one-time read (gpsData): ${rootSnap.value}');
    } catch (e) {
      debugPrint('RTDB one-time read error: $e');
    }
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  // Helper to clear routes before drawing a new one
  void _clearRoute() {
    setState(() {
      _routePoints = [];
    });
  }

  // Dropdown route generator (stop-to-stop)
  Future<void> _generateDropdownRoute() async {
    if (_selectedFromStop == null || _selectedToStop == null) {
      _clearRoute();
      return;
    }
    final from = StopData.coords[_selectedFromStop!]!;
    final to = StopData.coords[_selectedToStop!]!;
    try {
      final OpenRouteService client = OpenRouteService(
        apiKey:
            'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjU4YzVjYzVkZWZiZDRlN2NhM2VhMDI5Mjg3NWViNmFhIiwiaCI6Im11cm11cjY0In0=', // <-- Put your ORS API key here
      );
      final List<ORSCoordinate> routeCoordinates =
          await client.directionsRouteCoordsGet(
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
        _routePoints = routeCoordinates
            .map((c) => LatLng(c.latitude, c.longitude))
            .toList();
      });
    } catch (e) {
      debugPrint('Dropdown route error: $e');
    }
  }

  // Marker tap route handler
  Future<void> _handleStopTap(LatLng stopLatLng) async {
    if (_selectedFromStop != null && _selectedToStop != null) {
      await _generateDropdownRoute();
      return;
    }
    if (_devicePosition == null) return;
    try {
      final OpenRouteService client = OpenRouteService(
        apiKey:
            'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjU4YzVjYzVkZWZiZDRlN2NhM2VhMDI5Mjg3NWViNmFhIiwiaCI6Im11cm11cjY0In0=',
      );
      final List<ORSCoordinate> routeCoordinates =
          await client.directionsRouteCoordsGet(
        startCoordinate: ORSCoordinate(
          latitude: _devicePosition!.latitude,
          longitude: _devicePosition!.longitude,
        ),
        endCoordinate: ORSCoordinate(
          latitude: stopLatLng.latitude,
          longitude: stopLatLng.longitude,
        ),
      );
      setState(() {
        _routePoints = routeCoordinates
            .map((c) => LatLng(c.latitude, c.longitude))
            .toList();
      });
    } catch (e) {
      debugPrint('Route fetch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stopMarkers = <Marker>[
      for (int i = 0; i < StopData.names.length; i++)
        Marker(
          width: 44,
          height: 44,
          point: StopData.coords[StopData.names[i]]!,
          child: GestureDetector(
            onTap: () => _handleStopTap(
              StopData.coords[StopData.names[i]]!,
            ),
            child: _BlueStopMarker(number: i + 1),
          ),
        ),
    ];

    final busMarkers = <Marker>[];
    _busPositions.forEach((busId, pos) {
      final info = _busInfo[busId];
      busMarkers.add(Marker(
        width: 100,
        height: 100,
        point: pos,
        child: GestureDetector(
          onTap: () => _showBusDetails(context, busId),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (info != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    info.name,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 4),
              const Icon(Icons.directions_bus, color: Colors.red, size: 36),
            ],
          ),
        ),
      ));
    });

    final deviceMarker = _devicePosition != null
        ? Marker(
            width: 40,
            height: 40,
            point: _devicePosition!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.person_pin_circle,
                  color: Colors.white, size: 32),
            ),
          )
        : null;

    final initialCenter = _busPositions.isNotEmpty
        ? _busPositions.values.first
        : (_devicePosition ?? StopData.coords.values.first);

    final bottomForm = Container(
      color: const Color(0xFF0B1B4D),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: _selectedFromStop,
              dropdownColor: const Color(0xFF0B1B4D),
              hint: const Text(
                "From",
                style: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: Colors.white,
              isExpanded: true,
              items: StopData.names.map((name) {
                return DropdownMenuItem(
                  value: name,
                  child: Row(
                    children: [
                      const Icon(Icons.directions_bus, color: Colors.white),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(name, style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedFromStop = val;
                });
                _generateDropdownRoute();
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedToStop,
              dropdownColor: const Color(0xFF0B1B4D),
              hint: const Text(
                "To",
                style: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: Colors.white,
              isExpanded: true,
              items: StopData.names.map((name) {
                return DropdownMenuItem(
                  value: name,
                  child: Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.white),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(name, style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedToStop = val;
                });
                _generateDropdownRoute();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _generateDropdownRoute,
          ),
        ],
      ),
    );

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 13.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.bus_app',
                ),
                MarkerLayer(
                  markers: stopMarkers +
                      busMarkers +
                      (deviceMarker != null ? [deviceMarker] : []),
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              ],
            ),
          ),
          bottomForm,
        ],
      ),
    );
  }

  void _showBusDetails(BuildContext context, String busId) {
    final info = _busInfo[busId];
    final pos = _busPositions[busId];
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: info == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Bus ID: $busId',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('No metadata found in Firestore for this bus.'),
                      if (pos != null)
                        Text(
                            'Position: ${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}'),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(info.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Bus ID: ${info.busId}'),
                      if (info.assignedTo.isNotEmpty)
                        Text('Driver: ${info.assignedTo}'),
                      const SizedBox(height: 8),
                      if (info.route.isNotEmpty) Text('Route: ${info.route}'),
                      const SizedBox(height: 8),
                      if (info.schedule.isNotEmpty) ...[
                        const Text('Schedule:',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(info.schedule),
                      ],
                      const SizedBox(height: 8),
                      if (pos != null)
                        Text(
                            'Live: ${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}'),
                    ],
                  ),
          ),
        );
      },
    );
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
          child:
              const Icon(Icons.directions_bus, color: Colors.white, size: 20),
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
