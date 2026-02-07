// features/wallet/data/repositories/wallet_repository.dart
import 'package:dio/dio.dart';
import 'package:my_wallet/core/constants/api_constants.dart';
import 'package:my_wallet/core/services/api_service.dart';
import 'package:my_wallet/features/wallet/data/models/wallet_models.dart';

class WalletRepository {
  final ApiService _apiService = ApiService();
  
  Future<WalletHomeData> getHomeData() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.walletHome,
        requiresAuth: true,
      );
      
      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true) {
        return WalletHomeData.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to load home data');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  Future<WalletBalance> getBalance() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.walletBalance,
        requiresAuth: true,
      );
      
      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true) {
        return WalletBalance.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to load balance');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  Future<List<WalletTransaction>> getTransactions({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      
      if (type != null) {
        queryParams['type'] = type;
      }
      
      final response = await _apiService.get(
        ApiEndpoints.walletTransactions,
        queryParams: queryParams,
        requiresAuth: true,
      );
      
      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true) {
        final List<dynamic> transactions = data['data'];
        return transactions.map((t) => WalletTransaction.fromJson(t)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load transactions');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  Future<WalletTransaction> addTransaction({
    required String title,
    required String description,
    required double amount,
    required String type,
    required String category,
    String? attachmentUrl,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.walletAddTransaction,
        {
          'title': title,
          'description': description,
          'amount': amount,
          'type': type,
          'category': category,
          if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
        },
        requiresAuth: true,
      );
      
      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true) {
        return WalletTransaction.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to add transaction');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  Future<bool> deleteTransaction(int transactionId) async {
    try {
      final response = await _apiService.get(
        '${ApiEndpoints.walletDeleteTransaction}?transactionId=$transactionId',
        requiresAuth: true,
      );
      
      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true) {
        return true;
      } else {
        throw Exception(data['message'] ?? 'Failed to delete transaction');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  Future<WalletSummary> getSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.walletSummary,
        queryParams: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
        requiresAuth: true,
      );
      
      final data = _apiService.handleResponse(response);
      
      if (data['success'] == true) {
        return WalletSummary.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to load summary');
      }
    } catch (e) {
      rethrow;
    }
  }
}