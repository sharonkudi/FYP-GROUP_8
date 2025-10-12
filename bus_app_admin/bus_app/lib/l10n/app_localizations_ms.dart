// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get settings => 'Tetapan';

  @override
  String get language => 'Bahasa';

  @override
  String get english => 'Bahasa Inggeris';

  @override
  String get malay => 'Bahasa Melayu';

  @override
  String get accessibility => 'Aksesibiliti';

  @override
  String get fontSize => 'Saiz Fon';

  @override
  String get small => 'Kecil';

  @override
  String get medium => 'Sederhana';

  @override
  String get large => 'Besar';

  @override
  String get iconSize => 'Saiz Ikon';

  @override
  String get mode => 'Mod';

  @override
  String get save => 'Simpan';

  @override
  String get destination => 'Destinasi';

  @override
  String get selectDestination => 'Sila pilih destinasi.';

  @override
  String get busStopsNearMe => 'Perhentian Bas berhampiran';

  @override
  String get viewAll => 'Lihat Semua';

  @override
  String get view => 'Lihat';

  @override
  String get appName => 'BasKu';

  @override
  String get home => 'Utama';

  @override
  String get listForm => 'Borang Senarai';

  @override
  String get mapForm => 'Borang Peta';

  @override
  String get from => 'Dari';

  @override
  String get to => 'Ke';

  @override
  String get availableBuses => 'Bas Tersedia';

  @override
  String get available => 'Tersedia';

  @override
  String get fareEstimator => 'Penganggar Tambang';

  @override
  String get totalFare => 'Jumlah Tambang';

  @override
  String get back => 'Kembali';

  @override
  String get viewBus => 'Lihat Bas';

  @override
  String get busRoute => 'Laluan Bas';

  @override
  String get nextBus => 'Bas Seterusnya';

  @override
  String get viewMap => 'Lihat Peta';

  @override
  String get arrived => 'Tiba';

  @override
  String get passed => 'Lalu';

  @override
  String get upcoming => 'Akan Datang';

  @override
  String get noInternetConnection => 'Tiada Sambungan Internet';

  @override
  String get offlineViewMessage =>
      'Sila semak sambungan anda atau teruskan dengan paparan luar talian.';

  @override
  String get retry => 'Cuba Semula';

  @override
  String get viewOfflineMap => 'Lihat Peta Sistem Luar Talian';

  @override
  String get offlineMap => 'Peta Luar Talian';

  @override
  String get offlineSystemMap => 'Peta Sistem Luar Talian';

  @override
  String get offlineBusSchedule => 'Jadual Bas Luar Talian';

  @override
  String get adults => 'Dewasa';

  @override
  String get childrenSeniors => 'Kanak-kanak / Warga Emas';

  @override
  String get schedule => 'Jadual';

  @override
  String get features => 'Ciri-ciri';

  @override
  String get duration => 'Tempoh';

  @override
  String get driver => 'Pemandu';

  @override
  String get busNumber => 'No Bas';

  @override
  String get unassigned => 'Belum Ditetapkan';

  @override
  String get takeBusAToKianggeh => 'Naik Bas A ke Kianggeh';

  @override
  String get arriveAtKianggehAt => 'Tiba di Kianggeh pada';

  @override
  String get transferToBusBAtKianggeh => 'Tukar ke Bas B di Kianggeh';

  @override
  String get continueToYayasanOrMoF =>
      'Teruskan ke Kompleks Yayasan atau Kementerian Kewangan';

  @override
  String get takeBusBToKianggeh => 'Naik Bas B ke Kianggeh';

  @override
  String get transferToBusAAtTheMall => 'Tukar ke Bas A di The Mall Gadong';

  @override
  String get continueToPBSchoolOrMall =>
      'Teruskan ke Sekolah PB, Ong Sum Ping, atau pusing di The Mall Gadong';

  @override
  String get transitInfo => 'Maklumat Transit';

  @override
  String get busPrefix => 'Bas';

  @override
  String get wifi => 'Wi-Fi';

  @override
  String get aircond => 'Penyaman Udara';

  @override
  String get wheelchairLifts => 'Lif Kerusi Roda';

  @override
  String get wheelchairSpace => 'Ruang Kerusi Roda';

  @override
  String get duration_5_10 => 'Anggaran 5–10 minit bagi setiap hentian';

  @override
  String get duration_5_15 => 'Anggaran 5–15 minit bagi setiap hentian';

  @override
  String get duration_10_15 => 'Anggaran 10–15 minit bagi setiap hentian';

  @override
  String get duration_10_20 => 'Anggaran 10–20 minit bagi setiap hentian';

  @override
  String get close => 'Tutup';

  @override
  String get bus => 'Bas';

  @override
  String get scheduledTime => 'Waktu Jadual';

  @override
  String get nextStop => 'Perhentian Seterusnya';

  @override
  String get status => 'Kedudukan';

  @override
  String get unknown => 'Tidak diketahui';

  @override
  String get busFeatures => 'Ciri-ciri Bas';

  @override
  String get routeKianggehYayasan => 'Kianggeh → Yayasan Complex';

  @override
  String get routeYayasanKianggeh => 'Yayasan Complex → Kianggeh';

  @override
  String get transitRequired => 'Perlu Transit';

  @override
  String transitDescription(Object stop) {
    return 'Turun di $stop dan berjalan (~5 min) untuk meneruskan perjalanan anda.\n\nTambahan Tambang: BND 1.00';
  }

  @override
  String get statusArrived => '✅ Telah sampai destinasi';

  @override
  String statusArrivingSoon(Object minutes) {
    return '🟢 Sedang menghampiri ($minutes minit)';
  }

  @override
  String statusETA(Object minutes) {
    return '🕓 Jangkaan tiba $minutes minit';
  }
}
