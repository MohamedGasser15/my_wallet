import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:my_wallet/core/utils/shared_prefs.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  // Check if biometrics is available
  static Future<bool> isBiometricAvailable() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      print('Error checking biometrics: $e');
      return false;
    }
  }
// في biometric_service.dart، أضف هذه الدالة:
static Future<bool> authenticateWithFallback({
  int maxAttempts = 3,
  Function()? onFallback,
}) async {
  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      final authenticated = await authenticate();
      if (authenticated) {
        return true;
      }
      
      if (attempt < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      print('Biometric attempt $attempt failed: $e');
    }
  }
  
  // إذا فشلت جميع المحاولات
  if (onFallback != null) {
    onFallback();
  }
  
  return false;
}
  // Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print('Error getting biometrics: $e');
      return [];
    }
  }

  // Check if biometrics is enabled by user
  static Future<bool> isBiometricEnabled() async {
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      final hasBiometrics = await _auth.canCheckBiometrics;
      if (!hasBiometrics) return false;

      final userEnabled = SharedPrefs.getBoolValue('biometric_enabled') ?? false;
      return userEnabled;
    } on PlatformException catch (e) {
      print('Error checking biometric enabled: $e');
      return false;
    }
  }

  // Authenticate with biometrics
  static Future<bool> authenticate() async {
    try {
      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) return false;

      final authenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to access your wallet',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      return authenticated;
    } on PlatformException catch (e) {
      print('Error during authentication: $e');
      return false;
    }
  }

  // Enable biometrics
  static Future<void> enableBiometric() async {
    try {
      // First authenticate once
      final authenticated = await _auth.authenticate(
        localizedReason: 'Enable biometric authentication',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        await SharedPrefs.setBool('biometric_enabled', true);
      }
    } on PlatformException catch (e) {
      print('Error enabling biometrics: $e');
    }
  }

  // Disable biometrics
  static Future<void> disableBiometric() async {
    await SharedPrefs.removeKey('biometric_enabled');
  }

  // Get biometric display name based on platform
  static Future<String> getBiometricName() async {
    final available = await getAvailableBiometrics();
    
    if (available.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (available.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (available.contains(BiometricType.iris)) {
      return 'Iris';
    } else {
      return 'Biometric';
    }
  }

  // Check if device supports biometrics
  static Future<bool> hasBiometricSupport() async {
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      final biometrics = await getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } on PlatformException catch (e) {
      print('Error checking biometric support: $e');
      return false;
    }
  }
}