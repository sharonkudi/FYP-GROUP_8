import 'package:flutter/material.dart';
import 'OfflineMapPage.dart';

class NoInternetPage extends StatelessWidget {
  final Future<void> Function() onRetry;
  final VoidCallback onOfflineView;

  const NoInternetPage({
    super.key,
    required this.onRetry,
    required this.onOfflineView,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 100, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "No Internet Connection",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Please check your connection or continue with offline view.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Retry button
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
              ),

              const SizedBox(height: 12),

              // View Offline Map button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OfflineMapPage()),
                  );
                },
                icon: const Icon(Icons.map),
                label: const Text("View Offline Map"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
