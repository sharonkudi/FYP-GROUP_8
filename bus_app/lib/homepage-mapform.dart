// lib/pages/map_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bus_app/data/stops.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    this.offlineMode = false, // ✅ add this
  });

  /// When true, we don’t fetch online tiles; we still render markers + offline route.
  final bool offlineMode; // ✅ add this

  @override
  State<MapPage> createState() => MapPageState(); // public state for GlobalKey
}

class MapPageState extends State<MapPage> {
  final mapController = MapController();

  final Map<String, LatLng> stops = StopData.coords;
  final List<String> stopNames = StopData.names;

  // Active route
  List<LatLng> _routePoints = [];
  Marker? _busMarker;

  int busIndex = 0;

  /// Public API (called from Home)
  void showRouteBetween(String from, String to) {
    final fromPt = stops[from];
    final toPt = stops[to];
    if (fromPt == null || toPt == null) return;

    // ✅ Generate 30 intermediate points for smooth animation
    final steps = 30;
    final latStep = (toPt.latitude - fromPt.latitude) / steps;
    final lngStep = (toPt.longitude - fromPt.longitude) / steps;

    _routePoints = List.generate(
      steps + 1,
      (i) => LatLng(
        fromPt.latitude + latStep * i,
        fromPt.longitude + lngStep * i,
      ),
    );

    busIndex = 0;
    _busMarker = Marker(
      width: 40,
      height: 40,
      point: fromPt,
      child: const Icon(Icons.directions_bus, color: Colors.red, size: 32),
    );

    // Start fake bus animation
    _startBusAnimation();

    final mid = LatLng((fromPt.latitude + toPt.latitude) / 2,
        (fromPt.longitude + toPt.longitude) / 2);
    mapController.move(mid, 14);

    setState(() {});
  }

  void clearRoute() {
    setState(() {
      _routePoints = [];
      _busMarker = null;
    });
  }

  void _startBusAnimation() async {
    if (_routePoints.isEmpty) return;

    Future.doWhile(() async {
      // ⏱ Bus moves every 15 seconds
      await Future.delayed(const Duration(seconds: 15));

      if (_routePoints.isEmpty) return false;

      setState(() {
        busIndex++;
        if (busIndex >= _routePoints.length) busIndex = 0;
        _busMarker = Marker(
          width: 40,
          height: 40,
          point: _routePoints[busIndex],
          child: const Icon(Icons.directions_bus, color: Colors.red, size: 32),
        );
      });
      return true;
    });
  }

  /// Create dashed polyline by alternating visible/transparent segments
  List<Polyline> _makeDashedLine(List<LatLng> pts) {
    final List<Polyline> dashed = [];
    for (var i = 0; i < pts.length - 1; i++) {
      dashed.add(
        Polyline(
          points: [pts[i], pts[i + 1]],
          color: (i % 2 == 0) ? Colors.blue : Colors.transparent,
          strokeWidth: 4,
        ),
      );
    }
    return dashed;
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      // All stops (blue bubbles)
      for (int i = 0; i < stopNames.length; i++)
        Marker(
          width: 44,
          height: 44,
          point: stops[stopNames[i]]!,
          child: _BlueStopMarker(number: i + 1),
        ),
      if (_busMarker != null) _busMarker!,
    ];

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: stops.values.first,
            initialZoom: 13.5,
          ),
          children: [
            if (!widget.offlineMode)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.smartbus',
              ),
            if (_routePoints.isNotEmpty)
              PolylineLayer(polylines: _makeDashedLine(_routePoints)),
            MarkerLayer(markers: markers),
          ],
        ),
      ],
    );
  }
}

// ------- Marker widgets -------
class _BlueStopMarker extends StatelessWidget {
  final int number;
  const _BlueStopMarker({required this.number});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1C6BE3),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.directions_bus,
              color: Colors.white, size: 20),
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

// ✅ Allow HomePage to use MapPageState safely
typedef MapPageStateKey = MapPageState;
