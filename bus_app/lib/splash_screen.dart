import 'package:flutter/material.dart';

/// Simple splash screen that waits [duration], checks connectivity,
/// then calls [onFinish] with true/false (hasInternet).
class SplashScreen extends StatefulWidget {
  final ValueChanged<bool> onFinish;
  final Duration duration;
  final String? logoAsset; // optional: e.g. 'assets/logo.png'

  const SplashScreen({
    Key? key,
    required this.onFinish,
    this.duration = const Duration(seconds: 5),
    this.logoAsset,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // keep splash visible for the configured duration
    await Future.delayed(widget.duration);

    if (!mounted) return;
    widget.onFinish(true);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      body: Container(
        color: Color(0xFF103A74),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.logoAsset != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Image.asset(
                    widget.logoAsset!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child:
                      Icon(Icons.directions_bus, size: 96, color: Colors.white),
                ),
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              const Text(
                'Your Ride, Made Simple!',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
