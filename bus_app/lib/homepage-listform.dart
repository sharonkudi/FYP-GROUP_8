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

  final List<String> locations = [
    'BS Ong Sum Ping',
    'Mall, BSB',
    'Times Square, BSB',
    'Kianggeh, BSB',
    'Baid Polas, BSB',
    // Add more locations as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF103A74),
      child: Column(
        children: [
          // Search Row
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      return locations.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'From',
                          prefixIcon: Icon(Icons.directions_bus_filled, color: Color.fromARGB(255, 94, 105, 120)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      );
                    },
                    onSelected: (String selection) {
                      // Handle selection if needed
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      return locations.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'To',
                          prefixIcon: Icon(Icons.flag, color: Color.fromARGB(255, 94, 105, 120)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      );
                    },
                    onSelected: (String selection) {
                      // Handle selection if needed
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    setState(() {});
                  },
                )
              ],
            ),
          ),
          // Bus Stops List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Bus Stops near me',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                BusStopCard(
                  name: 'The Mall Gadong',
                  distance: '100m away',
                  onView: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AvailableBusesPage(busStopName: 'Ong Sum Ping'),
                      ),
                    );
                  },
                ),
                const BusStopCard(name: 'Yayasan Complex', distance: '1km away'),
                const BusStopCard(name: 'Kianggeh', distance: '2.5km away'),
              ],
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
        leading: const Icon(Icons.directions_bus, color: Color(0xFF103A74)),
        title: Text(name, style: const TextStyle(color: Colors.black)),
        subtitle: Text(distance, style: const TextStyle(color: Colors.black54)),
        trailing: ElevatedButton(
          onPressed: onView,
          child: const Text('View'),
        ),
      ),
    );
  }
}