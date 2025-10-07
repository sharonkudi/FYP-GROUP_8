import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ms')
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @malay.
  ///
  /// In en, this message translates to:
  /// **'Malay'**
  String get malay;

  /// No description provided for @accessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibility;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @small.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get small;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @large.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get large;

  /// No description provided for @iconSize.
  ///
  /// In en, this message translates to:
  /// **'Icon Size'**
  String get iconSize;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @selectDestination.
  ///
  /// In en, this message translates to:
  /// **'Please select a destination.'**
  String get selectDestination;

  /// No description provided for @busStopsNearMe.
  ///
  /// In en, this message translates to:
  /// **'Bus Stops near me'**
  String get busStopsNearMe;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'BasKu'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @listForm.
  ///
  /// In en, this message translates to:
  /// **'List Form'**
  String get listForm;

  /// No description provided for @mapForm.
  ///
  /// In en, this message translates to:
  /// **'Map Form'**
  String get mapForm;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @availableBuses.
  ///
  /// In en, this message translates to:
  /// **'Available Buses'**
  String get availableBuses;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @fareEstimator.
  ///
  /// In en, this message translates to:
  /// **'Fare Estimator'**
  String get fareEstimator;

  /// No description provided for @totalFare.
  ///
  /// In en, this message translates to:
  /// **'Total Fare'**
  String get totalFare;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @viewBus.
  ///
  /// In en, this message translates to:
  /// **'View Bus'**
  String get viewBus;

  /// No description provided for @busRoute.
  ///
  /// In en, this message translates to:
  /// **'Bus Route'**
  String get busRoute;

  /// No description provided for @nextBus.
  ///
  /// In en, this message translates to:
  /// **'Next Bus'**
  String get nextBus;

  /// No description provided for @viewMap.
  ///
  /// In en, this message translates to:
  /// **'View Map'**
  String get viewMap;

  /// No description provided for @arrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get arrived;

  /// No description provided for @passed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get passed;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetConnection;

  /// No description provided for @offlineViewMessage.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection or continue with offline view.'**
  String get offlineViewMessage;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @viewOfflineMap.
  ///
  /// In en, this message translates to:
  /// **'View Offline System Map'**
  String get viewOfflineMap;

  /// No description provided for @offlineMap.
  ///
  /// In en, this message translates to:
  /// **'Offline Map'**
  String get offlineMap;

  /// No description provided for @offlineSystemMap.
  ///
  /// In en, this message translates to:
  /// **'Offline System Map'**
  String get offlineSystemMap;

  /// No description provided for @offlineBusSchedule.
  ///
  /// In en, this message translates to:
  /// **'Offline Bus Schedule'**
  String get offlineBusSchedule;

  /// No description provided for @adults.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get adults;

  /// No description provided for @childrenSeniors.
  ///
  /// In en, this message translates to:
  /// **'Children / Seniors'**
  String get childrenSeniors;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @busNumber.
  ///
  /// In en, this message translates to:
  /// **'Bus No'**
  String get busNumber;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @takeBusAToKianggeh.
  ///
  /// In en, this message translates to:
  /// **'Take Bus A to Kianggeh'**
  String get takeBusAToKianggeh;

  /// No description provided for @arriveAtKianggehAt.
  ///
  /// In en, this message translates to:
  /// **'Arrive at Kianggeh at'**
  String get arriveAtKianggehAt;

  /// No description provided for @transferToBusBAtKianggeh.
  ///
  /// In en, this message translates to:
  /// **'Transfer to Bus B at Kianggeh'**
  String get transferToBusBAtKianggeh;

  /// No description provided for @continueToYayasanOrMoF.
  ///
  /// In en, this message translates to:
  /// **'Continue to Yayasan Complex or Ministry of Finance'**
  String get continueToYayasanOrMoF;

  /// No description provided for @takeBusBToKianggeh.
  ///
  /// In en, this message translates to:
  /// **'Take Bus B to Kianggeh'**
  String get takeBusBToKianggeh;

  /// No description provided for @transferToBusAAtTheMall.
  ///
  /// In en, this message translates to:
  /// **'Transfer to Bus A at The Mall Gadong'**
  String get transferToBusAAtTheMall;

  /// No description provided for @continueToPBSchoolOrMall.
  ///
  /// In en, this message translates to:
  /// **'Continue to PB School, Ong Sum Ping, or loop at The Mall Gadong'**
  String get continueToPBSchoolOrMall;

  /// No description provided for @transitInfo.
  ///
  /// In en, this message translates to:
  /// **'Transit Info'**
  String get transitInfo;

  /// No description provided for @busPrefix.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get busPrefix;

  /// No description provided for @wifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get wifi;

  /// No description provided for @aircond.
  ///
  /// In en, this message translates to:
  /// **'Air Conditioning'**
  String get aircond;

  /// No description provided for @wheelchairLifts.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair Lifts'**
  String get wheelchairLifts;

  /// No description provided for @wheelchairSpace.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair Space'**
  String get wheelchairSpace;

  /// No description provided for @duration_5_10.
  ///
  /// In en, this message translates to:
  /// **'Estimated 5–10 minutes for each stop'**
  String get duration_5_10;

  /// No description provided for @duration_5_15.
  ///
  /// In en, this message translates to:
  /// **'Estimated 5–15 minutes for each stop'**
  String get duration_5_15;

  /// No description provided for @duration_10_15.
  ///
  /// In en, this message translates to:
  /// **'Estimated 10–15 minutes for each stop'**
  String get duration_10_15;

  /// No description provided for @duration_10_20.
  ///
  /// In en, this message translates to:
  /// **'Estimated 10–20 minutes for each stop'**
  String get duration_10_20;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ms'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
