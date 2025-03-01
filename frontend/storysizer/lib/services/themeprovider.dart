

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  bool _isInitialized = false;

  ThemeMode get mode => _mode;
  bool get isInitialized => _isInitialized;

  ThemeModeProvider() {
    _loadTheme();
  }

  void changeMode(bool isDarkMode) {
    _mode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _saveTheme(isDarkMode);
    notifyListeners();
  }

  Future<void> _loadTheme() async {
  final prefs = await SharedPreferences.getInstance();
  ThemeMode newMode;

  if (!prefs.containsKey('isDarkMode')) {
    // Se è la prima volta, prendi il valore dal sistema
    final Brightness systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    newMode = systemBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
  } else {
    final isDark = prefs.getBool('isDarkMode') ?? false;
    newMode = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  if (_mode != newMode || !_isInitialized) { // ✅ Controllo extra per evitare blocchi
    _mode = newMode;
    _isInitialized = true;
    notifyListeners();
  }
}
  Future<void> _saveTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }
}