import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class BusRoutePage extends StatefulWidget {
  final String busId; // e.g. "bus123"
  final List<BusStop> stops;

  const BusRoutePage({
    super.key,
    required this.busId,
    required this.stops,
  });

  @override
  State<BusRoutePage> createState() => _BusRoutePageState();
}

class _BusRoutePageState extends State<BusRoutePage> {
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2); // meters
  }

  int _calculateETA(double distanceMeters, {double speedKmh = 30}) {
    double speedMps = speedKmh * 1000 / 3600;
    return (distanceMeters / speedMps / 60).round(); // minutes
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
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('buses')
              .doc(widget.busId)
              .snapshots(),
          builder: (context, snapshot) {
            double? busLat;
            double? busLng;
            double busSpeed = 30;

            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              busLat = data['lat'];
              busLng = data['lng'];
              if (data.containsKey('speed')) {
                busSpeed = data['speed'] ?? 30;
              }
            }

            return ListView.builder(
              itemCount: widget.stops.length,
              itemBuilder: (context, index) {
                final stop = widget.stops[index];
                String etaText = stop.eta;

                if (busLat != null && busLng != null) {
                  double dist = _calculateDistance(
                      busLat, busLng, stop.lat, stop.lng);
                  int etaMinutes = _calculateETA(dist, speedKmh: busSpeed);
                  etaText = "$etaMinutes min";
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline dots & lines
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (index != widget.stops.length - 1)
                          Container(
                            width: 2,
                            height: 70,
                            color: Colors.grey[300],
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Stop info card
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
                            if (stop.departIn != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  stop.departIn!,
                                  style: const TextStyle(
                                      color: Colors.blue, fontSize: 13),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "ETA: $etaText",
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class BusStop {
  final String name;
  final String? departIn;
  final String eta; // fallback ETA text
  final double lat;
  final double lng;

  BusStop({
    required this.name,
    this.departIn,
    required this.eta,
    required this.lat,
    required this.lng,
  });
}
