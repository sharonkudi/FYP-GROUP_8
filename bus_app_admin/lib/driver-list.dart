import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'bus-schedule.dart';
import 'login-register.dart'; // For AdminLoginPage
import 'admin-drawer.dart';
import 'home-page.dart';

class DriverListPage extends StatefulWidget {
  const DriverListPage({super.key});

  @override
  State<DriverListPage> createState() => _DriverListPageState();
}

class _DriverListPageState extends State<DriverListPage> {
  int _selectedIndex = 0; // Default to Driver List page after login
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String? adminId; // 🔹 store adminId

  final List<String> _titles = [
    'Home',
    'Driver List',
    'Bus Schedule',
  ];

  @override
  void initState() {
    super.initState();
    _fetchAdminId();
  }

  void _fetchAdminId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snap = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();
      if (snap.exists) {
        setState(() {
          adminId = snap['admin_id'];
        });
      }
    }
  }

  // ✅ Logout logic
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AdminLoginPage()),
      (route) => false,
    );
  }

  // ✅ Navigate to Add Driver Page
  void _goToAddDriverPage() {
    if (adminId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddDriverPage(adminId: adminId!),
      ),
    );
  }

  // ✅ Navigate to Edit Driver Page
  void _goToEditDriverPage(String docId, Map<String, dynamic> data) {
    if (adminId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditDriverPage(docId: docId, data: data, adminId: adminId!),
      ),
    );
  }

  // ✅ Delete Driver Confirmation
  void _deleteDriver(String docId, String name, String adminId) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete $name?"),
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
              // Delete driver
              await FirebaseFirestore.instance
                  .collection('drivers')
                  .doc(docId)
                  .delete();

              // Add log using correct adminId
              await FirebaseFirestore.instance.collection('logs').add({
                'admin_id': adminId,
                'action': "Deleted driver: $name",
                'timestamp': FieldValue.serverTimestamp(),
                'localTime': DateTime.now(),
              });

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              "Yes",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}

  Widget _buildDriverList() {
    return Column(
      children: [
        // ✅ Search bar + Person-Add button
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
                            hintText: "Search by name",
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.blue),
                        onPressed: () {
                          setState(() {
                            _searchQuery =
                                _searchController.text.trim().toLowerCase();
                          });
                        },
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
                  icon: const Icon(Icons.person_add, color: Colors.blue),
                  onPressed: _goToAddDriverPage,
                ),
              ),
            ],
          ),
        ),
        // ✅ Driver List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('drivers')
                .where('ownerId',
                    isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs.where((doc) {
                final name = doc['name']?.toString().toLowerCase() ?? '';
                return _searchQuery.isEmpty || name.contains(_searchQuery);
              }).toList();

              if (docs.isEmpty) {
                return const Center(
                  child: Text("No drivers found",
                      style: TextStyle(color: Colors.white)),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final docId = docs[index].id;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: index % 2 == 0 ? Colors.white : Colors.grey[200],
                    child: ListTile(
                      title: Text(data['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("ID: ${data['idNumber'] ?? ''}"),
                          Text("Age: ${data['age'] ?? ''}"),
                          Text("Contact: ${data['contactNumber'] ?? ''}"),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _goToEditDriverPage(docId, data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _deleteDriver(docId, data['name'] ?? '', adminId!),
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
    final List<Widget> _pages = [
      const HomePage(),
      _buildDriverList(),
      const BusSchedulePage(),
    ];

    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF103A74),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Container(
        color: const Color(0xFF1A2332),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
              child: Row(
                children: const [
                  SizedBox(width: 16),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFF103A74),
                      child: Icon(Icons.directions_bus, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Bus Admin',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildDrawerItem(Icons.home, 'Home', 0),
                  _buildDrawerItem(Icons.people, 'Driver List', 1),
                  _buildDrawerItem(Icons.schedule, 'Bus Schedule', 2),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title:
                    const Text('Logout', style: TextStyle(color: Colors.white)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onTap: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.blueAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }
}

////////////////////////////////////////////////////////
// ✅ Add Driver Page
////////////////////////////////////////////////////////
class AddDriverPage extends StatefulWidget {
  final String adminId;
  const AddDriverPage({super.key, required this.adminId});

  @override
  State<AddDriverPage> createState() => _AddDriverPageState();
}

class _AddDriverPageState extends State<AddDriverPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  /// Add log to Firestore and HomePage cache
  Future<void> _addLog(String action) async {
    final now = DateTime.now();

    // Instant UI feedback handled by HomePage localLogs
    await FirebaseFirestore.instance.collection('logs').add({
      'admin_id': widget.adminId,
      'action': action,
      'timestamp': FieldValue.serverTimestamp(),
      'localTime': now,
    });
  }

  void _saveDriver() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (nameController.text.trim().isEmpty ||
        idController.text.trim().isEmpty ||
        ageController.text.trim().isEmpty ||
        contactController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('drivers').add({
      'name': nameController.text.trim(),
      'idNumber': idController.text.trim(),
      'age': int.tryParse(ageController.text.trim()) ?? 0,
      'contactNumber': contactController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'ownerId': user.uid,
    });

    await _addLog("Added driver: ${nameController.text.trim()}");

    Navigator.pop(context);
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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
        title: const Text("Add Driver"),
        backgroundColor: const Color(0xFF103A74),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField("Name", nameController),
            _buildTextField("ID Number", idController),
            _buildTextField("Age", ageController,
                keyboardType: TextInputType.number),
            _buildTextField("Contact Number", contactController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveDriver,
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
// ✅ Edit Driver Page
////////////////////////////////////////////////////////
class EditDriverPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String adminId;

  const EditDriverPage({
    super.key,
    required this.docId,
    required this.data,
    required this.adminId,
  });

  @override
  State<EditDriverPage> createState() => _EditDriverPageState();
}

class _EditDriverPageState extends State<EditDriverPage> {
  late TextEditingController nameController;
  late TextEditingController idController;
  late TextEditingController ageController;
  late TextEditingController contactController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data['name'] ?? '');
    idController = TextEditingController(text: widget.data['idNumber'] ?? '');
    ageController =
        TextEditingController(text: widget.data['age']?.toString() ?? '');
    contactController =
        TextEditingController(text: widget.data['contactNumber'] ?? '');
  }

  /// Add log to Firestore and HomePage cache
  Future<void> _addLog(String action) async {
    final now = DateTime.now();

    await FirebaseFirestore.instance.collection('logs').add({
      'admin_id': widget.adminId,
      'action': action,
      'timestamp': FieldValue.serverTimestamp(),
      'localTime': now,
    });
  }

  void _updateDriver() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('drivers')
        .doc(widget.docId)
        .update({
      'name': nameController.text.trim(),
      'idNumber': idController.text.trim(),
      'age': int.tryParse(ageController.text.trim()) ?? 0,
      'contactNumber': contactController.text.trim(),
      'ownerId': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _addLog("Updated driver: ${nameController.text.trim()}");

    Navigator.pop(context);
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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
        title: const Text("Edit Driver"),
        backgroundColor: const Color(0xFF103A74),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField("Name", nameController),
            _buildTextField("ID Number", idController),
            _buildTextField("Age", ageController,
                keyboardType: TextInputType.number),
            _buildTextField("Contact Number", contactController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateDriver,
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
