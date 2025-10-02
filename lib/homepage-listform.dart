import 'dart:async';
import 'homepage-availablebuses.dart';
import 'package:bus_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:bus_app/no_internet_page.dart';
import 'package:geolocator/geolocator.dart';

class ListFormPage extends StatefulWidget {
  const ListFormPage({super.key});

  @override
  State<ListFormPage> createState() => _ListFormPageState();
}

class _ListFormPageState extends State<ListFormPage>
    with AutomaticKeepAliveClientMixin {
  final fromController = TextEditingController();
  final toController = TextEditingController();

  final List<String> locations = [
    'The Mall Gadong',
    'Ong Sum Ping',
    'PB School',
    'Yayasan Complex',
    'Kianggeh',
    'Ministry of Finance',
  ];

  final List<Map<String, dynamic>> _allStops = [
    {'name': 'The Mall Gadong', 'lat': 4.868942, 'lng': 114.903128}, // change to ur lat/lng here
    {'name': 'Yayasan Complex', 'lat': 4.888581361818439, 'lng': 114.94048600605531},
    {'name': 'Kianggeh', 'lat': 4.8892108308087385, 'lng': 114.94433682090414},
    {'name': 'Ong Sum Ping', 'lat': 4.90414222577477, 'lng': 114.93627988813594},
    {'name': 'PB School', 'lat': 4.904922563115028, 'lng': 114.9332865430959},
    {'name': 'Ministry of Finance', 'lat': 4.915056711681162, 'lng': 114.95226715214645},
  ];

  final Map<String, List<String>> stopGroups = {
    "PB School": ["PB School", "Ong Sum Ping"],
    "Ong Sum Ping": ["Ong Sum Ping", "PB School"],
  };

  late List<Map<String, dynamic>> _displayedStops;
Position? _userPosition;
StreamSubscription<Position>? _positionStream;
Timer? _locationTimer;

String? selectedFrom;
String? selectedTo;
StreamSubscription<ServiceStatus>? _serviceStatusStream;

bool _hasLocationPermission = false;
bool _locationPopupShown = false; // ✅ unified flag to prevent multiple popups

@override
void initState() {
  super.initState();

  _displayedStops = List<Map<String, dynamic>>.from(_allStops);

  _initLocation();

  // Stream for position updates
  _positionStream = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    ),
  ).listen((position) {
    if (mounted) setState(() => _userPosition = position);
  });

  // Stream for service status changes
  _serviceStatusStream = Geolocator.getServiceStatusStream().listen(
    (status) async {
      if (!mounted) return;

      // Location service disabled
      if (status == ServiceStatus.disabled && !_locationPopupShown) {
        _locationPopupShown = true;

        // Open system location settings
        await Geolocator.openLocationSettings();

        // Small delay to prevent rapid re-trigger
        await Future.delayed(const Duration(seconds: 2));

        _locationPopupShown = false;
      }
    },
  );

  // Timer to periodically get position if permission is granted
  _locationTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
    if (!mounted || !_hasLocationPermission) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) setState(() => _userPosition = position);
    } catch (_) {
      // ignore errors (likely no permission)
    }
  });
}

// ✅ Unified method to initialize location permission & first position
Future<void> _initLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled && !_locationPopupShown) {
    _locationPopupShown = true;
    await Geolocator.openLocationSettings();
    await Future.delayed(const Duration(seconds: 2));
    _locationPopupShown = false;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return; // user didn't enable, stop here
  }

  // Check permission
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) return;

  _hasLocationPermission = true;

  // Get initial position
  final position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
  if (mounted) setState(() => _userPosition = position);
}

@override
void dispose() {
  _positionStream?.cancel();
  _serviceStatusStream?.cancel();
  _locationTimer?.cancel();
  super.dispose();
}


  @override
  bool get wantKeepAlive => true;

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters == double.infinity) return 'Locating...';
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m away';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(2)} km away';
    }
  }

  double _calculateDistance(double lat, double lng) {
    if (_userPosition == null) return double.infinity;
    return Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      lat,
      lng,
    );
  }

  bool _matchesQuery(String name, String query) {
    final lowerName = name.toLowerCase();
    final tokens =
        query.toLowerCase().split(RegExp(r'[\s,]+')).where((t) => t.isNotEmpty);
    for (final t in tokens) {
      if (lowerName.contains(t)) return true;
    }
    return false;
  }

  void _applyFilter() {
    if ((selectedFrom == null || selectedFrom!.isEmpty) &&
        (selectedTo == null || selectedTo!.isEmpty)) {
      setState(() {
        _displayedStops = List<Map<String, dynamic>>.from(_allStops);
      });
      return;
    }

    setState(() {
      _displayedStops = _allStops.where((stop) {
        final name = stop['name'] ?? '';

        final toTargets = selectedTo != null && selectedTo!.isNotEmpty
            ? (stopGroups[selectedTo] ?? [selectedTo!])
            : [];

        final fromTargets = selectedFrom != null && selectedFrom!.isNotEmpty
            ? (stopGroups[selectedFrom] ?? [selectedFrom!])
            : [];

        final fromOk = fromTargets.isNotEmpty &&
            fromTargets.any((target) => _matchesQuery(name, target));
        final toOk = toTargets.isNotEmpty &&
            toTargets.any((target) => _matchesQuery(name, target));

        return fromOk || toOk;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final loc = AppLocalizations.of(context)!;

    _displayedStops.sort((a, b) {
      final distA = _calculateDistance(a['lat'], a['lng']);
      final distB = _calculateDistance(b['lat'], b['lng']);
      return distA.compareTo(distB);
    });

    return Container(
      color: const Color(0xFF103A74),
      child: Column(
        children: [
          if (_userPosition != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lat: ${_userPosition!.latitude.toStringAsFixed(5)}, Lng: ${_userPosition!.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          // Destination Search Row
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedTo,  // Use `value` here instead of `initialValue`
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: loc.destination, // Localized
                      prefixIcon: const Icon(Icons.flag,
                          color: Color.fromARGB(255, 94, 105, 120)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: locations
                        .map((locName) => DropdownMenuItem<String>(
                              value: locName,
                              child: Text(locName, overflow: TextOverflow.ellipsis),
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
                    onPressed: () {
                      if (selectedTo != null) {
                        setState(() {
                          List<String> groupStops =
                              stopGroups[selectedTo] ?? [selectedTo!];

                          _displayedStops = _allStops.where((stop) {
                            return groupStops.contains(stop['name']);
                          }).toList();
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(loc.selectDestination), // Localized
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Title row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.busStopsNearMe, // Localized
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 28, 105, 168),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {
                    setState(() {
                      _displayedStops = List<Map<String, dynamic>>.from(_allStops);
                      selectedFrom = null;
                      selectedTo = null;
                    });
                  },
                  child: Text(
                    loc.viewAll, // Localized
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // List of bus stops
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _displayedStops.length,
              itemBuilder: (context, index) {
                final stop = _displayedStops[index];
                final name = stop['name']!;
                final lat = stop['lat'] as double?;
                final lng = stop['lng'] as double?;

                final distance = (lat != null && lng != null)
                    ? _calculateDistance(lat, lng)
                    : double.infinity;
                final distanceText = _formatDistance(distance);

                final isNearby = distance <= 900;

                return BusStopCard(
                  name: name,
                  distance: distanceText,
                  onView: isNearby
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AvailableBusesPage(busStopName: name),
                            ),
                          );
                        }
                      : null,
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
    final loc = AppLocalizations.of(context)!;

    return Card(
      color: Colors.white,
      child: ListTile(
        leading: const Icon(Icons.directions_bus, color: Color(0xFF103A74)),
        title: Text(name, style: const TextStyle(color: Colors.black)),
        subtitle: Text(distance, style: const TextStyle(color: Colors.black54)),
        trailing: ElevatedButton(
          onPressed: onView,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                onView == null ? Colors.grey : const Color(0xFF103A74),
          ),
          child: Text(loc.view),
        ),
      ),
    );
  }
}
