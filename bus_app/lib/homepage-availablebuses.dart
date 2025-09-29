import 'package:bus_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'homepage-busroute.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvailableBusesPage extends StatefulWidget {
  final String busStopName;

  const AvailableBusesPage({super.key, required this.busStopName});

  @override
  State<AvailableBusesPage> createState() => _AvailableBusesPageState();
}

class _AvailableBusesPageState extends State<AvailableBusesPage> {
  Future<void> _refreshBuses() async {
    await FirebaseFirestore.instance.collection('buses').get();
    setState(() {});
  }

  final Set<String> _selectedFareBusIds = {};

  // NEW: Passenger counts
  int _adultCount = 0;
  int _childCount = 0;

  // UPDATED: Fare calculation (adult = $1.00, child/senior = $0.50)
  double get totalFare {
    final perBusFare = (_adultCount * 1.0) + (_childCount * 0.5);
    return perBusFare * _selectedFareBusIds.length;
  }

  // Helper to produce breakdown text using localization (pass loc from build)
  String fareBreakdown(AppLocalizations loc) {
    if (_selectedFareBusIds.isEmpty || (_adultCount == 0 && _childCount == 0)) {
      return "";
    }
    return "($_adultCount ${loc.adults} + $_childCount ${loc.childrenSeniors}) × ${_selectedFareBusIds.length} bus(es)";
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.availableBuses,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF103A74),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('buses').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final buses = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'docId': doc.id,
                    'id': data['bus_id'] ?? doc.id,
                    'name': data['bus_name'] ?? 'Unknown Bus',
                    'time': data['time'] ?? 'N/A',
                    'route': data['route'] ?? 'N/A',
                    'duration': data['duration'] ?? 'N/A',
                    'assignedTo': data['assignedTo'] ?? '',
                    'features': [],
                  };
                }).toList();

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
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
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
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            color: Colors.black87),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        loc.available,
                                        style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        bus['time'],
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700]),
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
                                            fontSize: 14,
                                            color: Colors.grey[600]),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
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
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
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
          ),

          // -----------------------------------------------------
          // Fare Estimator Card (fixed at bottom)
          // -----------------------------------------------------
          Card(
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('buses').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final buses = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {
                      'docId': doc.id,
                      'id': data['bus_id'] ?? doc.id,
                      'name': data['bus_name'] ?? (data['bus_id'] ?? doc.id),
                    };
                  }).toList();

                  return ExpansionTile(
                    title: Text(
                      loc.fareEstimator,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),

                    // ====== START: added dropdowns + breakdown (kept inside existing children) ======
                    children: [
                      // Passenger dropdowns (Adults & Children/Seniors)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(loc.adults),
                                DropdownButton<int>(
                                  value: _adultCount,
                                  items: List.generate(11, (i) => i) // 0–10
                                      .map((count) => DropdownMenuItem(
                                            value: count,
                                            child: Text(count.toString()),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _adultCount = value ?? 0;
                                    });
                                  },
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(loc.childrenSeniors),
                                DropdownButton<int>(
                                  value: _childCount,
                                  items: List.generate(11, (i) => i) // 0–10
                                      .map((count) => DropdownMenuItem(
                                            value: count,
                                            child: Text(count.toString()),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _childCount = value ?? 0;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Bus selection checkboxes (your original code)
                      Column(
                        children: buses.map((bus) {
                          final busId = bus['id']?.toString() ?? bus['docId'];
                          final isSelected =
                              _selectedFareBusIds.contains(busId);
                          return Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedFareBusIds.add(busId);
                                    } else {
                                      _selectedFareBusIds.remove(busId);
                                    }
                                  });
                                },
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedFareBusIds.remove(busId);
                                      } else {
                                        _selectedFareBusIds.add(busId);
                                      }
                                    });
                                  },
                                  child: Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.blue[50]
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      bus['name'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 11),

                      // Fare breakdown (only shown when relevant)
                      if (fareBreakdown(loc).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            fareBreakdown(loc),
                            style: const TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.black54,
                            ),
                          ),
                        ),

                      // Total fare (formatted to 2 decimals)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.lightBlueAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${loc.totalFare}: \$${totalFare.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                    // ====== END: added dropdowns + breakdown ======
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------
// Bus details sheet (fixed with scroll)
// -------------------------
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
          .where('name', isEqualTo: driverName)
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
    final loc = AppLocalizations.of(context)!;

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
          child: SingleChildScrollView(
            // ✅ FIX: allow scrolling
            child: Column(
              children: [
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildScheduleList(widget.bus['time']),
                      ),
                      const Divider(height: 20, thickness: 0.6),
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 16, color: Colors.grey),
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
                      const SizedBox(height: 4),
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
                        child: Text(loc.back,
                            style: const TextStyle(fontSize: 16)),
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
                            final Map<String, BusStop> stopCoordinates = {
                              "The Mall Gadong": BusStop(
                                  name: "The Mall Gadong",
                                  lat: 4.905010,
                                  lng: 114.919227),
                              "Yayasan Complex": BusStop(
                                  name: "Yayasan Complex",
                                  lat: 4.888581361818439,
                                  lng: 114.94048600605531),
                              "Kianggeh": BusStop(
                                  name: "Kianggeh",
                                  lat: 4.8892108308087385,
                                  lng: 114.94433682090414),
                              "Ong Sum Ping": BusStop(
                                  name: "Ong Sum Ping",
                                  lat: 4.90414222577477,
                                  lng: 114.93627988813594),
                              "PB School": BusStop(
                                  name: "PB School",
                                  lat: 4.904922563115028,
                                  lng: 114.9332865430959),
                              "Ministry of Finance": BusStop(
                                  name: "Ministry of Finance",
                                  lat: 4.915056711681162,
                                  lng: 114.95226715214645),
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

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BusRoutePage(
                                  busId: widget.bus['id'] ?? 'UnknownBus',
                                  stops: stopsList,
                                  gpsRef: widget.bus['id'] == 'BUS002'
                                      ? 'gpsData2'
                                      : 'gpsData',
                                  onTransit: () {
                                    final nextBusDoc = FirebaseFirestore
                                        .instance
                                        .collection('buses')
                                        .where('bus_id',
                                            isNotEqualTo: widget.bus['id'])
                                        .limit(1);

                                    nextBusDoc.get().then((snapshot) {
                                      if (snapshot.docs.isNotEmpty) {
                                        final nextBus =
                                            snapshot.docs.first.data();
                                        List<BusStop> nextStopsList = (nextBus[
                                                'route'] as String)
                                            .split(',')
                                            .map((name) =>
                                                stopCoordinates[name.trim()] ??
                                                BusStop(
                                                    name: name.trim(),
                                                    lat: 0,
                                                    lng: 0))
                                            .toList();

                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => BusRoutePage(
                                              busId: nextBus['bus_id'] ??
                                                  'UnknownBus',
                                              stops: nextStopsList,
                                              gpsRef:
                                                  nextBus['bus_id'] == 'BUS002'
                                                      ? 'gpsData2'
                                                      : 'gpsData',
                                              onTransit: null,
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
                          child: Text(loc.viewBus,
                              style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> _buildScheduleList(String? timeString) {
  if (timeString == null || timeString.isEmpty) return [];

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
