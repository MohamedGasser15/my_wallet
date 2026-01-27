// core/constants/app_constants.dart
class AppConstants {
  static const String appName = 'محفظتي';
  static const String appVersion = '1.0.0';
  static const String baseUrl = 'http://10.0.2.2:5022/api'; // للـ Android Emulator
  
  // Shared Preferences Keys
  static const String isFirstTimeKey = 'isFirstTime';
  static const String authTokenKey = 'authToken';
  static const String userDataKey = 'userData';
  static const String appLanguageKey = 'appLanguage';
  
  // App Languages
  static const String arabic = 'ar';
  static const String english = 'en';
}