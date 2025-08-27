// lib/pages/map_page.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

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

  LatLng? currentLocation;

  // Offline routing graph
  late Map<String, LatLng> _offlineStops;
  late List<List<String>> _offlineEdges;
  bool _routesLoaded = false;

  // Preview overlays
  List<Polyline> _offlinePreview = [];
  Marker? _offlinePreviewBus;

  @override
  void initState() {
    super.initState();
    currentLocation = stops.values.first;
    _loadLocalRoutes();
  }

  // ===== Public API (Home calls) =====
  void centerBetween(String from, String to) {
    final p1 = stops[from]!;
    final p2 = stops[to]!;
    final mid = LatLng((p1.latitude + p2.latitude) / 2,
        (p1.longitude + p2.longitude) / 2);
    mapController.move(mid, 14);
  }

  void showOfflineRouteByName(String fromId, String toId) {
    if (!_routesLoaded) return;
    final ids = _shortestPath(fromId, toId);
    if (ids.length < 2) return;
    final pts = ids.map((id) => _offlineStops[id]!).toList();
    _drawOfflinePreview(pts);
  }

  void clearOfflineRoute() {
    setState(() {
      _offlinePreview = [];
      _offlinePreviewBus = null;
    });
  }
  // ===================================

  Future<void> _loadLocalRoutes() async {
    try {
      final s = await rootBundle.loadString('assets/data/offline_routes.json');
      final data = jsonDecode(s) as Map<String, dynamic>;

      final m = <String, LatLng>{};
      for (final st in (data['stops'] as List)) {
        m[st['id'] as String] = LatLng(
          (st['lat'] as num).toDouble(),
          (st['lng'] as num).toDouble(),
        );
      }
      _offlineStops = m;
      _offlineEdges = (data['edges'] as List)
          .map<List<String>>((e) => [e[0] as String, e[1] as String])
          .toList();

      setState(() => _routesLoaded = true);
    } catch (_) {
      _routesLoaded = false; // keep working even if file missing
    }
  }

  List<String> _shortestPath(String fromId, String toId) {
    final adj = <String, List<String>>{};
    for (final e in _offlineEdges) {
      adj.putIfAbsent(e[0], () => []).add(e[1]);
      adj.putIfAbsent(e[1], () => []).add(e[0]);
    }
    final q = <String>[fromId];
    final prev = <String, String?>{fromId: null};
    for (var i = 0; i < q.length; i++) {
      final u = q[i];
      if (u == toId) break;
      for (final v in (adj[u] ?? const [])) {
        if (!prev.containsKey(v)) {
          prev[v] = u;
          q.add(v);
        }
      }
    }
    if (!prev.containsKey(toId)) return [];
    final path = <String>[];
    for (String? at = toId; at != null; at = prev[at]!) {
      path.add(at);
    }
    return path.reversed.toList();
  }

  void _drawOfflinePreview(List<LatLng> points) {
    if (points.length < 2) return;
    setState(() {
      _offlinePreview = [
        Polyline(
          points: points,
          color: const Color(0xFF5B677A),
          strokeWidth: 4,
          // NOTE: solid line (no plugin). If you want dashed,
          // add flutter_map_dashed_polyline and switch to DashedPolyline.
        ),
      ];
      _offlinePreviewBus = Marker(
        width: 40,
        height: 40,
        point: points.first,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: const Icon(Icons.directions_bus, color: Color(0xFFE53935)),
        ),
      );
    });

    final mid = points[points.length ~/ 2];
    mapController.move(mid, 14);
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      for (int i = 0; i < stopNames.length; i++)
        Marker(
          width: 44,
          height: 44,
          point: stops[stopNames[i]]!,
          child: _BlueStopMarker(number: i + 1),
        ),
      if (currentLocation != null)
        Marker(
          width: 44,
          height: 44,
          point: currentLocation!,
          child: const _PersonMarker(),
        ),
      if (_offlinePreviewBus != null) _offlinePreviewBus!,
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
            // ✅ Only load online tiles when NOT in offline mode
            if (!widget.offlineMode)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.basku_bn',
              ),
            if (_offlinePreview.isNotEmpty)
              PolylineLayer(polylines: _offlinePreview),
            MarkerLayer(markers: markers),
          ],
        ),
      ],
    );
  }
}

// ------- Marker widgets (unchanged) -------
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

class _PersonMarker extends StatelessWidget {
  const _PersonMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF1C6BE3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.person, color: Color(0xFF1C6BE3), size: 20),
    );
  }
}
