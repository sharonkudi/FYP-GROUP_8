import 'package:bus_app/l10n/app_localizations.dart' show AppLocalizations;
import 'package:flutter/material.dart';
import 'homepage-busroute.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvailableBusesPage extends StatelessWidget {
  final String busStopName;

  const AvailableBusesPage({super.key, required this.busStopName});

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

          return ListView.builder(
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
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        // Title row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                bus['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.black87,
                                ),
                                overflow:
                                    TextOverflow.ellipsis, // prevents overflow
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Available',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Time & route
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                bus['timew'],
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[700]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            Icon(Icons.alt_route,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                bus['route'],
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Duration (features removed for now)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                bus['duration'],
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.blue),
                                overflow: TextOverflow.ellipsis, // optional
                              ),
                            ),
                            const Spacer(),
                            // Features removed for now
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
  int fare = 0;

  void calculateFare(List<String> stops) {
    if (selectedFrom != null && selectedTo != null) {
      int fromIndex = stops.indexOf(selectedFrom!);
      int toIndex = stops.indexOf(selectedTo!);

      if (fromIndex != -1 && toIndex != -1 && toIndex > fromIndex) {
        int stopCount = (toIndex - fromIndex).abs();
        setState(() {
          fare = stopCount * 1; // $1 per stop
        });
      } else {
        setState(() {
          fare = 0; // invalid or same stop
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
      heightFactor: 0.6, // slightly taller to fit dropdowns
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

              // ---- Your existing card details (unchanged) ----
              Container(
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
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT INFO
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.bus['route'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Depart: ${widget.bus['time'].toString().split('-')[0].trim()}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.flag,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Arrive: ${widget.bus['time'].toString().split('-')[1].trim()}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.directions_bus,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Bus Number: ${widget.bus['id']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.person,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Driver: ${widget.bus['assignedTo'].isNotEmpty ? widget.bus['assignedTo'] : 'Unassigned'}',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // RIGHT INFO
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.bus['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Fee estimator:',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black),
                                ),
                                Text(
                                  '\$$fare',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ---- NEW DROPDOWNS for fare estimator ----
              if (stops.isNotEmpty) ...[
                Row(
                  children: [
                    // FROM Dropdown
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text("From"),
                        value: selectedFrom,
                        items: stops.map((stop) {
                          return DropdownMenuItem(
                            value: stop,
                            child: Text(stop),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedFrom = value;
                            selectedTo = null; // reset "To" when "From" changes
                            calculateFare(stops);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // TO Dropdown (only stops after "From")
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text("To"),
                        value: selectedTo,
                        items: selectedFrom == null
                            ? []
                            : stops
                                .skip(stops.indexOf(selectedFrom!) + 1)
                                .map((stop) => DropdownMenuItem(
                                      value: stop,
                                      child: Text(stop),
                                    ))
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTo = value;
                            calculateFare(stops);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),

              // ---- Your existing buttons (unchanged) ----
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
                          // ✅ Your original Navigator.push remains here
                          List<BusStop> stops = [];
                          if (widget.bus['route'] != null &&
                              widget.bus['route'] is String) {
                            stops = (widget.bus['route'] as String)
                                .split(',')
                                .map((name) => BusStop(
                                      name: name.trim(),
                                      eta: '5 minutes',
                                      lat: 0.0,
                                      lng: 0.0,
                                    ))
                                .toList();
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BusRoutePage(
                                busId: widget.bus['bus_id'] ?? 'UnknownBus',
                                stops: stops,
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
