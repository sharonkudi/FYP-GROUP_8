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

  // ✅ Auto generate bus ID (BUS001, BUS002, ...)
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

  // ✅ Navigate to Add Bus Page
  void _goToAddBusPage() async {
    final busId = await _generateBusId();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddBusPage(busId: busId)),
    );
  }

  // ✅ Navigate to Edit Bus Page
  void _goToEditBusPage(String docId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditBusPage(docId: docId, data: data),
      ),
    );
  }

  // ✅ Delete Bus
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
        // ✅ Search bar + Add button
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
                            hintText: "Search bus name / route",
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
        // ✅ Bus List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('buses').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['bus_name']?.toString().toLowerCase() ?? '';
                final route = data['route']?.toString().toLowerCase() ?? '';
                return _searchQuery.isEmpty ||
                    name.contains(_searchQuery) ||
                    route.contains(_searchQuery);
              }).toList();

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    "No bus schedules found",
                    style: TextStyle(color: Colors.white),
                  ),
                );
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
                  final currentAssigned = data['assignedTo'] ?? '';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: index % 2 == 0 ? Colors.white : Colors.grey.shade200,
                    child: ListTile(
                      title: Text(
                        "${data['bus_name']} (${busId})",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Route: ${data['route'] ?? ''}"),
                          Text("Duration: ${data['duration'] ?? ''}"),
                          Text("Features: ${data['features'] ?? ''}"),
                          Text("Time: ${data['time'] ?? ''}"),
                          Text(
                            "Assigned: ${currentAssigned.isEmpty ? '-' : currentAssigned}",
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 🔹 Assign driver dropdown
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

                              // clear invalid driver
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

                              availableDrivers.insert(0, "Clear Assignment");

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

                          // 🔹 Edit button
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _goToEditBusPage(docId, data),
                          ),

                          // 🔹 Delete button
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _deleteBus(docId, data['bus_name'], busId),
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
// ✅ Add Bus Page
////////////////////////////////////////////////////////
class AddBusPage extends StatefulWidget {
  final String busId;
  const AddBusPage({super.key, required this.busId});

  @override
  State<AddBusPage> createState() => _AddBusPageState();
}

class _AddBusPageState extends State<AddBusPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController routeController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController featuresController = TextEditingController();

  void _saveBus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (nameController.text.trim().isEmpty ||
        routeController.text.trim().isEmpty ||
        timeController.text.trim().isEmpty)
      return;

    await FirebaseFirestore.instance.collection('buses').add({
      'bus_id': widget.busId,
      'bus_name': nameController.text.trim(),
      'route': routeController.text.trim(),
      'time': timeController.text.trim(),
      'duration': durationController.text.trim(),
      'features': featuresController.text.trim(),
      'assignedTo': "",
      'createdAt': FieldValue.serverTimestamp(),
      'ownerId': user.uid,
    });

    await addLog(
      "Added bus schedule: ${nameController.text.trim()} (${widget.busId})",
    );

    Navigator.pop(context);
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField("Bus Name", nameController),
            _buildTextField("Route", routeController),
            _buildTextField("Time", timeController),
            _buildTextField("Duration", durationController),
            _buildTextField("Features", featuresController),
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

////////////////////////////////////////////////////////
// ✅ Edit Bus Page
////////////////////////////////////////////////////////
class EditBusPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  const EditBusPage({super.key, required this.docId, required this.data});

  @override
  State<EditBusPage> createState() => _EditBusPageState();
}

class _EditBusPageState extends State<EditBusPage> {
  late TextEditingController nameController;
  late TextEditingController routeController;
  late TextEditingController timeController;
  late TextEditingController durationController;
  late TextEditingController featuresController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data['bus_name'] ?? '');
    routeController = TextEditingController(text: widget.data['route'] ?? '');
    timeController = TextEditingController(text: widget.data['time'] ?? '');
    durationController = TextEditingController(
      text: widget.data['duration'] ?? '',
    );
    featuresController = TextEditingController(
      text: widget.data['features'] ?? '',
    );
  }

  void _updateBus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('buses')
        .doc(widget.docId)
        .update({
          'bus_name': nameController.text.trim(),
          'route': routeController.text.trim(),
          'time': timeController.text.trim(),
          'duration': durationController.text.trim(),
          'features': featuresController.text.trim(),
          'ownerId': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });

    await addLog(
      "Updated bus schedule: ${nameController.text.trim()} (${widget.data['bus_id']})",
    );

    Navigator.pop(context);
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField("Bus Name", nameController),
            _buildTextField("Route", routeController),
            _buildTextField("Time", timeController),
            _buildTextField("Duration", durationController),
            _buildTextField("Features", featuresController),
            const SizedBox(height: 20),
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
