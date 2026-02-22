// features/wallet/data/repositories/wallet_repository.dart
import 'package:dio/dio.dart';
import 'package:my_wallet/core/constants/api_constants.dart';
import 'package:my_wallet/core/services/api_service.dart';
import 'package:my_wallet/features/wallet/data/models/budget_models.dart';
import 'package:my_wallet/features/wallet/data/models/wallet_models.dart';

class WalletRepository {
  final ApiService _apiService = ApiService();
  
  // جلب بيانات الصفحة الرئيسية
  Future<WalletHomeData> getHomeData() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.walletHome,
        requiresAuth: true,
      );
      
      // الـ API يعيد WalletHomeData مباشرة بدون غلاف
      return WalletHomeData.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to load home data: $e');
    }
  }
  
  // جلب الرصيد فقط
  Future<WalletBalance> getBalance() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.walletBalance,
        requiresAuth: true,
      );
      
      return WalletBalance.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to load balance: $e');
    }
  }
  
  // جلب قائمة المعاملات مع إمكانية التصفية والصفحات
Future<TransactionListResponse> getTransactions({
  int page = 1,
  int pageSize = 20,
  DateTime? fromDate,
  DateTime? toDate,
  String? type,
  int? categoryId, // تغيير من String? إلى int?
}) async {
  try {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    if (fromDate != null) {
      queryParams['fromDate'] = fromDate.toIso8601String();
    }
    if (toDate != null) {
      queryParams['toDate'] = toDate.toIso8601String();
    }
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }
    if (categoryId != null) { // تعديل الشرط
      queryParams['categoryId'] = categoryId;
    }

    final response = await _apiService.get(
      ApiEndpoints.walletTransactions,
      queryParams: queryParams,
      requiresAuth: true,
    );

    return TransactionListResponse.fromJson(response.data);
  } on DioException catch (e) {
    throw _handleDioError(e);
  } catch (e) {
    throw Exception('Failed to load transactions: $e');
  }
}
  // إضافة معاملة جديدة
// إضافة معاملة جديدة
Future<WalletTransaction> addTransaction({
  required String title,
  String? description,
  required double amount,
  required String type, // "Deposit" أو "Withdrawal"
  required int categoryId, // تغيير من String إلى int
  DateTime? transactionDate,
  bool isRecurring = false,
  String? recurringInterval,
  DateTime? recurringEndDate,
}) async {
  try {
    final body = <String, dynamic>{
      'title': title,
      'amount': amount,
      'type': type,
      'categoryId': categoryId, // إرسال categoryId بدلاً من category
      'isRecurring': isRecurring,
    };

    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    if (transactionDate != null) {
      body['transactionDate'] = transactionDate.toIso8601String();
    }
    if (recurringInterval != null) {
      body['recurringInterval'] = recurringInterval;
    }
    if (recurringEndDate != null) {
      body['recurringEndDate'] = recurringEndDate.toIso8601String();
    }

    final response = await _apiService.post(
      ApiEndpoints.walletAddTransaction,
      body,
      requiresAuth: true,
    );

    return WalletTransaction.fromJson(response.data);
  } on DioException catch (e) {
    throw _handleDioError(e);
  } catch (e) {
    throw Exception('Failed to add transaction: $e');
  }
}
  // حذف معاملة (soft delete)
  Future<bool> deleteTransaction(int transactionId) async {
    try {
      await _apiService.delete(
        '${ApiEndpoints.walletDeleteTransaction}/$transactionId',
        requiresAuth: true,
      );
      return true; // إذا لم يرمي استثناء، فالحذف ناجح
    } on DioException catch (e) {
      if (e.response?.statusCode == 204 || e.response?.statusCode == 200) {
        return true; // في حالة نجاح بدون محتوى
      }
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }
Future<BudgetDto> getBudget() async {
  try {
    final response = await _apiService.get(
      ApiEndpoints.budget,
      requiresAuth: true,
    );
    return BudgetDto.fromJson(response.data);
  } on DioException catch (e) {
    throw _handleDioError(e);
  }
}

Future<void> updateMonthlyBudget(double monthlyBudget) async {
  try {
    await _apiService.put(
      ApiEndpoints.budget,
      {'monthlyBudget': monthlyBudget},
      requiresAuth: true,
    );
  } on DioException catch (e) {
    throw _handleDioError(e);
  }
}Future<void> updateCategoryBudget(int categoryId, double budget) async {
  try {
    await _apiService.put(
      'api/Budget/category',
      {'categoryId': categoryId, 'budget': budget}, // تأكد من أن المفتاح 'budget' مطابق لـ DTO
      requiresAuth: true,
    );
  } on DioException catch (e) {
    throw _handleDioError(e);
  }
}
  // جلب ملخص للتحليلات
Future<WalletSummary> getSummary({
  required DateTime fromDate,
  required DateTime toDate,
}) async {
  try {
    final response = await _apiService.get(
      ApiEndpoints.walletSummary,
      queryParams: {
        'fromDate': fromDate.toIso8601String(),
        'toDate': toDate.toIso8601String(),
      },
      requiresAuth: true,
    );

    return WalletSummary.fromJson(response.data);
  } on DioException catch (e) {
    throw _handleDioError(e);
  } catch (e) {
    throw Exception('Failed to load summary: $e');
  }
}
  // معالجة أخطاء Dio
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