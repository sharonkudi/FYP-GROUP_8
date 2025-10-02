// lib/data/stops.dart
import 'package:latlong2/latlong.dart';

class StopData {
  static Map<String, LatLng> coords = {
    'The Mall Gadong': LatLng(4.905010, 114.919227),
    'Yayasan Complex': LatLng(4.888581361818439, 114.94048600605531),
    'Kianggeh': LatLng(4.8892108308087385, 114.94433682090414),
    'Ong Sum Ping': LatLng(4.90414222577477, 114.93627988813594),
    'PB School': LatLng(4.904922563115028, 114.9332865430959),
    'Ministry of Finance': LatLng(4.915056711681162, 114.95226715214645),
  };

  static List<String> names = [
    'The Mall Gadong',
    'Yayasan Complex',
    'Kianggeh',
    'Ong Sum Ping',
    'PB School',
    'Ministry of Finance',
  ];
}