import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    _listenFirestoreBuses();
    _listenRealtimeGps();
    _rtdbOneTimeCheck();
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

        // root -> gpsData -> {latitude, longitude}
        if (mapVal.containsKey('gpsData')) {
          try {
            final gpsRaw = mapVal['gpsData'];
            if (gpsRaw is Map) {
              final gpsMap = Map<String, dynamic>.from(gpsRaw);
              final lat = _toDouble(gpsMap['latitude']) ?? _toDouble(gpsMap['lat']);
              final lng = _toDouble(gpsMap['longitude']) ?? _toDouble(gpsMap['lng']);
              if (lat != null && lng != null) updatedPositions['tracker'] = LatLng(lat, lng);
            }
          } catch (e) {
            debugPrint('Error parsing root gpsData: $e');
          }
        }

        // root -> buses_gps -> { busId -> (gpsData|latitude,longitude) }
        if (mapVal.containsKey('buses_gps')) {
          final busesRaw = mapVal['buses_gps'];
          if (busesRaw is Map) {
            busesRaw.forEach((busId, busData) {
              try {
                final busMap = busData is Map ? Map<String, dynamic>.from(busData) : {};
                if (busMap.containsKey('gpsData')) {
                  final gpsRaw = busMap['gpsData'];
                  if (gpsRaw is Map) {
                    final gpsMap = Map<String, dynamic>.from(gpsRaw);
                    final lat = _toDouble(gpsMap['latitude']) ?? _toDouble(gpsMap['lat']);
                    final lng = _toDouble(gpsMap['longitude']) ?? _toDouble(gpsMap['lng']);
                    if (lat != null && lng != null) updatedPositions[busId.toString()] = LatLng(lat, lng);
                  }
                } else {
                  final lat = _toDouble(busMap['latitude']) ?? _toDouble(busMap['lat']);
                  final lng = _toDouble(busMap['longitude']) ?? _toDouble(busMap['lng']);
                  if (lat != null && lng != null) updatedPositions[busId.toString()] = LatLng(lat, lng);
                }
              } catch (e) {
                debugPrint('Error parsing bus $busId: $e');
              }
            });
          }
        }

        // top-level keys are bus ids
        if (updatedPositions.isEmpty) {
          mapVal.forEach((key, node) {
            try {
              if (node is Map) {
                final nodeMap = Map<String, dynamic>.from(node);
                if (nodeMap.containsKey('gpsData')) {
                  final gpsRaw = nodeMap['gpsData'];
                  if (gpsRaw is Map) {
                    final lat = _toDouble(gpsRaw['latitude']) ?? _toDouble(gpsRaw['lat']);
                    final lng = _toDouble(gpsRaw['longitude']) ?? _toDouble(gpsRaw['lng']);
                    if (lat != null && lng != null) updatedPositions[key.toString()] = LatLng(lat, lng);
                  }
                } else {
                  final lat = _toDouble(nodeMap['latitude']) ?? _toDouble(nodeMap['lat']);
                  final lng = _toDouble(nodeMap['longitude']) ?? _toDouble(nodeMap['lng']);
                  if (lat != null && lng != null) updatedPositions[key.toString()] = LatLng(lat, lng);
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
      final snap = await FirebaseDatabase.instance.ref().child('buses_gps').get();
      debugPrint('RTDB one-time read (buses_gps): ${snap.value}');
      final rootSnap = await FirebaseDatabase.instance.ref().child('gpsData').get();
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

  @override
  Widget build(BuildContext context) {
    final stopMarkers = <Marker>[
      for (int i = 0; i < StopData.names.length; i++)
        Marker(
          width: 44,
          height: 44,
          point: StopData.coords[StopData.names[i]]!,
          child: _BlueStopMarker(number: i + 1),
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    info.name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 4),
              const Icon(Icons.directions_bus, color: Colors.red, size: 36),
            ],
          ),
        ),
      ));
    });

    final initialCenter = _busPositions.isNotEmpty ? _busPositions.values.first : StopData.coords.values.first;

    return Scaffold(
      body: FlutterMap(
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
          MarkerLayer(markers: stopMarkers + busMarkers),
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
                      Text('Bus ID: $busId', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('No metadata found in Firestore for this bus.'),
                      if (pos != null) Text('Position: ${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}'),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(info.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Bus ID: ${info.busId}'),
                      if (info.assignedTo.isNotEmpty) Text('Driver: ${info.assignedTo}'),
                      const SizedBox(height: 8),
                      if (info.route.isNotEmpty) Text('Route: ${info.route}'),
                      const SizedBox(height: 8),
                      if (info.schedule.isNotEmpty) ...[
                        const Text('Schedule:', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(info.schedule),
                      ],
                      const SizedBox(height: 8),
                      if (pos != null) Text('Live: ${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}'),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // Add these public methods that are being called from home.dart
  void clearRoute() {
    // Add implementation
  }

  void showRouteBetween(String from, String to) {
    // Add implementation
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
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}