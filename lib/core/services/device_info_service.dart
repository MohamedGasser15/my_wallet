import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Dio _dio = Dio();

  Future<String> getDeviceName() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.name ?? 'iPhone';
      } else {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      }
    } catch (e) {
      return 'Unknown Device';
    }
  }

  Future<String?> getPublicIp() async {
    try {
      final response = await _dio.get('https://api.ipify.org');
      return response.data as String?;
    } catch (e) {
      return null;
    }
  }
}