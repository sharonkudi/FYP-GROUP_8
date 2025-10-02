import 'package:bus_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class OfflineMapPage extends StatelessWidget {
  const OfflineMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(local.offlineMap)),

      // 🔹 Full screen map with unlimited zoom
      body: PhotoView(
        imageProvider: const AssetImage("assets/offline_map.png"),
        backgroundDecoration: const BoxDecoration(
          color: Colors.white,
        ),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 100, // unlimited zoom
      ),

      // 🔹 Fixed buttons at the bottom
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OfflineMapPage(),
                  ),
                );
              },
              child: Text(local.offlineSystemMap),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OfflineBusSchedulePage(),
                  ),
                );
              },
              child: Text(local.offlineBusSchedule),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔹 Example Offline Bus Schedule Page (can be replaced with hybrid Firestore + JSON)
class OfflineBusSchedulePage extends StatelessWidget {
  const OfflineBusSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    final List<Map<String, String>> schedule = [
      {
        "bus": "Bus A",
        "route":
            "08:00AM - The Mall Gadong → 08:05AM - Ong Sum Ping → 08:10AM - PB School → 08:15AM - Kianggeh → 08:20AM - The Mall Gadong",
        "time": "08:00AM - 08:20AM"
      },
      {
        "bus": "Bus B",
        "route":
            "08:00AM - Kianggeh → 08:07AM - Yayasan Complex → 08:12AM - Ministry of Finance → 08:15AM - Kianggeh",
        "time": "08:00AM - 08:15AM"
      },
    ];

    return Scaffold(
      appBar: AppBar(title: Text(local.offlineBusSchedule)),
      body: ListView.builder(
        itemCount: schedule.length,
        itemBuilder: (context, index) {
          final bus = schedule[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: const Icon(Icons.directions_bus, color: Colors.blue),
              title: Text(bus["bus"]!),
              subtitle: Text(bus["route"]!),
              trailing: Text(
                bus["time"]!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}
