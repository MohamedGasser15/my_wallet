import 'dart:convert';
import 'package:my_wallet/core/constants/api_constants.dart';
import 'package:my_wallet/core/services/api_service.dart';
import 'package:my_wallet/core/utils/shared_prefs.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();
  
Future<Map<String, dynamic>> sendVerification({
  required String email,
  required bool isLogin,
  String? deviceName,
  String? ipAddress,
}) async {
  try {
    final response = await _apiService.post(
      ApiEndpoints.sendVerification,
      {
        'email': email,
        'isLogin': isLogin,
        'deviceName': deviceName,
        'ipAddress': ipAddress,
      },
    );
    final data = _apiService.handleResponse(response);
    await SharedPrefs.setString('temp_email', email);
    await SharedPrefs.setBool('temp_is_login', isLogin);
    return data;
  } catch (e) {
    rethrow;
  }
}
  
  // Verify code only (نقطة التحقق المنفصلة الجديدة)
  Future<Map<String, dynamic>> verifyCode({
    required String email,
    required String verificationCode,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.verifyCode,
        {
          'email': email,
          'verificationCode': verificationCode,
        },
      );
      
      final data = _apiService.handleResponse(response);
      
      // إذا نجح التحقق، نخزن البيانات
      if (data['success'] == true) {
        await SharedPrefs.setString('verified_email', email);
        await SharedPrefs.setString('verified_code', verificationCode);
        await SharedPrefs.setBool('is_code_verified', true);
      }
      
      return data;
    } catch (e) {
      rethrow;
    }
  }
  
  // Resend verification code
  Future<Map<String, dynamic>> resendCode({
  required String email,
  required bool isLogin,
  String? deviceName,
  String? ipAddress,
}) async {
  final response = await _apiService.post(
    ApiEndpoints.resendCode,
    {
      'email': email,
      'isLogin': isLogin,
      'deviceName': deviceName,
      'ipAddress': ipAddress,
    },
  );
  return _apiService.handleResponse(response);
}
  
  // Complete registration
  Future<Map<String, dynamic>> completeRegistration({
    required String email,
    required String verificationCode,
    required String password,
    required String fullName,
    required String userName,
    required String phoneNumber,
  }) async {
    try {
      // تأكد من أن الكود تم التحقق منه أولاً
      final isVerified = SharedPrefs.getBoolValue('is_code_verified') ?? false;
      if (!isVerified) {
        throw Exception('Please verify your code first');
      }
      
      final response = await _apiService.post(
        ApiEndpoints.verifyAndComplete,
        {
          'email': email,
          'verificationCode': verificationCode,
          'password': password,
          'fullName': fullName,
          'userName': userName,
          'phoneNumber': phoneNumber,
        },
      );
      
      final data = _apiService.handleResponse(response);
      
      // إذا نجح التسجيل، نخزن الـ token
      if (data['success'] == true && data['token'] != null) {
        await SharedPrefs.setAuthToken(data['token']);
        
        // تخزين بيانات المستخدم
        await SharedPrefs.setUserData(jsonEncode({
          'email': email,
          'fullName': fullName,
          'userName': userName,
          'phoneNumber': phoneNumber,
        }));
        
        // تنظيف البيانات المؤقتة
        await _cleanTempData();
      }
      
      return data;
    } catch (e) {
      rethrow;
    }
  }
  
  // Complete login
  Future<Map<String, dynamic>> completeLogin({
    required String email,
    required String verificationCode,
    required String password,
  }) async {
    try {
      // تأكد من أن الكود تم التحقق منه أولاً
      final isVerified = SharedPrefs.getBoolValue('is_code_verified') ?? false;
      if (!isVerified) {
        throw Exception('Please verify your code first');
      }
      
      final response = await _apiService.post(
        ApiEndpoints.verifyAndComplete,
        {
          'email': email,
          'verificationCode': verificationCode,
          'password': password,
          'fullName': '',
          'userName': '',
          'phoneNumber': '',
        },
      );
      
      final data = _apiService.handleResponse(response);
      
      // إذا نجح الدخول، نخزن الـ token
      if (data['success'] == true && data['token'] != null) {
        await SharedPrefs.setAuthToken(data['token']);
        
        // تخزين بيانات المستخدم
        await SharedPrefs.setUserData(jsonEncode({
          'email': email,
        }));
        
        // تنظيف البيانات المؤقتة
        await _cleanTempData();
      }
      
      return data;
    } catch (e) {
      rethrow;
    }
  }
  
  // Check if email exists
  Future<bool> checkEmail(String email) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.checkEmail,
        queryParams: {'email': email},
      );
      
      final data = _apiService.handleResponse(response);
      return data['exists'] ?? false;
    } catch (e) {
      rethrow;
    }
  }
  
  // تنظيف البيانات المؤقتة
  Future<void> _cleanTempData() async {
    await SharedPrefs.removeKey('temp_email');
    await SharedPrefs.removeKey('temp_is_login');
    await SharedPrefs.removeKey('verified_email');
    await SharedPrefs.removeKey('verified_code');
    await SharedPrefs.removeKey('is_code_verified');
  }
  
  // Logout
  Future<void> logout() async {
    try {
      await _apiService.post(
        ApiEndpoints.logout,
        {},
        requiresAuth: true,
      );
      
      // إزالة البيانات المحلية
      await SharedPrefs.removeAuthToken();
      await SharedPrefs.removeUserData();
      await _cleanTempData();
    } catch (e) {
      rethrow;
    }
  }
}