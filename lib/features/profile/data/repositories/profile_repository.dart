import 'dart:convert';
import 'package:my_wallet/core/constants/api_constants.dart';
import 'package:my_wallet/core/services/api_service.dart';
import 'package:my_wallet/core/utils/shared_prefs.dart';
import 'package:my_wallet/features/profile/data/models/user_profile.dart';

class ProfileRepository {
  final ApiService _apiService = ApiService();

  // جلب بيانات الملف الشخصي
  Future<UserProfile> getProfile() async {
    // الأول نجرب نجيب البيانات من SharedPrefs
    final userDataString = SharedPrefs.userData;
    if (userDataString != null) {
      final Map<String, dynamic> userData = jsonDecode(userDataString);
      return UserProfile.fromJson(userData);
    }

    // لو مش موجودة، نجيبها من API (لازم تضيف endpoint)
    // final response = await _apiService.get(ApiEndpoints.profileGet, requiresAuth: true);
    // final data = _apiService.handleResponse(response);
    // return UserProfile.fromJson(data['data']);

    throw Exception('No profile data found');
  }

  // تحديث الملف الشخصي
  Future<UserProfile> updateProfile({
    required String fullName,
    required String userName,
    required String phoneNumber,
    String? profileImage,
  }) async {
    // استدعاء API التحديث (لازم تضيف endpoint)
    final response = await _apiService.post(
      ApiEndpoints.profileUpdate, // هنضيفه بعد شوية
      {
        'fullName': fullName,
        'userName': userName,
        'phoneNumber': phoneNumber,
        'profileImage': profileImage,
      },
      requiresAuth: true,
    );

    final data = _apiService.handleResponse(response);

    if (data['success'] == true) {
      // تحديث البيانات المخزنة محلياً
      final currentUserData = SharedPrefs.userData != null
          ? jsonDecode(SharedPrefs.userData!)
          : {};
      final updatedUser = UserProfile(
        fullName: fullName,
        userName: userName,
        email: currentUserData['email'] ?? '',
        phoneNumber: phoneNumber,
        profileImageUrl: profileImage,
      );
      await SharedPrefs.setUserData(jsonEncode(updatedUser.toJson()));
      return updatedUser;
    } else {
      throw Exception(data['message'] ?? 'Failed to update profile');
    }
  }
}