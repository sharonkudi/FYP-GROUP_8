import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class OfflineMapPage extends StatelessWidget {
  const OfflineMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Offline Map")),
      body: Column(
        children: [
          Expanded(
            child: PhotoView(
              imageProvider: const AssetImage("assets/offline_map.png"),
              backgroundDecoration: const BoxDecoration(
                color: Colors.white, // set background
              ),
              minScale:
                  PhotoViewComputedScale.contained, // fit image inside screen
              maxScale: PhotoViewComputedScale.covered * 4, // zoom up to 4x
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "This is your offline map",
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Back"),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
