import 'package:flutter/material.dart';
import 'homepage-busroute.dart';

class AvailableBusesPage extends StatelessWidget {
  final String busStopName;

  const AvailableBusesPage({super.key, required this.busStopName});

  @override
  Widget build(BuildContext context) {
    // Example static data; replace with your actual data source if needed
    final buses = [
      {
        'name': 'Bas A',
        'time': '1:00PM - 1:25PM',
        'route': '$busStopName to BS Mall',
        'duration': 'eta: 18 min',
        'features': [Icons.accessible, Icons.wifi]
      },
      {
        'name': 'Bas B',
        'time': '1:45PM - 2:05PM',
        'route': '$busStopName to BS Mall',
        'duration': 'eta: 20 min',
        'features': [Icons.wifi]
      },
    ];

    return Scaffold(
  appBar: AppBar(
  title: const Text(
    'Available Buses',
    style: TextStyle(color: Colors.white), // Change text color here
  ),
  backgroundColor: Color(0xFF103A74),
  iconTheme: IconThemeData(color: Colors.white), // Optional: change drawer icon color
),
  body: ListView.builder(
    itemCount: buses.length,
    itemBuilder: (context, index) {
      final bus = buses[index] as Map<String, dynamic>;
      return GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => BusDetailsSheet(bus: bus),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bus['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Available',
                        style: TextStyle(
                          color: Color.fromARGB(255, 42, 49, 141), // here
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Time & route
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      bus['time'],
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.alt_route, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      bus['route'],
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Duration & features
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        bus['duration'],
                        style: const TextStyle(fontSize: 13, color: Colors.blue),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: (bus['features'] as List<IconData>)
                          .map((icon) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(icon, size: 18, color: Colors.blue),
                              ))
                          .toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

  }
}

class BusDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> bus;

  const BusDetailsSheet({super.key, required this.bus});

  @override
Widget build(BuildContext context) {
  return FractionallySizedBox(
    heightFactor: 0.5, // Half of the screen height
    child: Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Card design similar to the first layout
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT INFO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bus['route'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                'Depart: ${bus['time'].toString().split('-')[0].trim()}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.flag, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                'Arrive: ${bus['time'].toString().split('-')[1].trim()}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.directions_bus, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                'Bus Number: ${bus['name']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            children: const [
                              Icon(Icons.person, size: 16, color: Colors.grey),
                              SizedBox(width: 4),
                              Text(
                                'Driver: Mr Singh',
                                style: TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // RIGHT INFO
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          bus['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: const [
                              Text(
                                'Total:',
                                style: TextStyle(fontSize: 12, color: Colors.black),
                              ),
                              Text(
                                '\$1',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // View Bus button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BusRoutePage(
                        busId: 'bus123',      // example busId
                        stops: [BusStop(name: 'Stop 1', eta: '5 min', lat: 1.3521, lng: 103.8198),
        BusStop(name: 'Stop 2', eta: '10 min', lat: 1.3550, lng: 103.8200),],            // empty list for now
                        ),
                      ),
                    );
                  },
                child: const Text('View Bus', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}