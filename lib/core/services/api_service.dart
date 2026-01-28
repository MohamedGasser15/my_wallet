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
    
    try {
      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseBody;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else if (response.statusCode == 400) {
        final error = responseBody;
        throw Exception(error['message'] ?? 'Bad request');
      } else if (response.statusCode == 404) {
        throw Exception('Endpoint not found');
      } else if (response.statusCode == 500) {
        throw Exception('Server error - Please try again later');
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Response parsing error: $e');
      print('❌ Response body: ${response.body}');
      throw Exception('Failed to parse response');
    }
  }
}