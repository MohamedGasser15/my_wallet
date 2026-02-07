// features/wallet/data/models/wallet_models.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class WalletHomeResponse extends Equatable {
  final bool success;
  final String? message;
  final WalletHomeData data;

  const WalletHomeResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory WalletHomeResponse.fromJson(Map<String, dynamic> json) {
    return WalletHomeResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: WalletHomeData.fromJson(json['data']),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

class WalletHomeData extends Equatable {
  final WalletBalance balance;
  final List<WalletTransaction> recentTransactions;
  final WalletSummary? monthlySummary;

  const WalletHomeData({
    required this.balance,
    required this.recentTransactions,
    this.monthlySummary,
  });

  factory WalletHomeData.fromJson(Map<String, dynamic> json) {
    return WalletHomeData(
      balance: WalletBalance.fromJson(json['balance']),
      recentTransactions: (json['recentTransactions'] as List)
          .map((e) => WalletTransaction.fromJson(e))
          .toList(),
      monthlySummary: json['monthlySummary'] != null
          ? WalletSummary.fromJson(json['monthlySummary'])
          : null,
    );
  }

  @override
  List<Object?> get props => [balance, recentTransactions, monthlySummary];
}

class WalletBalance extends Equatable {
  final double totalBalance;
  final double totalDeposits;
  final double totalWithdrawals;
  final DateTime lastUpdated;

  const WalletBalance({
    required this.totalBalance,
    required this.totalDeposits,
    required this.totalWithdrawals,
    required this.lastUpdated,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      totalBalance: (json['totalBalance'] as num).toDouble(),
      totalDeposits: (json['totalDeposits'] as num).toDouble(),
      totalWithdrawals: (json['totalWithdrawals'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalBalance': totalBalance,
        'totalDeposits': totalDeposits,
        'totalWithdrawals': totalWithdrawals,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [totalBalance, totalDeposits, totalWithdrawals, lastUpdated];
}

class WalletTransaction extends Equatable {
  final int id;
  final int userId;
  final String title;
  final String description;
  final double amount;
  final DateTime date;
  final String type;
  final String category;
  final String? attachmentUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalletTransaction({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    this.attachmentUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      type: json['type'],
      category: json['category'],
      attachmentUrl: json['attachmentUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'type': type,
        'category': category,
        'attachmentUrl': attachmentUrl,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  bool get isDeposit => type.toLowerCase() == 'deposit';
  bool get isWithdrawal => type.toLowerCase() == 'withdrawal';
  
  String get formattedAmount => '${isDeposit ? '+' : '-'}\$${amount.toStringAsFixed(2)}';
  
  IconData get icon {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'salary':
        return Icons.account_balance_wallet;
      case 'shopping':
        return Icons.shopping_bag;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'bill':
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
        date,
        type,
        category,
        attachmentUrl,
        createdAt,
        updatedAt,
      ];
}

class WalletSummary extends Equatable {
  final double totalDeposits;
  final double totalWithdrawals;
  final double netBalance;
  final DateTime periodStart;
  final DateTime periodEnd;

  const WalletSummary({
    required this.totalDeposits,
    required this.totalWithdrawals,
    required this.netBalance,
    required this.periodStart,
    required this.periodEnd,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      totalDeposits: (json['totalDeposits'] as num).toDouble(),
      totalWithdrawals: (json['totalWithdrawals'] as num).toDouble(),
      netBalance: (json['netBalance'] as num).toDouble(),
      periodStart: DateTime.parse(json['periodStart']),
      periodEnd: DateTime.parse(json['periodEnd']),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalDeposits': totalDeposits,
        'totalWithdrawals': totalWithdrawals,
        'netBalance': netBalance,
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [totalDeposits, totalWithdrawals, netBalance, periodStart, periodEnd];
}