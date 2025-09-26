import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// 🔹 Import log service
import 'logs_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState(); // ✅ public, no underscore
}

class HomePageState extends State<HomePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String? adminName;
  String? adminId;

  // 🔹 Session flag shared across the app
  static bool sessionLoginLogged = false;

  // 🔹 New filter states
  String? selectedAction;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    if (currentUser != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(currentUser!.uid)
          .get();

      if (snapshot.exists) {
        setState(() {
          adminName = snapshot['name'];
          adminId = snapshot['admin_id'];
        });

        // 🔹 Log "Logged in" only once per session
        if (!HomePageState.sessionLoginLogged &&
            adminId != null &&
            adminName != null) {
          HomePageState.sessionLoginLogged = true;
          await addLog("Logged in");
        }
      }
    }
  }

  // ❌ Old log function removed, use addLog from service

  Future<void> _clearHistory() async {
    if (adminId == null) return;

    final query = await FirebaseFirestore.instance
        .collection('logs')
        .where('admin_id', isEqualTo: adminId)
        .get();

    for (var doc in query.docs) {
      await doc.reference.delete();
    }

    await addLog("Cleared history");
  }

  /// 🔹 Safely parse log time (Timestamp or DateTime)
  DateTime _parseLogTime(Map<String, dynamic> log) {
    final ts = log['timestamp'];
    final local = log['localTime'];

    if (ts is Timestamp) return ts.toDate();
    if (ts is DateTime) return ts;
    if (local is Timestamp) return local.toDate();
    if (local is DateTime) return local;

    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ✅ Centered Welcome Header
            if (adminName != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Welcome 👋",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        adminName!,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ✅ Filters Row
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: Row(
                children: [
                  // Filter by Date
                  IconButton(
                    icon: const Icon(Icons.date_range, color: Colors.blueGrey),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                  ),

                  const SizedBox(width: 8),

                  // Filter by Date
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                      icon: const Icon(
                        Icons.date_range,
                        color: Colors.blueGrey,
                      ),
                      label: Text(
                        selectedDate == null
                            ? "Filter by Date"
                            : DateFormat("MMM d, yyyy").format(selectedDate!),
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        side: const BorderSide(color: Colors.blueGrey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Filter by Action
                  DropdownButton<String>(
                    value: selectedAction,
                    hint: const Text("Action"),
                    items: ["Update", "Delete", "Add", "Assigned driver"]
                        .map(
                          (action) => DropdownMenuItem(
                            value: action,
                            child: Text(action),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => selectedAction = value);
                    },
                  ),

                  const SizedBox(width: 8),

                  // Reset Filters Button
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.redAccent),
                    tooltip: "Clear Filters",
                    onPressed: () {
                      setState(() {
                        selectedAction = null;
                        selectedDate = null;
                      });
                    },
                  ),
                ],
              ),
            ),

            // ✅ Activity Feed
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Container Header
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "History Activity",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Colors.grey),

                      // Timeline List
                      Expanded(
                        child: adminId == null
                            ? const Center(child: CircularProgressIndicator())
                            : StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('logs')
                                    .orderBy('timestamp', descending: true)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        "No history yet.",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16,
                                        ),
                                      ),
                                    );
                                  }

                                  final logs = snapshot.data!.docs
                                      .map(
                                        (doc) =>
                                            doc.data() as Map<String, dynamic>,
                                      )
                                      .toList();

                                  logs.sort(
                                    (a, b) => _parseLogTime(
                                      b,
                                    ).compareTo(_parseLogTime(a)),
                                  );

                                  // 🔹 Apply filters
                                  var filteredLogs = logs.where((log) {
                                    final date = _parseLogTime(log);
                                    final action = (log['action'] ?? "")
                                        .toString();

                                    final matchesDate =
                                        selectedDate == null ||
                                        (date.year == selectedDate!.year &&
                                            date.month == selectedDate!.month &&
                                            date.day == selectedDate!.day);

                                    final matchesAction =
                                        selectedAction == null ||
                                        action.toLowerCase().contains(
                                          selectedAction!.toLowerCase(),
                                        );

                                    return matchesDate && matchesAction;
                                  }).toList();

                                  return ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: filteredLogs.length,
                                    itemBuilder: (context, index) {
                                      final log = filteredLogs[index];
                                      final action =
                                          log['action'] ?? "Unknown action";
                                      final dateTime = _parseLogTime(log);
                                      final formatted = DateFormat(
                                        "MMM d, yyyy • hh:mm a",
                                      ).format(dateTime);

                                      Color tagColor = Colors.grey;
                                      if (action.toLowerCase().contains(
                                        "add",
                                      )) {
                                        tagColor = Colors.green;
                                      } else if (action.toLowerCase().contains(
                                        "update",
                                      )) {
                                        tagColor = Colors.orange;
                                      } else if (action.toLowerCase().contains(
                                        "delete",
                                      )) {
                                        tagColor = Colors.red;
                                      }

                                      return Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        elevation: 3,
                                        shadowColor: tagColor.withOpacity(0.2),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: tagColor
                                                .withOpacity(0.2),
                                            child: Icon(
                                              Icons.history,
                                              color: tagColor,
                                            ),
                                          ),
                                          title: Text(
                                            action,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          subtitle: Text(
                                            "${log['name'] ?? ''} (ID: ${log['admin_id'] ?? 'N/A'}) • $formatted",
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
