// lib/core/utils/api_error_handler.dart
import 'package:dio/dio.dart';

class ApiErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'انتهت مهلة الاتصال، تحقق من اتصالك بالإنترنت';
        case DioExceptionType.badResponse:
          // محاولة استخراج رسالة الخطأ من جسم الاستجابة
          final responseData = error.response?.data;
          if (responseData != null) {
            // محاولة قراءة الحقول المعتادة
            if (responseData is Map) {
              if (responseData.containsKey('message')) {
                return responseData['message'].toString();
              } else if (responseData.containsKey('error')) {
                return responseData['error'].toString();
              } else if (responseData.containsKey('errors')) {
                // لو كانت الأخطاء عبارة عن كائن به عدة حقول
                final errors = responseData['errors'];
                if (errors is Map) {
                  return errors.values.join('\n');
                }
              }
            } else if (responseData is String) {
              return responseData;
            }
          }
          return 'حدث خطأ في الخادم (${error.response?.statusCode ?? 'غير معروف'})';
        case DioExceptionType.cancel:
          return 'تم إلغاء الطلب';
        case DioExceptionType.connectionError:
          return 'لا يوجد اتصال بالإنترنت';
        default:
          return 'حدث خطأ غير متوقع: ${error.message}';
      }
    } else if (error is FormatException) {
      return 'خطأ في تنسيق البيانات المستلمة';
    } else {
      return error.toString();
    }
  }

  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
             error.type == DioExceptionType.connectionTimeout ||
             error.type == DioExceptionType.receiveTimeout ||
             error.type == DioExceptionType.sendTimeout;
    }
    return false;
  }
}