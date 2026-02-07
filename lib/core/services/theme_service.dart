// core/services/theme_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'selected_theme';
  
  // الأنماط المتاحة
  static const String light = 'light';
  static const String dark = 'dark';
  static const String system = 'system';
  
  static ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
  
  static Future<void> init() async {
    final savedTheme = await getSavedTheme();
    themeNotifier.value = _stringToThemeMode(savedTheme);
  }
  
  static ThemeMode _stringToThemeMode(String theme) {
    switch (theme) {
      case light:
        return ThemeMode.light;
      case dark:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
  
  static String _themeModeToString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return light;
      case ThemeMode.dark:
        return dark;
      default:
        return system;
    }
  }
  
  // حفظ النمط المختار
  static Future<void> saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
    themeNotifier.value = _stringToThemeMode(theme);
  }
  
  static Future<void> saveThemeMode(ThemeMode themeMode) async {
    final theme = _themeModeToString(themeMode);
    await saveTheme(theme);
  }
  
  // جلب النمط المحفوظ
  static Future<String> getSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? system;
  }
  
  static Future<ThemeMode> getCurrentThemeMode() async {
    final savedTheme = await getSavedTheme();
    return _stringToThemeMode(savedTheme);
  }
}