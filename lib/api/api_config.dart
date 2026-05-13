import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // 1. Android Emulator URL (Special IP for host machine)
  static const String _emulatorUrl = 'http://10.0.2.2:4000/api/v1';

  // 2. Physical Device URL (Use 127.0.0.1 with 'adb reverse')
  static const String _physicalDeviceUrl = 'http://127.0.0.1:4000/api/v1';
  static const String _physicalMinioUrl = 'http://127.0.0.1:9000';

  // 3. Production URL (Placeholder)
  static const String _productionUrl = 'https://api.yourproductiondomain.com/api/v1';
  static const String _productionMinioUrl = 'https://s3.yourproductiondomain.com';

  /// Automatically returns the correct base URL based on the environment and device type.
  static Future<String> getBaseUrl() async {
    if (kReleaseMode) return _productionUrl;

    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.isPhysicalDevice ? _physicalDeviceUrl : _emulatorUrl;
    }
    return _physicalDeviceUrl;
  }

  /// Automatically returns the correct MinIO/S3 base URL.
  static Future<String> getMinioUrl() async {
    if (kReleaseMode) return _productionMinioUrl;

    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      // 10.0.2.2 for emulator, 127.0.0.1 for physical device (requires adb reverse)
      return androidInfo.isPhysicalDevice ? _physicalMinioUrl : 'http://10.0.2.2:9000';
    }
    return _physicalMinioUrl;
  }
}

