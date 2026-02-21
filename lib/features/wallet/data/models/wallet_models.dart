// features/wallet/data/models/wallet_models.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class WalletHomeData extends Equatable {
  final WalletBalance balance;
  final List<WalletTransaction> recentTransactions;

  const WalletHomeData({
    required this.balance,
    required this.recentTransactions,
  });

  factory WalletHomeData.fromJson(Map<String, dynamic> json) {
    return WalletHomeData(
      balance: WalletBalance.fromJson(json['balance']),
      recentTransactions: (json['recentTransactions'] as List)
          .map((e) => WalletTransaction.fromJson(e))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [balance, recentTransactions];
}

class WalletBalance extends Equatable {
  final double totalBalance;
  final double totalDeposits;
  final double totalWithdrawals;

  const WalletBalance({
    required this.totalBalance,
    required this.totalDeposits,
    required this.totalWithdrawals,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      totalBalance: (json['totalBalance'] as num).toDouble(),
      totalDeposits: (json['totalDeposits'] as num).toDouble(),
      totalWithdrawals: (json['totalWithdrawals'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalBalance': totalBalance,
        'totalDeposits': totalDeposits,
        'totalWithdrawals': totalWithdrawals,
      };

  @override
  List<Object?> get props => [totalBalance, totalDeposits, totalWithdrawals];
}

class WalletTransaction extends Equatable {
  final int id;
  final String? userId; // اختياري – قد لا يأتي في بعض الاستجابات
  final String title;
  final String? description;
  final double amount;
  final DateTime transactionDate;
  final String type;
  final String category;
  final bool isRecurring;
  final String? recurringInterval;
  final DateTime? recurringEndDate;
  final DateTime? createdAt; // اختياري – قد لا يأتي في بعض الاستجابات
  final DateTime? updatedAt; // اختياري

  const WalletTransaction({
    required this.id,
    this.userId,
    required this.title,
    this.description,
    required this.amount,
    required this.transactionDate,
    required this.type,
    required this.category,
    this.isRecurring = false,
    this.recurringInterval,
    this.recurringEndDate,
    this.createdAt,
    this.updatedAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      userId: json['userId']?.toString(), // لو موجود، يحوله ل String
      title: json['title'],
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      transactionDate: DateTime.parse(json['transactionDate']),
      type: json['type'],
      category: json['category'],
      isRecurring: json['isRecurring'] ?? false,
      recurringInterval: json['recurringInterval'],
      recurringEndDate: json['recurringEndDate'] != null
          ? DateTime.parse(json['recurringEndDate'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (userId != null) 'userId': userId,
        'title': title,
        if (description != null) 'description': description,
        'amount': amount,
        'transactionDate': transactionDate.toIso8601String(),
        'type': type,
        'category': category,
        'isRecurring': isRecurring,
        if (recurringInterval != null) 'recurringInterval': recurringInterval,
        if (recurringEndDate != null)
          'recurringEndDate': recurringEndDate!.toIso8601String(),
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  bool get isDeposit => type.toLowerCase() == 'deposit';
  bool get isWithdrawal => type.toLowerCase() == 'withdrawal';

  String get formattedAmount =>
      '${isDeposit ? '+' : '-'}\$${amount.toStringAsFixed(2)}';

  IconData get icon {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'salary':
        return Icons.account_balance_wallet;
      case 'shopping':
        return Icons.shopping_bag;
      case 'transport':
      case 'transportation':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'bill':
      case 'bills':
        return Icons.receipt;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      default:
        return isDeposit ? Icons.arrow_downward : Icons.arrow_upward;
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        amount,
        transactionDate,
        type,
        category,
        isRecurring,
        recurringInterval,
        recurringEndDate,
        createdAt,
        updatedAt,
      ];
}

class TransactionListResponse extends Equatable {
  final List<WalletTransaction> transactions;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  const TransactionListResponse({
    required this.transactions,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory TransactionListResponse.fromJson(Map<String, dynamic> json) {
    return TransactionListResponse(
      transactions: (json['transactions'] as List)
          .map((e) => WalletTransaction.fromJson(e))
          .toList(),
      totalCount: json['totalCount'],
      page: json['page'],
      pageSize: json['pageSize'],
      totalPages: json['totalPages'],
    );
  }

  @override
  List<Object?> get props => [transactions, totalCount, page, pageSize, totalPages];
}

class WalletSummary extends Equatable {
  final double totalIncome;
  final double totalExpenses;
  final double netSavings;
  final List<CategorySummary> expensesByCategory;
  final List<CategorySummary> incomeByCategory;
  final int transactionCount;

  const WalletSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netSavings,
    required this.expensesByCategory,
    required this.incomeByCategory,
    required this.transactionCount,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      totalIncome: (json['totalIncome'] as num).toDouble(),
      totalExpenses: (json['totalExpenses'] as num).toDouble(),
      netSavings: (json['netSavings'] as num).toDouble(),
      expensesByCategory: (json['expensesByCategory'] as List)
          .map((e) => CategorySummary.fromJson(e))
          .toList(),
      incomeByCategory: (json['incomeByCategory'] as List)
          .map((e) => CategorySummary.fromJson(e))
          .toList(),
      transactionCount: json['transactionCount'],
    );
  }

  @override
  List<Object?> get props => [
        totalIncome,
        totalExpenses,
        netSavings,
        expensesByCategory,
        incomeByCategory,
        transactionCount,
      ];
}

class CategorySummary extends Equatable {
  final String category;
  final double total;
  final int count;

  const CategorySummary({
    required this.category,
    required this.total,
    required this.count,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      category: json['category'],
      total: (json['total'] as num).toDouble(),
      count: json['count'],
    );
  }

  @override
  List<Object?> get props => [category, total, count];
}