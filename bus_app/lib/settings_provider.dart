import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  // Language
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  // Font & Icon Sizes
  double fontSize = 14;
  double iconSize = 24;

  double get font => fontSize;

  void changeLanguage(String langCode) {
    // ✅ Ensure only supported locales are used
    if (['en', 'ms'].contains(langCode)) {
      _locale = Locale(langCode);
      notifyListeners();
    }
  }

  void changeFontSize(double size) {
    fontSize = size;
    notifyListeners();
  }

  void changeIconSize(double size) {
    iconSize = size;
    notifyListeners();
  }

  // ✅ Helper for MaterialApp locale assignment
  void setLocale(Locale locale) {
    if (!['en', 'ms'].contains(locale.languageCode)) return;
    _locale = locale;
    notifyListeners();
  }
}
