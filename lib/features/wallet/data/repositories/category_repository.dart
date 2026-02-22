import 'package:dio/dio.dart';
import 'package:my_wallet/core/constants/api_constants.dart';
import 'package:my_wallet/core/services/api_service.dart';
import 'package:my_wallet/features/wallet/data/models/category_model.dart';

class CategoryRepository {
  final ApiService _apiService = ApiService();

  // جلب كل التصنيفات
  Future<List<Category>> getAllCategories() async {
    try {
      final response = await _apiService.get(
        'api/Category', // تأكد من صحة الـ endpoint
        requiresAuth: true,
      );
      final List data = response.data;
      return data.map((json) => Category.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // إضافة تصنيف جديد
  Future<Category> createCategory(String nameAr, String nameEn) async {
    try {
      final response = await _apiService.post(
        'api/Category',
        {'nameAr': nameAr, 'nameEn': nameEn},
        requiresAuth: true,
      );
      return Category.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // تحديث تصنيف
  Future<Category> updateCategory(int id, String nameAr, String nameEn) async {
    try {
      final response = await _apiService.put(
        'api/Category/$id',
        {'id': id, 'nameAr': nameAr, 'nameEn': nameEn},
        requiresAuth: true,
      );
      return Category.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // حذف تصنيف
  Future<void> deleteCategory(int id) async {
    try {
      await _apiService.delete(
        'api/Category/$id',
        requiresAuth: true,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // معالجة الأخطاء
  String _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
      return 'Server error: ${e.response!.statusCode}';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Connection timeout. Please check your internet.';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }
    return 'An error occurred: ${e.message}';
  }
}