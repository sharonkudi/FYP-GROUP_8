import 'package:bus_app/homepage-availablebuses.dart';
import 'package:flutter/material.dart';

class StopsListPage extends StatelessWidget {
  const StopsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stops = const [
      {'name': 'The Mall Gadong', 'schedule': 'Every 20 min'},
      {'name': 'Ong Sum Ping', 'schedule': 'Every 20 min'},
      {'name': 'PB School', 'schedule': 'Every 20 min'},
      {'name': 'Yayasan Complex', 'schedule': 'Every 20 min'},
      {'name': 'Kianggeh', 'schedule': 'Every 20 min'},
      {'name': 'Ministry of Finance', 'schedule': 'Every 20 min'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: stops.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final s = stops[i];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.directions_bus, color: Color(0xFF103A74)),
            title: Text(s['name']!),
            subtitle: Text('Schedule: ${s['schedule']}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate only if the stop is "The Mall Gadong"
              if (s['name'] == 'The Mall Gadong') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AvailableBusesPage(busStopName: s['name']!),
                  ),
                );
              } else {
                // Optional: handle other stops if needed
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No buses available for ${s['name']}')),
                );
              }
            },
          ),
        );
      },
    );
  }
}
