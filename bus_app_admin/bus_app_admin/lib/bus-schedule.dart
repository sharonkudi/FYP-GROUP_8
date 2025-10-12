import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 🔹 Import log service
import 'logs_service.dart';

class AdminBusSchedulePage extends StatefulWidget {
  final String adminId;
  final String adminName;

  const AdminBusSchedulePage({
    super.key,
    required this.adminId,
    required this.adminName,
  });

  @override
  State<AdminBusSchedulePage> createState() => _AdminBusSchedulePageState();
}

class _AdminBusSchedulePageState extends State<AdminBusSchedulePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  Future<String> _generateBusId() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('buses')
        .orderBy('bus_id', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return "BUS001";
    } else {
      final lastId = snapshot.docs.first['bus_id'] as String;
      final number = int.parse(lastId.replaceAll(RegExp(r'[^0-9]'), ''));
      final nextId = number + 1;
      return "BUS${nextId.toString().padLeft(3, '0')}";
    }
  }

  void _goToAddBusPage() async {
    final busId = await _generateBusId();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddBusPage(busId: busId)),
    );
  }

  void _goToEditBusPage(String docId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditBusPage(docId: docId, data: data),
      ),
    );
  }

  void _deleteBus(String docId, String busName, String busId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete $busName ($busId)?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('buses')
                    .doc(docId)
                    .delete();
                await addLog("Deleted bus schedule: $busName ($busId)");
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Yes", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBusList() {
    return Column(
      children: [
        // 🔹 Search bar + Add button
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: "Search bus name / stop",
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.blue),
                        onPressed: _performSearch,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue, width: 1),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.add, color: Colors.blue),
                  onPressed: _goToAddBusPage,
                ),
              ),
            ],
          ),
        ),

        // 🔹 Bus List Cards
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('buses')
                .orderBy('bus_id')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['bus_name']?.toString().toLowerCase() ?? '';
                final stops = (data['stops'] ?? []).toString().toLowerCase();
                return _searchQuery.isEmpty ||
                    name.contains(_searchQuery) ||
                    stops.contains(_searchQuery);
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text("No bus schedules found"));
              }

              final assignedDrivers = docs
                  .map((d) => (d['assignedTo'] ?? "").toString())
                  .where((name) => name.isNotEmpty)
                  .toSet();

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final docId = docs[index].id;
                  final busId = data['bus_id'] ?? '';
                  final busName = data['bus_name'] ?? '';
                  final currentAssigned = data['assignedTo'] ?? '';

                  final stops = (data['stops'] ?? []) as List;
                  final duration = data['duration'] ?? '';
                  final features = (data['features'] is List)
                      ? (data['features'] as List).join(', ')
                      : (data['features'] ?? '');

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 Bus title & ID
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                busName,
                                style: const TextStyle(
                                  color: Color(0xFF103A74),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                "Bus No: $busId",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Divider(),

                          // 🔹 Stops / Schedule
                          const Text(
                            "Schedule:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (stops.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: stops.map<Widget>((s) {
                                String time = s['time'] ?? '';
                                if (time.isNotEmpty && !time.contains('M')) {
                                  final parts = time.split(':');
                                  if (parts.length == 2) {
                                    int hour = int.tryParse(parts[0]) ?? 0;
                                    int minute = int.tryParse(parts[1]) ?? 0;
                                    final period = hour >= 12 ? "PM" : "AM";
                                    hour = hour > 12 ? hour - 12 : hour;
                                    time =
                                        "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}$period";
                                  }
                                }
                                return Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "$time - ${s['name'] ?? ''}",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                );
                              }).toList(),
                            )
                          else
                            const Text("No stops available"),

                          const SizedBox(height: 8),
                          Text("Duration: $duration"),
                          Text("Features: $features"),

                          const SizedBox(height: 6),
                          const Divider(),

                          // 🔹 Driver Info
                          Row(
                            children: [
                              const Icon(Icons.person, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                "Driver: ${currentAssigned.isEmpty ? '-' : currentAssigned}",
                              ),
                            ],
                          ),
                          if (data['driverPhone'] != null &&
                              data['driverPhone'].toString().isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 18),
                                const SizedBox(width: 6),
                                Text(data['driverPhone'].toString()),
                              ],
                            ),

                          const SizedBox(height: 6),

                          // 🔹 Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('drivers')
                                    .snapshots(),
                                builder: (context, driverSnapshot) {
                                  if (!driverSnapshot.hasData) {
                                    return const SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  var drivers = driverSnapshot.data!.docs;
                                  var driverNames = drivers
                                      .map((doc) => doc['name'].toString())
                                      .toList();

                                  if (currentAssigned.isNotEmpty &&
                                      !driverNames.contains(currentAssigned)) {
                                    FirebaseFirestore.instance
                                        .collection('buses')
                                        .doc(docId)
                                        .update({'assignedTo': ""});
                                  }

                                  var availableDrivers = driverNames
                                      .where(
                                        (name) =>
                                            !assignedDrivers.contains(name) ||
                                            name == currentAssigned,
                                      )
                                      .toList();

                                  availableDrivers.insert(
                                    0,
                                    "Clear Assignment",
                                  );

                                  return DropdownButton<String>(
                                    value: currentAssigned.isNotEmpty
                                        ? currentAssigned
                                        : null,
                                    hint: const Text("Assign"),
                                    items: availableDrivers.map((name) {
                                      return DropdownMenuItem(
                                        value: name == "Clear Assignment"
                                            ? ""
                                            : name,
                                        child: Text(name),
                                      );
                                    }).toList(),
                                    onChanged: (value) async {
                                      await FirebaseFirestore.instance
                                          .collection('buses')
                                          .doc(docId)
                                          .update({'assignedTo': value ?? ""});
                                      final action =
                                          (value == null || value.isEmpty)
                                          ? "Cleared assignment for $busId"
                                          : "Assigned driver $value to $busId";
                                      await addLog(action);
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _goToEditBusPage(docId, data),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _deleteBus(docId, busName, busId),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBusList());
  }
}

////////////////////////////////////////////////////////
// ✅ Add Bus Page (Updated: stops)
////////////////////////////////////////////////////////
class AddBusPage extends StatefulWidget {
  final String busId;
  const AddBusPage({super.key, required this.busId});

  @override
  State<AddBusPage> createState() => _AddBusPageState();
}

class _AddBusPageState extends State<AddBusPage> {
  String busName = "";
  String duration = "";
  List<Map<String, dynamic>> stops = [];
  List<String> selectedFeatures = [];

  @override
  void initState() {
    super.initState();
    _generateBusName();
    stops.add({"name": "", "lat": "", "lng": "", "time": TimeOfDay.now()});
  }

  void _generateBusName() {
    final number = int.parse(widget.busId.replaceAll(RegExp(r'[^0-9]'), ''));
    final letter = String.fromCharCode(64 + number);
    setState(() {
      busName = "Bus $letter (${widget.busId})";
    });
  }

  void _saveBus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (stops.isEmpty || duration.isEmpty) return;

    final stopData = stops.map((s) {
      return {
        "name": s["name"],
        "lat": double.tryParse(s["lat"]) ?? 0.0,
        "lng": double.tryParse(s["lng"]) ?? 0.0,
        "time":
            "${s["time"].hour.toString().padLeft(2, '0')}:${s["time"].minute.toString().padLeft(2, '0')}",
      };
    }).toList();

    await FirebaseFirestore.instance.collection('buses').add({
      'bus_id': widget.busId,
      'bus_name': busName,
      'stops': stopData,
      'duration': duration,
      'features': selectedFeatures,
      'assignedTo': "",
      'createdAt': FieldValue.serverTimestamp(),
      'ownerId': user.uid,
    });

    await addLog("Added bus schedule: $busName (${widget.busId})");

    Navigator.pop(context);
  }

  Widget _buildStopField(int index) {
    final stop = stops[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              "Stop ${index + 1}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: "Name"),
              onChanged: (val) => stop["name"] = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Latitude"),
              keyboardType: TextInputType.number,
              onChanged: (val) => stop["lat"] = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Longitude"),
              keyboardType: TextInputType.number,
              onChanged: (val) => stop["lng"] = val,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text("Time: "),
                Text(
                  "${stop["time"].hour.toString().padLeft(2, '0')}:${stop["time"].minute.toString().padLeft(2, '0')}",
                ),
                IconButton(
                  icon: const Icon(Icons.access_time, color: Colors.blue),
                  onPressed: () async {
                    TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: stop["time"],
                    );
                    if (picked != null) {
                      setState(() {
                        stop["time"] = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    final features = [
      "Wi-Fi",
      "Aircond",
      "Wheelchair space",
      "Wheelchair lifts",
    ];
    return Wrap(
      spacing: 10,
      children: features.map((f) {
        final selected = selectedFeatures.contains(f);
        return ChoiceChip(
          label: Text(f),
          selected: selected,
          selectedColor: Colors.grey,
          onSelected: (val) {
            setState(() {
              if (val) {
                selectedFeatures.add(f);
              } else {
                selectedFeatures.remove(f);
              }
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Bus", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF103A74),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Bus Name",
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              controller: TextEditingController(text: busName),
            ),
            const SizedBox(height: 16),

            const Text(
              "Stops",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              children: stops
                  .asMap()
                  .entries
                  .map((entry) => _buildStopField(entry.key))
                  .toList(),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add Stop"),
              onPressed: () {
                setState(() {
                  stops.add({
                    "name": "",
                    "lat": "",
                    "lng": "",
                    "time": TimeOfDay.now(),
                  });
                });
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: duration.isEmpty ? null : duration,
              decoration: const InputDecoration(
                labelText: "Duration",
                border: OutlineInputBorder(),
              ),
              items:
                  const [
                    "Estimated 10-20 minutes for each stops",
                    "Estimated 10-15 minutes for each stops",
                    "Estimated 5-15 minutes for each stops",
                    "Estimated 5-10 minutes for each stops",
                  ].map((d) {
                    return DropdownMenuItem(value: d, child: Text(d));
                  }).toList(),
              onChanged: (val) => setState(() => duration = val ?? ""),
            ),
            const SizedBox(height: 16),

            const Text(
              "Features",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildFeatures(),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _saveBus,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Save Data",
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/////////////////////////////////////////////////////
// ✅ Edit Bus Page (Updated - using "stops" field)
/////////////////////////////////////////////////////

class EditBusPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditBusPage({super.key, required this.docId, required this.data});

  @override
  State<EditBusPage> createState() => _EditBusPageState();
}

class _EditBusPageState extends State<EditBusPage> {
  late String busId;
  late String busName;
  late String duration;
  late List<Map<String, dynamic>> stops;
  late List<String> selectedFeatures;

  @override
  void initState() {
    super.initState();
    busId = widget.data['bus_id'] ?? '';
    busName = widget.data['bus_name'] ?? '';

    // Duration
    duration = widget.data['duration'] ?? "";

    // 🔹 Stops (was routes before)
    if (widget.data['stops'] != null) {
      stops = List<Map<String, dynamic>>.from(
        (widget.data['stops'] as List).map(
          (s) => {
            "name": s["name"] ?? "",
            "lat": s["lat"].toString(),
            "lng": s["lng"].toString(),
            "time": _parseTime(s["time"] ?? "08:00"),
          },
        ),
      );
    } else {
      stops = [
        {"name": "", "lat": "", "lng": "", "time": TimeOfDay.now()},
      ];
    }

    // Features
    if (widget.data['features'] != null) {
      selectedFeatures = List<String>.from(widget.data['features']);
    } else {
      selectedFeatures = [];
    }
  }

  // 🔹 Helper to parse "08:00" into TimeOfDay
  TimeOfDay _parseTime(String time) {
    final parts = time.split(":");
    if (parts.length == 2) {
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return TimeOfDay.now();
  }

  // 🔹 Update Bus
  void _updateBus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final stopData = stops.map((s) {
      return {
        "name": s["name"],
        "lat": double.tryParse(s["lat"]) ?? 0.0,
        "lng": double.tryParse(s["lng"]) ?? 0.0,
        "time":
            "${s["time"].hour.toString().padLeft(2, '0')}:${s["time"].minute.toString().padLeft(2, '0')}",
      };
    }).toList();

    await FirebaseFirestore.instance
        .collection('buses')
        .doc(widget.docId)
        .update({
          'bus_name': busName,
          'stops': stopData, // ✅ changed field name here
          'duration': duration,
          'features': selectedFeatures,
          'ownerId': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });

    await addLog("Updated bus schedule: $busName ($busId)");
    Navigator.pop(context);
  }

  // 🔹 Build Stop Field Widget (was Route Field)
  Widget _buildStopField(int index) {
    final stop = stops[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              "Stop ${index + 1}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: stop["name"]),
              decoration: const InputDecoration(labelText: "Name"),
              onChanged: (val) => stop["name"] = val,
            ),
            TextField(
              controller: TextEditingController(text: stop["lat"]),
              decoration: const InputDecoration(labelText: "Latitude"),
              keyboardType: TextInputType.number,
              onChanged: (val) => stop["lat"] = val,
            ),
            TextField(
              controller: TextEditingController(text: stop["lng"]),
              decoration: const InputDecoration(labelText: "Longitude"),
              keyboardType: TextInputType.number,
              onChanged: (val) => stop["lng"] = val,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text("Time: "),
                Text(
                  "${stop["time"].hour.toString().padLeft(2, '0')}:${stop["time"].minute.toString().padLeft(2, '0')}",
                ),
                IconButton(
                  icon: const Icon(Icons.access_time, color: Colors.blue),
                  onPressed: () async {
                    TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: stop["time"],
                    );
                    if (picked != null) {
                      setState(() {
                        stop["time"] = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Features Widget
  Widget _buildFeatures() {
    final features = [
      "Wi-Fi",
      "Aircond",
      "Wheelchair space",
      "Wheelchair lifts",
    ];

    return Wrap(
      spacing: 10,
      children: features.map((f) {
        final selected = selectedFeatures.contains(f);
        return ChoiceChip(
          label: Text(f),
          selected: selected,
          selectedColor: Colors.grey,
          onSelected: (val) {
            setState(() {
              if (val) {
                selectedFeatures.add(f);
              } else {
                selectedFeatures.remove(f);
              }
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Bus", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF103A74),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bus Name (readonly)
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Bus Name",
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              controller: TextEditingController(text: busName),
            ),
            const SizedBox(height: 16),

            // Stops
            const Text(
              "Stops",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Column(
              children: stops
                  .asMap()
                  .entries
                  .map<Widget>((entry) => _buildStopField(entry.key))
                  .toList(),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add Stop"),
              onPressed: () {
                setState(() {
                  stops.add({
                    "name": "",
                    "lat": "",
                    "lng": "",
                    "time": TimeOfDay.now(),
                  });
                });
              },
            ),
            const SizedBox(height: 16),

            // Duration
            DropdownButtonFormField<String>(
              value: duration.isEmpty ? null : duration,
              decoration: const InputDecoration(
                labelText: "Duration",
                border: OutlineInputBorder(),
              ),
              items:
                  const [
                    "Estimated 10-20 minutes for each stops",
                    "Estimated 10-15 minutes for each stops",
                    "Estimated 5-15 minutes for each stops",
                    "Estimated 5-10 minutes for each stops",
                  ].map((d) {
                    return DropdownMenuItem(value: d, child: Text(d));
                  }).toList(),
              onChanged: (val) => setState(() => duration = val ?? ""),
            ),

            const SizedBox(height: 16),

            // Features
            const Text(
              "Features",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildFeatures(),

            const SizedBox(height: 20),

            // Save button
            ElevatedButton(
              onPressed: _updateBus,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Save Update",
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
