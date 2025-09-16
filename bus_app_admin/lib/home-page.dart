import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
        if (!HomePageState.sessionLoginLogged && adminId != null) {
          HomePageState.sessionLoginLogged = true;
          await _addLog("Logged in");
        }
      }
    }
  }

  Future<void> _addLog(String action) async {
    if (adminId == null) return;

    await FirebaseFirestore.instance.collection('logs').add({
      'admin_id': adminId,
      'admin_name': adminName, // ✅ so logs can show who did it
      'action': action,
      'timestamp': FieldValue.serverTimestamp(),
      'localTime': DateTime.now(),
    });
  }

  Future<void> _clearHistory() async {
    if (adminId == null) return;

    final query = await FirebaseFirestore.instance
        .collection('logs')
        .where('admin_id', isEqualTo: adminId)
        .get();

    for (var doc in query.docs) {
      await doc.reference.delete();
    }

    await _addLog("Cleared history");
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
                        "Welcome back 👋",
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

            // ✅ Clear History Button
            if (adminId != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Clear History"),
                        content: const Text(
                          "Are you sure you want to clear your entire history?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text(
                              "Yes, Clear",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await _clearHistory();
                    }
                  },
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("Clear History"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // ✅ Activity Feed Container with Label
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

                                  return ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: logs.length,
                                    itemBuilder: (context, index) {
                                      final log = logs[index];
                                      final action =
                                          log['action'] ?? "Unknown action";
                                      final dateTime = _parseLogTime(log);
                                      final formatted = DateFormat(
                                        "MMM d, yyyy • hh:mm a",
                                      ).format(dateTime);

                                      Color tagColor = Colors.grey;
                                      if (action.toLowerCase().contains(
                                        "added",
                                      )) {
                                        tagColor = Colors.green;
                                      } else if (action.toLowerCase().contains(
                                        "updated",
                                      )) {
                                        tagColor = Colors.orange;
                                      } else if (action.toLowerCase().contains(
                                        "deleted",
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
                                            "${log['admin_name'] ?? log['admin_id']} • $formatted",
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
