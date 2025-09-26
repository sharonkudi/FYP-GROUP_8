import 'package:bus_app/l10n/app_localizations.dart' show AppLocalizations;
import 'package:flutter/material.dart';
import 'homepage-busroute.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvailableBusesPage extends StatelessWidget {
  final String busStopName;

  const AvailableBusesPage({super.key, required this.busStopName});

  Future<void> _refreshBuses() async {
    // Firestore streams update automatically, but this forces a reload
    await FirebaseFirestore.instance.collection('buses').get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Available Buses",
          style: TextStyle(color: Colors.white), // Title text color white
        ),
        backgroundColor: const Color(0xFF103A74), // Keep original color
        iconTheme: const IconThemeData(
          color: Colors.white, // Back button color white
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('buses').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Convert Firestore docs to bus list
          final buses = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': data['bus_id'] ?? 'Unknown Bus',
              'name': data['bus_name'] ?? 'Unknown Bus',
              'time': data['time'] ?? 'N/A',
              'route': data['route'] ?? 'N/A',
              'duration': data['duration'] ?? 'N/A',
              'assignedTo': data['assignedTo'] ?? '',
              'features': [], // ignoring icons/features for now
            };
          }).toList();

          snapshot.data!.docs.forEach((doc) {
  print(doc.data());
});

          
          return RefreshIndicator(
            onRefresh: _refreshBuses,
            child: ListView.builder(
              itemCount: buses.length,
              itemBuilder: (context, index) {
                final bus = buses[index];
                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => BusDetailsSheet(bus: bus),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  bus['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Available',
                                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  bus['time'],
                                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.alt_route, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  bus['route'],
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  bus['duration'],
                                  style: const TextStyle(fontSize: 13, color: Colors.blue),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class BusDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> bus;

  const BusDetailsSheet({super.key, required this.bus});

  @override
  State<BusDetailsSheet> createState() => _BusDetailsSheetState();
}

class _BusDetailsSheetState extends State<BusDetailsSheet> {
  String? selectedFrom;
  String? selectedTo;
  String driverContact = "N/A";

@override
  void initState() {
    super.initState();
    _fetchDriverContact();
  }

  Future<void> _fetchDriverContact() async {
    final driverName = widget.bus['assignedTo'];
    if (driverName != null && driverName.isNotEmpty) {
      final snapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .where('name', isEqualTo: driverName) // or use driver ID if available
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          driverContact = data['contactNumber'] ?? "N/A";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Split route into list of stops
    List<String> stops = [];
    if (widget.bus['route'] != null && widget.bus['route'] is String) {
      stops = (widget.bus['route'] as String)
          .split(',')
          .map((s) => s.trim())
          .toList();
    }

    return FractionallySizedBox(
      heightFactor: 0.6,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Bus info card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER: Bus Name + Number
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.bus['name'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          "Bus No: ${widget.bus['id']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ROUTE
                    Row(
                      children: [
                        const Icon(Icons.route, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.bus['route'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 0.6),

                    // SCHEDULE LIST: all times from Firebase
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildScheduleList(widget.bus['time']),
                    ),
                    const Divider(height: 20, thickness: 0.6),

                    // DRIVER INFO
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          widget.bus['assignedTo'].isNotEmpty
                              ? "Driver: ${widget.bus['assignedTo']}"
                              : "Driver: Unassigned",
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4), // spacing
    // DRIVER CONTACT
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          driverContact,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Spacer(),

              // BUTTONS
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Back', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          // ✅ NEW: Map route names to real BusStop objects with lat/lng
                          final Map<String, BusStop> stopCoordinates = {
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
                            // Add more known stops here
                          };

                          List<BusStop> stopsList = [];
                          if (widget.bus['route'] != null &&
                              widget.bus['route'] is String) {
                            stopsList = (widget.bus['route'] as String)
                                .split(',')
                                .map((name) =>
                                    stopCoordinates[name.trim()] ??
                                    BusStop(
                                        name: name.trim(),
                                        lat: 0.0,
                                        lng: 0.0))
                                .toList();
                          }

                          // Inside the "View Bus" button onPressed in BusDetailsSheet

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BusRoutePage(
      busId: widget.bus['id'] ?? 'UnknownBus',
      stops: stopsList,
      gpsRef: widget.bus['id'] == 'BUS002' ? 'gpsData2' : 'gpsData', // Add this line
      onTransit: () {
        // Example: transit to Bus B (for demo purposes)
        final nextBusDoc = FirebaseFirestore.instance
            .collection('buses')
            .where('bus_id', isNotEqualTo: widget.bus['id'])
            .limit(1);

        nextBusDoc.get().then((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final nextBus = snapshot.docs.first.data();
            List<BusStop> nextStopsList = (nextBus['route'] as String)
                .split(',')
                .map((name) =>
                    stopCoordinates[name.trim()] ??
                    BusStop(name: name.trim(), lat: 0, lng: 0))
                .toList();

            Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => BusRoutePage(
      busId: nextBus['bus_id'] ?? 'UnknownBus',
      stops: nextStopsList,
      gpsRef: nextBus['bus_id'] == 'BUS002' ? 'gpsData2' : 'gpsData', // Add this line
      onTransit: null, // optional: add further transit
    ),
  ),
);
          }
        });
      },
    ),
  ),
);
                        },
                        child: const Text('View Bus',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper method to build schedule list from Firebase string
  List<Widget> _buildScheduleList(String? timeString) {
    if (timeString == null || timeString.isEmpty) return [];

    // Split by ". " to separate each stop + time
    final List<String> schedule = timeString
        .split(RegExp(r'\.\s*'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    return [
      const Text(
        "Schedule:",
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 6),
      ...schedule.map(
        (entry) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.green),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }
