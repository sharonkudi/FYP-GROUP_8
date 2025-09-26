import 'package:bus_app/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'homepage-mapform.dart';

class BusRoutePage extends StatefulWidget {
  final String busId;
  final List<BusStop> stops;
  final String gpsRef; // Add this
  final int? currentStopIndex;
  final VoidCallback? onTransit;

  const BusRoutePage({
    super.key,
    required this.busId,
    required this.stops,
    required this.gpsRef, // Add this
    this.currentStopIndex,
    this.onTransit,
  });

  @override
  State<BusRoutePage> createState() => _BusRoutePageState();
}

class _BusRoutePageState extends State<BusRoutePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  // Add these stream controllers
  late StreamController<Map<String, dynamic>> _mainBusController;
  late StreamController<Map<String, dynamic>> _altBusController;

  List<BusStop>? nextBusStops;
  String? nextBusName;
  String? nextBusId;
  double? nextBusLat;
  double? nextBusLng;
  double nextBusSpeed = 30;

  // Add to your existing state variables
  Map<String, dynamic>? _mainBusData;
  Map<String, dynamic>? _altBusData;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.9,
      upperBound: 1.3,
    )..repeat(reverse: true);

    // Initialize stream controllers
    _mainBusController = StreamController<Map<String, dynamic>>.broadcast();
    _altBusController = StreamController<Map<String, dynamic>>.broadcast();

    // Set up GPS listeners
    _setupGpsListeners();

    if (widget.onTransit != null) {
      fetchNextBus();
    }
  }

  void _setupGpsListeners() {
    // Listen to main bus GPS
    FirebaseDatabase.instance.ref(widget.gpsRef).onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        _mainBusController.add(data);
        setState(() => _mainBusData = data);

        print('====== Current Bus GPS Data ======');
        print('Bus ID: ${widget.busId}');
        print('GPS Source: ${widget.gpsRef}');
        print('Location: ${data['latitude']}, ${data['longitude']}');
        print('Speed: ${data['speed']} km/h');
        print('================================');
      }
    });

    // Listen to alternative bus GPS
    final altGpsRef = widget.busId == 'BUS002' ? 'gpsData' : 'gpsData2';
    FirebaseDatabase.instance.ref(altGpsRef).onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        _altBusController.add(data);
        setState(() => _altBusData = data);

        print('====== Alternative Bus GPS Data ======');
        print('Bus ID: ${widget.busId == "BUS002" ? "BUS001" : "BUS002"}');
        print('GPS Source: $altGpsRef');
        print('Location: ${data['latitude']}, ${data['longitude']}');
        print('Speed: ${data['speed']} km/h');
        print('====================================');
      }
    });
  }

  Future<void> fetchNextBus() async {
    // Example stop coordinates; adapt as needed
    final stopCoordinates = {
      "The Mall Gadong": BusStop(
          name: "The Mall Gadong", lat: 4.905010, lng: 114.919227),
      "Yayasan Complex": BusStop(
          name: "Yayasan Complex", lat: 4.888581361818439, lng: 114.94048600605531),
      "Kianggeh": BusStop(
          name: "Kianggeh", lat: 4.8892108308087385, lng: 114.94433682090414),
      "Ong Sum Ping": BusStop(
          name: "Ong Sum Ping", lat: 4.90414222577477, lng: 114.93627988813594),
      "PB School": BusStop(
          name: "PB School", lat: 4.904922563115028, lng: 114.9332865430959),
      "Ministry of Finance": BusStop(
          name: "Ministry of Finance", lat: 4.915056711681162, lng: 114.95226715214645),
    };

    final snapshot = await FirebaseFirestore.instance
        .collection('buses')
        .where('bus_id', isNotEqualTo: widget.busId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final busData = snapshot.docs.first.data();
      setState(() {
        nextBusId = busData['bus_id'];
        nextBusName = busData['bus_name'];
        nextBusStops = (busData['route'] as String)
            .split(',')
            .map((name) => stopCoordinates[name.trim()] ??
                BusStop(name: name.trim(), lat: 0, lng: 0))
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _mainBusController.close();
    _altBusController.close();
    _pulseController.dispose();
    super.dispose();
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  int _calculateETA(double distanceMeters, {double speedKmh = 30}) {
    if (speedKmh <= 0) return -1;
    double speedMps = speedKmh * 1000 / 3600;
    return (distanceMeters / speedMps / 60).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Bus Route",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<Map<String, dynamic>>(
          stream: _mainBusController.stream,
          initialData: _mainBusData,
          builder: (context, snapshot) {
            double? busLat;
            double? busLng;
            double busSpeed = 30;

            if (snapshot.hasData) {
              final data = snapshot.data!;
              busLat = (data['latitude'] ?? 0).toDouble();
              busLng = (data['longitude'] ?? 0).toDouble();
              busSpeed = ((data['speed'] ?? 0).toDouble()) * 3.6; // convert m/s → km/h
            }

            return ListView(
              children: [
                // Current bus stops
                ...widget.stops.asMap().entries.map((entry) {
                  int index = entry.key;
                  BusStop stop = entry.value;
                  return buildStopRow(stop, index, busLat, busLng, busSpeed, widget.stops);
                }).toList(),

                // ExpansionTile for next bus if available
                // Replace the existing ExpansionTile code with this:
                if (nextBusStops != null)
                  ExpansionTile(
                    title: Text(
                      nextBusName ?? 'Next Bus',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    children: [
                      StreamBuilder<Map<String, dynamic>>(
                        stream: _altBusController.stream,
                        initialData: _altBusData,
                        builder: (context, altSnapshot) {
                          double? altBusLat;
                          double? altBusLng;
                          double altBusSpeed = 30;

                          if (altSnapshot.hasData) {
                            final data = altSnapshot.data!;
                            altBusLat = (data['latitude'] ?? 0).toDouble();
                            altBusLng = (data['longitude'] ?? 0).toDouble();
                            altBusSpeed = ((data['speed'] ?? 0).toDouble()) * 3.6;
                          }

                          return Column(
                            children: nextBusStops!.asMap().entries.map((entry) {
                              int index = entry.key;
                              BusStop stop = entry.value;
                              return buildStopRow(
                                stop,
                                index,
                                altBusLat,
                                altBusLng,
                                altBusSpeed,
                                nextBusStops!,
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),

                  // View Map button
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton.icon(
        onPressed: () {
          // Navigate to homepage-mapform
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(initialTab: 1), // 1 = Map Form tab
            ),
          );
        },
        icon: const Icon(Icons.map),
        label: const Text("View Map"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget buildStopRow(BusStop stop, int index, double? busLat, double? busLng, double busSpeed, List<BusStop> stopsList) {
    String etaText = "--";
    bool isNearby = false;
    Color lineColor = Colors.grey[300]!;

    // Determine ETA
    if (busLat != null && busLng != null && busSpeed > 0) {
      double distToStop = _calculateDistance(busLat, busLng, stop.lat, stop.lng);

      if (distToStop > 0) {
        int etaMinutes = _calculateETA(distToStop, speedKmh: busSpeed);
        etaText = etaMinutes >= 0 ? "$etaMinutes min" : "--";
      } else {
        etaText = "0 min";
      }

      // 👇 Add distance display here
      if (distToStop < 1000) {
        etaText += " • ${distToStop.toStringAsFixed(0)} m";
      } else {
        etaText += " • ${(distToStop / 1000).toStringAsFixed(1)} km";
      }

      isNearby = distToStop <= 90;

      // Line color gradient logic
      if (index != stopsList.length - 1) {
        final nextStop = stopsList[index + 1];
        double segmentLength = _calculateDistance(stop.lat, stop.lng, nextStop.lat, nextStop.lng);
        segmentLength = segmentLength == 0 ? 1 : segmentLength;

        double distToNextStop = _calculateDistance(busLat, busLng, nextStop.lat, nextStop.lng);
        double segmentProgress =
            ((segmentLength - distToNextStop).clamp(0, segmentLength)) / segmentLength;
        lineColor = Color.lerp(Colors.grey[300], Colors.green, segmentProgress)!;
      }

      final lastStop = stopsList.last;
      double distToLast = _calculateDistance(busLat, busLng, lastStop.lat, lastStop.lng);
      if (distToLast <= 50) lineColor = Colors.grey[300]!;
    }

    // Determine status: Passed / Arrived / Upcoming
    String status = "Upcoming";
    if (busLat != null && busLng != null) {
      double distanceToStop = _calculateDistance(busLat, busLng, stop.lat, stop.lng);
      if (distanceToStop <= 90) {
        status = "Arrived";
      } else {
        // Check if bus has passed this stop (any previous stop within 10m)
        bool passed = false;
        for (int i = 0; i < index; i++) {
          double distPrev = _calculateDistance(busLat, busLng, stopsList[i].lat, stopsList[i].lng);
          if (distPrev <= 10) {
            passed = true;
            break;
          }
        }
        if (passed) status = "Passed";
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dot + line
        Column(
          children: [
            ScaleTransition(
              scale: isNearby ? _pulseController : const AlwaysStoppedAnimation<double>(1.0),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isNearby ? Colors.green : Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            if (index != stopsList.length - 1)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 2,
                height: 70 + 34 / 2,
                color: lineColor,
              ),
          ],
        ),
        const SizedBox(width: 12),

        // Main stop container
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),

                // ETA and Status Row
                Row(
                  children: [
                    // ETA box
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "ETA: $etaText",
                          style: const TextStyle(color: Colors.black87, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status box (no pulsating animation)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: status == "Arrived"
                              ? Colors.green.withOpacity(0.2)
                              : status == "Passed"
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: status == "Arrived"
                                ? Colors.green
                                : status == "Passed"
                                    ? Colors.red
                                    : Colors.orange,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BusStop {
  final String name;
  final String? departIn;
  final double lat;
  final double lng;

  BusStop({
    required this.name,
    this.departIn,
    required this.lat,
    required this.lng,
  });
}
