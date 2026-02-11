import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  bool _notificationsEnabled = true;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get notificationsEnabled => _notificationsEnabled;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setLocale(Locale locale) {
    if (['en', 'so', 'ar'].contains(locale.languageCode)) {
      _locale = locale;
      notifyListeners();
    }
  }

  List<Locale> get supportedLocales => const [
    Locale('en', 'US'),
    Locale('so', 'SO'),
    Locale('ar', 'SA'),
  ];

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }
}
