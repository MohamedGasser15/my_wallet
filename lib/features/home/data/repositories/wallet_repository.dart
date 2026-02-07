// features/home/data/repositories/wallet_repository.dart
import 'dart:convert';
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
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
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

  Future<WalletTransaction> addTransaction(Map<String, dynamic> transactionData) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.walletAddTransaction,
        transactionData,
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
}