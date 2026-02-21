// core/utils/shared_prefs.dart
import 'package:my_wallet/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static late SharedPreferences _prefs;
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // First Time
  static bool get isFirstTime {
    return _prefs.getBool(AppConstants.isFirstTimeKey) ?? true;
  }
  
  static Future<void> setFirstTime(bool value) async {
    await _prefs.setBool(AppConstants.isFirstTimeKey, value);
  }
  
  // Auth Token
  static String? get authToken {
    return _prefs.getString(AppConstants.authTokenKey);
  }
  static Future<void> setBool(String key, bool value) async {
  await _prefs.setBool(key, value);
}
  static Future<void> setAuthToken(String token) async {
    await _prefs.setString(AppConstants.authTokenKey, token);
  }
  
  static Future<void> removeAuthToken() async {
    await _prefs.remove(AppConstants.authTokenKey);
  }
  static Future<String?> getUserData() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(AppConstants.userDataKey);
}
  // User Data
  static String? get userData {
    return _prefs.getString(AppConstants.userDataKey);
  }
  
  static Future<void> setUserData(String data) async {
    await _prefs.setString(AppConstants.userDataKey, data);
  }
  
  static Future<void> removeUserData() async {
    await _prefs.remove(AppConstants.userDataKey);
  }
  
  // App Language
  static String get appLanguage {
    return _prefs.getString(AppConstants.appLanguageKey) ?? AppConstants.arabic;
  }
  
  static Future<void> setAppLanguage(String language) async {
    await _prefs.setString(AppConstants.appLanguageKey, language);
  }
    static Future<void> setString(String key, dynamic value) async {
    if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    }
  }
  
  static String? getStringValue(String key) {
    return _prefs.getString(key);
  }
  
  static bool? getBoolValue(String key) {
    return _prefs.getBool(key);
  }
  
  static Future<void> removeKey(String key) async {
    await _prefs.remove(key);
  }
  
}