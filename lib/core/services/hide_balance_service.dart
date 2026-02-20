import 'package:flutter/material.dart';
import 'package:my_wallet/core/constants/app_constants.dart';
import 'package:my_wallet/core/utils/shared_prefs.dart';

class HideBalanceService extends ChangeNotifier {
  bool _isHidden = false;

  bool get isHidden => _isHidden;

  HideBalanceService() {
    _load();
  }

  Future<void> _load() async {
    _isHidden = SharedPrefs.getBoolValue(AppConstants.hideBalancesKey) ?? false;
    notifyListeners();
  }

  // تبديل الحالة (يستخدمها زر العين السريع)
  Future<void> toggle() async {
    _isHidden = !_isHidden;
    await SharedPrefs.setBool(AppConstants.hideBalancesKey, _isHidden);
    notifyListeners();
  }

  // تعيين حالة معينة (يستخدمها الـ Switch في الإعدادات)
  Future<void> setHidden(bool value) async {
    if (_isHidden != value) {
      _isHidden = value;
      await SharedPrefs.setBool(AppConstants.hideBalancesKey, _isHidden);
      notifyListeners();
    }
  }
}