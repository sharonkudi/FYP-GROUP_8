import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBusSchedulePage extends StatefulWidget {
  const AdminBusSchedulePage({super.key});

  @override
  State<AdminBusSchedulePage> createState() => _AdminBusSchedulePageState();
}

class _AdminBusSchedulePageState extends State<AdminBusSchedulePage> {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  void _performSearch() {
    setState(() {
      searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[300],
                      hintText: "Search buses & routes",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _performSearch,
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('buses').snapshots(),
        builder: (context, busSnapshot) {
          if (!busSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var buses = busSnapshot.data!.docs;

          // 🔎 Apply search filter only when searchQuery is set
          buses = buses.where((bus) {
            final busName = bus['bus_name'].toString().toLowerCase();
            final route = bus['route'].toString().toLowerCase();
            final time = bus['time'].toString().toLowerCase();
            return busName.contains(searchQuery) ||
                route.contains(searchQuery) ||
                time.contains(searchQuery);
          }).toList();

          // Collect all assigned drivers
          final assignedDrivers = buses
              .map((bus) => bus['assignedTo'] ?? "")
              .where((name) => name.toString().isNotEmpty)
              .toSet();

          return ListView.builder(
            itemCount: buses.length,
            itemBuilder: (context, index) {
              var bus = buses[index];
              var busId = bus.id;
              var currentAssigned = bus['assignedTo'] ?? "";

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text("${bus['bus_name']} | ${bus['route']}"),
                  subtitle: Text("Time: ${bus['time']}"),
                  trailing: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('drivers')
                        .snapshots(),
                    builder: (context, driverSnapshot) {
                      if (!driverSnapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      var drivers = driverSnapshot.data!.docs;
                      var driverNames = drivers
                          .map((doc) => doc['name'].toString())
                          .toList();

                      // ✅ If assigned driver no longer exists → clear it in Firestore
                      if (currentAssigned.isNotEmpty &&
                          !driverNames.contains(currentAssigned)) {
                        FirebaseFirestore.instance
                            .collection('buses')
                            .doc(busId)
                            .update({'assignedTo': ""});
                        currentAssigned = "";
                      }

                      // Restrict: remove drivers already assigned elsewhere
                      var availableDrivers = driverNames
                          .where(
                            (name) =>
                                !assignedDrivers.contains(name) ||
                                name == currentAssigned,
                          )
                          .toList();

                      // Add "Clear Assignment" option
                      availableDrivers.insert(0, "Clear Assignment");

                      return DropdownButton<String>(
                        value: currentAssigned.isNotEmpty
                            ? currentAssigned
                            : null,
                        hint: const Text("Assign Driver"),
                        items: availableDrivers.map((name) {
                          return DropdownMenuItem(
                            value: name == "Clear Assignment" ? "" : name,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          FirebaseFirestore.instance
                              .collection('buses')
                              .doc(busId)
                              .update({'assignedTo': value ?? ""});
                        },
                      );
                    },
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
