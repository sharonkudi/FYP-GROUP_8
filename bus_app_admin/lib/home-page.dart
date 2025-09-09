import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String? adminName;
  String? adminId;

  // 🔹 Track if login log has already been added
  bool _loginLogged = false;

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

      // 🔹 Log "Logged in" only once per day (or session)
      if (adminId != null) {
        final todayStart = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );

        final query = await FirebaseFirestore.instance
            .collection('logs')
            .where('admin_id', isEqualTo: adminId)
            .where('action', isEqualTo: "Logged in")
            .where('localTime', isGreaterThanOrEqualTo: todayStart)
            .get();

        if (query.docs.isEmpty) {
          await _addLog("Logged in");
        }
      }
    }
  }
}

  Future<void> _addLog(String action) async {
    if (adminId == null) return;

    await FirebaseFirestore.instance.collection('logs').add({
      'admin_id': adminId,
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (adminName != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    const Text(
                      "Welcome back 👋",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      adminName!,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                          "Are you sure you want to clear your entire history?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel",
                              style: TextStyle(color: Colors.grey)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Yes, Clear",
                              style: TextStyle(color: Colors.red)),
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
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: adminId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('logs')
                        .where('admin_id', isEqualTo: adminId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text("No history yet.",
                                style: TextStyle(color: Colors.grey)));
                      }

                      final logs = snapshot.data!.docs
                          .map((doc) => doc.data() as Map<String, dynamic>)
                          .toList();

                      // Sort logs descending by normalized DateTime
                      logs.sort((a, b) =>
                          _parseLogTime(b).compareTo(_parseLogTime(a)));

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final action = log['action'] ?? "Unknown action";
                          final dateTime = _parseLogTime(log);

                          final formatted =
                              DateFormat("MMM d, yyyy • hh:mm a")
                                  .format(dateTime);

                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: ListTile(
                              leading:
                                  const Icon(Icons.history, color: Colors.blue),
                              title: Text(action,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                formatted,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
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
    );
  }
}
