import 'dart:async';
import 'package:bus_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'homepage-busroute.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AvailableBusesPage extends StatefulWidget {
  final String busStopName;
  const AvailableBusesPage({super.key, required this.busStopName});

  @override
  State<AvailableBusesPage> createState() => _AvailableBusesPageState();
}

class _AvailableBusesPageState extends State<AvailableBusesPage> {
  Future<void> _refreshBuses() async {
    await FirebaseFirestore.instance.collection('buses').get();
    setState(() {});
  }

  final Set<String> _selectedFareBusIds = {};
  int _adultCount = 0;
  int _childCount = 0;

  double get totalFare =>
      ((_adultCount * 1.0) + (_childCount * 0.5)) * _selectedFareBusIds.length;

  String fareBreakdown(AppLocalizations loc) {
    if (_selectedFareBusIds.isEmpty || (_adultCount == 0 && _childCount == 0))
      return "";
    return "($_adultCount ${loc.adults} + $_childCount ${loc.childrenSeniors}) × ${_selectedFareBusIds.length} bus(es)";
  }

  String _formatTime(String time24h) {
    try {
      final t = DateFormat("HH:mm").parse(time24h);
      return DateFormat("h:mm a").format(t);
    } catch (_) {
      return time24h;
    }
  }

  // 🔹 Localization helpers
  String localizeBusName(BuildContext context, String busName) {
    final loc = AppLocalizations.of(context)!;
    if (busName.toLowerCase().startsWith('bus ')) {
      return '${loc.busPrefix} ${busName.substring(4)}';
    }
    return busName;
  }

  String localizeFeature(BuildContext context, String feature) {
    final loc = AppLocalizations.of(context)!;
    final clean =
        feature.toLowerCase().replaceAll(RegExp(r'[-_\s]'), '').trim();
    switch (clean) {
      case 'wifi':
      case 'wi-fi':
        return loc.wifi;
      case 'aircond':
      case 'aircon':
      case 'ac':
        return loc.aircond;
      case 'wheelchairlifts':
        return loc.wheelchairLifts;
      case 'wheelchairspace':
        return loc.wheelchairSpace;
      default:
        return feature;
    }
  }

  String localizeDuration(BuildContext context, String duration) {
    final loc = AppLocalizations.of(context)!;
    final lower = duration.toLowerCase();
    if (lower.contains('5-10')) return loc.duration_5_10;
    if (lower.contains('5-15')) return loc.duration_5_15;
    if (lower.contains('10-15')) return loc.duration_10_15;
    if (lower.contains('10-20')) return loc.duration_10_20;
    return duration;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.availableBuses,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF103A74),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('buses')
                  .orderBy('bus_id')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final buses = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final stops = (data['stops'] as List<dynamic>? ?? [])
                      .map((s) => Map<String, dynamic>.from(s))
                      .toList();

                  final routeNames =
                      stops.map((s) => s['name'] ?? '').join(' - ');
                  final scheduleStr = stops
                      .map((s) =>
                          "${s['name']} (${_formatTime(s['time'] ?? 'N/A')})")
                      .join(". ");

                  final features =
                      (data['features'] as List<dynamic>? ?? []).cast<String>();

                  return {
                    'docId': doc.id,
                    'id': data['bus_id'] ?? doc.id,
                    'name': data['bus_name'] ?? 'Unknown Bus',
                    'route': routeNames.isNotEmpty ? routeNames : 'N/A',
                    'time': scheduleStr,
                    'duration': data['duration'] ?? 'N/A',
                    'assignedTo': data['assignedTo'] ?? '',
                    'features': features,
                  };
                }).toList();

                return RefreshIndicator(
                  onRefresh: _refreshBuses,
                  child: ListView.builder(
                    itemCount: buses.length,
                    itemBuilder: (context, index) {
                      final bus = buses[index];
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
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        localizeBusName(context, bus['name']),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            color: Colors.black87),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(loc.available,
                                          style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(bus['time'],
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700]),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.alt_route,
                                        size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(bus['route'],
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600]),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                                if (bus['features'] != null &&
                                    (bus['features'] as List).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: (bus['features'] as List)
                                          .map<Widget>((f) => Chip(
                                                label: Text(localizeFeature(
                                                    context, f.toString())),
                                                backgroundColor:
                                                    Colors.blue.shade50,
                                                labelStyle: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blue),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        localizeDuration(
                                            context, bus['duration']),
                                        style: const TextStyle(
                                            fontSize: 13, color: Colors.blue),
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
              },
            ),
          ),
          // --- Fare estimator section (unchanged) ---
          Card(
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('buses')
                    .orderBy('bus_id')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final buses = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {
                      'docId': doc.id,
                      'id': data['bus_id'] ?? doc.id,
                      'name': data['bus_name'] ?? (data['bus_id'] ?? doc.id),
                    };
                  }).toList();

                  return ExpansionTile(
                    title: Text(loc.fareEstimator,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(loc.adults),
                                DropdownButton<int>(
                                  value: _adultCount,
                                  items: List.generate(11, (i) => i)
                                      .map((i) => DropdownMenuItem(
                                          value: i, child: Text(i.toString())))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _adultCount = v ?? 0),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(loc.childrenSeniors),
                                DropdownButton<int>(
                                  value: _childCount,
                                  items: List.generate(11, (i) => i)
                                      .map((i) => DropdownMenuItem(
                                          value: i, child: Text(i.toString())))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _childCount = v ?? 0),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: buses.map((bus) {
                          final busId = bus['id']?.toString() ?? bus['docId'];
                          final isSelected =
                              _selectedFareBusIds.contains(busId);
                          return Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true)
                                      _selectedFareBusIds.add(busId);
                                    else
                                      _selectedFareBusIds.remove(busId);
                                  });
                                },
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected)
                                        _selectedFareBusIds.remove(busId);
                                      else
                                        _selectedFareBusIds.add(busId);
                                    });
                                  },
                                  child: Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.blue[50]
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: isSelected
                                              ? Colors.blue
                                              : Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      localizeBusName(
                                          context, bus['name'].toString()),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 11),
                      if (fareBreakdown(loc).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(fareBreakdown(loc),
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black54)),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.lightBlueAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${loc.totalFare}: \$${totalFare.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- bottom sheet for bus details ---
class BusDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> bus;
  const BusDetailsSheet({super.key, required this.bus});

  @override
  State<BusDetailsSheet> createState() => _BusDetailsSheetState();
}

class _BusDetailsSheetState extends State<BusDetailsSheet> {
  String? selectedFrom;
  String? selectedTo;
  String driverContact = "N/A";
  StreamSubscription? _driverSub;

  @override
  void initState() {
    super.initState();
    _fetchDriverContact();
  }

  @override
  void dispose() {
    _driverSub?.cancel();
    super.dispose();
  }

  void _fetchDriverContact() {
    final driverName = widget.bus['assignedTo']?.toString().trim();

    if (driverName == null || driverName.isEmpty) {
      setState(() => driverContact = "Unassigned");
      return;
    }

    _driverSub?.cancel();

    _driverSub = FirebaseFirestore.instance
        .collection('drivers')
        .where('name', isEqualTo: driverName)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          driverContact = data['contactNumber']?.toString() ?? "N/A";
        });
      } else {
        setState(() => driverContact = "N/A");
      }
    }, onError: (e) {
      setState(() => driverContact = "N/A");
    });
  }

  Future<List<BusStop>> fetchBusStops(String busId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('buses')
          .where('bus_id', isEqualTo: busId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return [];

      final data = snapshot.docs.first.data();
      final stopsList = (data['stops'] as List<dynamic>? ?? []).map((stopMap) {
        final map = Map<String, dynamic>.from(stopMap);
        return BusStop(
          name: map['name'] ?? 'Unknown',
          lat: (map['lat'] ?? 0).toDouble(),
          lng: (map['lng'] ?? 0).toDouble(),
          departIn: map['time'],
        );
      }).toList();

      return stopsList;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // reuse localization functions
    String localizeBusName(String name) {
      if (name.toLowerCase().startsWith('bus ')) {
        return '${loc.busPrefix} ${name.substring(4)}';
      }
      return name;
    }

    String localizeFeature(BuildContext context, String feature) {
      final loc = AppLocalizations.of(context)!;
      final clean =
          feature.toLowerCase().replaceAll(RegExp(r'[-_\s]'), '').trim();
      switch (clean) {
        case 'wifi':
        case 'wi-fi':
          return loc.wifi;
        case 'aircond':
        case 'aircon':
        case 'ac':
          return loc.aircond;
        case 'wheelchairlifts':
          return loc.wheelchairLifts;
        case 'wheelchairspace':
          return loc.wheelchairSpace;
        default:
          return feature;
      }
    }

    return FractionallySizedBox(
      heightFactor: 0.6,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localizeBusName(widget.bus['name']),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            "${loc.busNumber}: ${widget.bus['id']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.route, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.bus['route'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, thickness: 0.6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            _buildScheduleList(context, widget.bus['time']),
                      ),
                      const Divider(height: 20, thickness: 0.6),
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            widget.bus['assignedTo'].isNotEmpty
                                ? "${loc.driver}: ${widget.bus['assignedTo']}"
                                : "${loc.driver}: ${loc.unassigned}",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            driverContact,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),

                      // 🔹 Features in details
                      if (widget.bus['features'] != null &&
                          (widget.bus['features'] as List).isNotEmpty) ...[
                        const Divider(height: 20, thickness: 0.6),
                        Text(
                          "${loc.features}:",
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: (widget.bus['features'] as List)
                              .map<Widget>(
                                (f) => Chip(
                                  label: Text(
                                      localizeFeature(context, f.toString())),
                                  backgroundColor: Colors.green.shade50,
                                  labelStyle: const TextStyle(
                                      fontSize: 13, color: Colors.green),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // buttons (back + view bus)
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(loc.back,
                            style: const TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            final stopsList = await fetchBusStops(
                                widget.bus['id'] ?? 'UnknownBus');

                            if (stopsList.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Stops not found for this bus")),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BusRoutePage(
                                  busId: widget.bus['id'] ?? 'UnknownBus',
                                  stops: stopsList,
                                  gpsRef: widget.bus['id'] == 'BUS002'
                                      ? 'gpsData2'
                                      : 'gpsData',
                                  onTransit: () async {
                                    final nextBusSnapshot =
                                        await FirebaseFirestore.instance
                                            .collection('buses')
                                            .where('bus_id',
                                                isNotEqualTo: widget.bus['id'])
                                            .limit(1)
                                            .get();

                                    if (nextBusSnapshot.docs.isNotEmpty) {
                                      final nextBus =
                                          nextBusSnapshot.docs.first.data();
                                      final nextStops = (nextBus['stops']
                                                  as List<dynamic>? ??
                                              [])
                                          .map((map) => BusStop(
                                                name: map['name'] ?? 'Unknown',
                                                lat: (map['lat'] ?? 0)
                                                    .toDouble(),
                                                lng: (map['lng'] ?? 0)
                                                    .toDouble(),
                                                departIn: map['time'],
                                              ))
                                          .toList();

                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BusRoutePage(
                                            busId: nextBus['bus_id'] ??
                                                'UnknownBus',
                                            stops: nextStops,
                                            gpsRef:
                                                nextBus['bus_id'] == 'BUS002'
                                                    ? 'gpsData2'
                                                    : 'gpsData',
                                            onTransit: null,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                          child: Text(
                            loc.viewBus,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> _buildScheduleList(BuildContext context, String? timeString) {
  final loc = AppLocalizations.of(context)!;

  if (timeString == null || timeString.isEmpty) return [];

  final List<String> schedule = timeString
      .split(RegExp(r'\.\s*'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  return [
    Text(
      "${loc.schedule}:",
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 6),
    ...schedule.map(
      (entry) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: Colors.green),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                entry,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    ),
  ];
}
