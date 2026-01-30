import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_wallet/core/constants/app_constants.dart';
import 'package:my_wallet/core/utils/shared_prefs.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String baseUrl = AppConstants.baseUrl;
  
  Future<http.Response> post(
    String endpoint, 
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      };
      
      if (requiresAuth) {
        final token = SharedPrefs.authToken;
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
      }
      
      print('🌐 POST Request to: $baseUrl$endpoint');
      print('📦 Body: ${jsonEncode(body)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
      
      return response;
    } catch (e) {
      print('❌ POST Error: $e');
      rethrow;
    }
  }
  
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = false,
  }) async {
    try {
      final headers = <String, String>{};
      
      if (requiresAuth) {
        final token = SharedPrefs.authToken;
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
      }
      
      String url = '$baseUrl$endpoint';
      if (queryParams != null) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }
      
      print('🌐 GET Request to: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
      
      return response;
    } catch (e) {
      print('❌ GET Error: $e');
      rethrow;
    }
  }
  
  // Helper method to handle API responses
Map<String, dynamic> handleResponse(http.Response response) {
  print('🔄 Handling response: ${response.statusCode}');
  
  final statusCode = response.statusCode;
  final body = response.body;

  // لو الفويس بتاع السيرفر فاضي
  if (body.isEmpty) {
    return {
      'success': false,
      'message': 'Empty response from server',
    };
  }

  try {
    // حاول نفك JSON
    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return {
        'success': decoded['success'] ?? (statusCode == 200),
        'message': decoded['message'] ?? '',
        ...decoded,
      };
    }

    // لو decoded مش Map (مثلاً String) => نعتبره رسالة خطأ
    return {
      'success': false,
      'message': decoded.toString(),
    };
  } catch (e) {
    // JSON غير صالح => نستخدم النص كما هو
    return {
      'success': false,
      'message': body,
    };
  }
}
}