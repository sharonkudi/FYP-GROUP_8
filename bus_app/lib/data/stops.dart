// lib/data/stops.dart
import 'package:latlong2/latlong.dart';

class StopData {
  static Map<String, LatLng> coords = {
    'The Mall Gadong':     LatLng(4.9055, 114.9163),
    'Ong Sum Ping':        LatLng(4.8886, 114.9479),
    'PB School':           LatLng(4.8935, 114.9454),
    'Yayasan Complex':     LatLng(4.8903, 114.9400),
    'Kianggeh':            LatLng(4.8948, 114.9428),
    'Ministry of Finance': LatLng(4.9033, 114.9399),
  };
  static List<String> names = [
    'The Mall Gadong',
    'Ong Sum Ping',
    'PB School',
    'Yayasan Complex',
    'Kianggeh',
    'Ministry of Finance',
  ];
}
