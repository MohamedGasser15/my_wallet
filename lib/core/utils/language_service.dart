import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  
  static const Locale arabic = Locale('ar', 'SA');
  static const Locale english = Locale('en', 'US');
  
  static Future<Locale> getDeviceLocale() async {
    final platformLocale = PlatformDispatcher.instance.locale;
    
    // الكشف عن لغة الجهاز
    if (platformLocale.languageCode.startsWith('ar')) {
      return arabic;
    }
    
    return english;
  }
  
  static Future<Locale> getSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      
      if (savedLanguage == 'ar') return arabic;
      if (savedLanguage == 'en') return english;
      
      // إذا لم تكن هناك لغة محفوظة، استخدم لغة الجهاز
      return await getDeviceLocale();
    } catch (e) {
      return english;
    }
  }
  
  static Future<void> saveLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, locale.languageCode);
    } catch (e) {
      print('Error saving locale: $e');
    }
  }
  
  static Future<void> switchToArabic() async {
    await saveLocale(arabic);
  }
  
  static Future<void> switchToEnglish() async {
    await saveLocale(english);
  }
  
  static bool isArabic(Locale locale) {
    return locale.languageCode == 'ar';
  }
  
  static bool isEnglish(Locale locale) {
    return locale.languageCode == 'en';
  }
}