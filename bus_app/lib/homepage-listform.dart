import 'package:flutter/material.dart';
import 'homepage-availablebuses.dart'; // Make sure this import is at the top

class ListFormPage extends StatefulWidget {
  const ListFormPage({super.key});

  @override
  State<ListFormPage> createState() => _ListFormPageState();
}

class _ListFormPageState extends State<ListFormPage> {
  final fromController = TextEditingController();
  final toController = TextEditingController();

  // Your dropdown source list (you can add more names here)
  final List<String> locations = [
    'The Mall Gadong',
    'Ong Sum Ping',
    'PB School',
    'Yayasan Complex',
    'Kianggeh',
    'Ministry of Finance',
  ];

  // Bus stops shown in "Bus Stops near me"
  final List<Map<String, String>> _allStops = const [
    {'name': 'The Mall Gadong', 'distance': '100m away'},
    {'name': 'Yayasan Complex', 'distance': '1km away'},
    {'name': 'Kianggeh', 'distance': '500m away'},
    {'name': 'Ong Sum Ping', 'distance': '2km away'},
    {'name': 'PB School', 'distance': '1.5km away'},
    {'name': 'Ministry Of Finance', 'distance': '3.5km away'},
  ];

  late List<Map<String, String>> _displayedStops;

  String? selectedFrom;
  String? selectedTo;

  @override
  void initState() {
    super.initState();
    _displayedStops = List<Map<String, String>>.from(_allStops);
  }

  bool _matchesQuery(String name, String query) {
    final lowerName = name.toLowerCase();
    final tokens = query.toLowerCase().split(RegExp(r'[\s,]+')).where((t) => t.isNotEmpty);
    for (final t in tokens) {
      if (lowerName.contains(t)) return true;
    }
    return false;
  }

  void _applyFilter() {
  if ((selectedFrom == null || selectedFrom!.isEmpty) &&
      (selectedTo == null || selectedTo!.isEmpty)) {
    setState(() {
      _displayedStops = List<Map<String, String>>.from(_allStops);
    });
    return;
  }

  setState(() {
    _displayedStops = _allStops.where((stop) {
      final name = stop['name'] ?? '';
      final fromOk = (selectedFrom != null &&
          _matchesQuery(name, selectedFrom!));
      final toOk = (selectedTo != null &&
          _matchesQuery(name, selectedTo!));

      return fromOk || toOk;
    }).toList();
  });
}

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF103A74),
      child: Column(
        children: [
          // Search Row
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedFrom,
                    isExpanded: true, // avoids overflow
                    decoration: const InputDecoration(
                      labelText: 'From',
                      prefixIcon: Icon(Icons.directions_bus_filled,
                          color: Color.fromARGB(255, 94, 105, 120)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: locations
                        .map((loc) => DropdownMenuItem<String>(
                              value: loc,
                              child: Text(loc, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedFrom = val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedTo,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'To',
                      prefixIcon: Icon(Icons.flag,
                          color: Color.fromARGB(255, 94, 105, 120)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: locations
                        .map((loc) => DropdownMenuItem<String>(
                              value: loc,
                              child: Text(loc, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedTo = val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: _applyFilter,
                  ),
                ),
              ],
            ),
          ),
          // Title row with "Bus Stops near me" and "View All"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bus Stops near me',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 28, 105, 168), // button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // corner radius
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {
                    setState(() {
                      _displayedStops = List<Map<String, String>>.from(_allStops);
                      selectedFrom = null;
                      selectedTo = null;
                    });
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _displayedStops.length,
              itemBuilder: (context, index) {
                final stop = _displayedStops[index];
                final name = stop['name']!;
                final distance = stop['distance']!;

                // Preserve your original behavior: only "The Mall Gadong" had an active View button
                final VoidCallback? onView =
                    (name == 'The Mall Gadong')
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                // kept the same hard-coded parameter from your original code
                                builder: (context) =>
                                    AvailableBusesPage(busStopName: 'Ong Sum Ping'),
                              ),
                            );
                          }
                        : null;

                return BusStopCard(
                  name: name,
                  distance: distance,
                  onView: onView,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BusStopCard extends StatelessWidget {
  final String name;
  final String distance;
  final VoidCallback? onView;

  const BusStopCard({
    super.key,
    required this.name,
    required this.distance,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading:
            const Icon(Icons.directions_bus, color: Color(0xFF103A74)),
        title: Text(name, style: const TextStyle(color: Colors.black)),
        subtitle:
            Text(distance, style: const TextStyle(color: Colors.black54)),
        trailing: ElevatedButton(
          onPressed: onView, // stays disabled when null, same as before
          child: const Text('View'),
        ),
      ),
    );
  }
}
