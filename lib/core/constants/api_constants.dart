// core/constants/api_constants.dart
class ApiEndpoints {
  // Auth
  static const String sendVerification = 'api/auth/send-verification';
  static const String verifyCode = 'api/auth/verify-code';
  static const String resendCode = 'api/auth/resend-code';
  static const String verifyAndComplete = 'api/auth/verify-complete';
  static const String logout = 'api/auth/logout';
  static const String checkEmail = 'api/auth/check-email';
  
  // Wallet
  static const String walletHome = 'api/wallet/home';
  static const String walletBalance = 'api/wallet/balance';
  static const String walletTransactions = 'api/wallet/transactions';
  static const String walletAddTransaction = 'api/wallet/transactions/add';
  static const String walletDeleteTransaction = 'api/wallet/transactions/delete';
  static const String walletSummary = 'api/wallet/summary';

  // Profile
  static const String profileGet = 'api/profile/get';
  static const String profileUpdate = 'api/profile/update';
}