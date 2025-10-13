// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get malay => 'Malay';

  @override
  String get accessibility => 'Accessibility';

  @override
  String get fontSize => 'Font Size';

  @override
  String get small => 'Small';

  @override
  String get medium => 'Medium';

  @override
  String get large => 'Large';

  @override
  String get iconSize => 'Icon Size';

  @override
  String get mode => 'Mode';

  @override
  String get save => 'Save';

  @override
  String get destination => 'Destination';

  @override
  String get selectDestination => 'Please select a destination.';

  @override
  String get busStopsNearMe => 'Bus Stops near me';

  @override
  String get viewAll => 'View All';

  @override
  String get view => 'View';

  @override
  String get appName => 'BasKu';

  @override
  String get home => 'Home';

  @override
  String get listForm => 'List Form';

  @override
  String get mapForm => 'Map Form';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get availableBuses => 'Available Buses';

  @override
  String get available => 'Available';

  @override
  String get fareEstimator => 'Fare Estimator';

  @override
  String get totalFare => 'Total Fare';

  @override
  String get back => 'Back';

  @override
  String get viewBus => 'View Bus';

  @override
  String get busRoute => 'Bus Route';

  @override
  String get nextBus => 'Next Bus';

  @override
  String get viewMap => 'View Map';

  @override
  String get arrived => 'Arrived';

  @override
  String get passed => 'Passed';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get noInternetConnection => 'No Internet Connection';

  @override
  String get offlineViewMessage =>
      'Please check your connection or continue with offline view.';

  @override
  String get retry => 'Retry';

  @override
  String get viewOfflineMap => 'View Offline System Map';

  @override
  String get offlineMap => 'Offline Map';

  @override
  String get offlineSystemMap => 'Offline System Map';

  @override
  String get offlineBusSchedule => 'Offline Bus Schedule';

  @override
  String get adults => 'Adults';

  @override
  String get childrenSeniors => 'Children / Seniors';

  @override
  String get schedule => 'Schedule';

  @override
  String get features => 'Features';

  @override
  String get duration => 'Duration';

  @override
  String get driver => 'Driver';

  @override
  String get busNumber => 'Bus No';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get takeBusAToKianggeh => 'Take Bus A to Kianggeh';

  @override
  String get arriveAtKianggehAt => 'Arrive at Kianggeh at';

  @override
  String get transferToBusBAtKianggeh => 'Transfer to Bus B at Kianggeh';

  @override
  String get continueToYayasanOrMoF =>
      'Continue to Yayasan Complex or Ministry of Finance';

  @override
  String get takeBusBToKianggeh => 'Take Bus B to Kianggeh';

  @override
  String get transferToBusAAtTheMall => 'Transfer to Bus A at The Mall Gadong';

  @override
  String get continueToPBSchoolOrMall =>
      'Continue to PB School, Ong Sum Ping, or loop at The Mall Gadong';

  @override
  String get transitInfo => 'Transit Info';

  @override
  String get busPrefix => 'Bus';

  @override
  String get wifi => 'Wi-Fi';

  @override
  String get aircond => 'Air Conditioning';

  @override
  String get wheelchairLifts => 'Wheelchair Lifts';

  @override
  String get wheelchairSpace => 'Wheelchair Space';

  @override
  String get duration_5_10 => 'Estimated 5–10 minutes for each stop';

  @override
  String get duration_5_15 => 'Estimated 5–15 minutes for each stop';

  @override
  String get duration_10_15 => 'Estimated 10–15 minutes for each stop';

  @override
  String get duration_10_20 => 'Estimated 10–20 minutes for each stop';

  @override
  String get close => 'Close';

  @override
  String get bus => 'Bus';

  @override
  String get busA => 'Bus A';

  @override
  String get busB => 'Bus B';

  @override
  String get scheduledTime => 'Scheduled Time';

  @override
  String get nextStop => 'Next Stop';

  @override
  String get status => 'Status';

  @override
  String get unknown => 'Unknown';

  @override
  String get busFeatures => 'Bus Features';

  @override
  String get routeKianggehYayasan => 'Kianggeh → Yayasan Complex';

  @override
  String get routeYayasanKianggeh => 'Yayasan Complex → Kianggeh';

  @override
  String get transitRequired => 'Transit Required';

  @override
  String transitDescription(Object stop) {
    return 'Drop off at $stop and walk (~5 min) to continue your journey.\n\nExtra Fare: BND 1.00';
  }

  @override
  String get locating => 'Locating...';

  @override
  String get metersAway => 'm away';

  @override
  String get kilometersAway => 'km away';

  @override
  String get statusArrived => '✅ Arrived at destination';

  @override
  String statusArrivingSoon(Object minutes) {
    return '🟢 Arriving Soon ($minutes min)';
  }

  @override
  String statusETA(Object minutes) {
    return '🕓 ETA $minutes min';
  }
}
