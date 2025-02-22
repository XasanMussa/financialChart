import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

Future<String?> getDeviceId() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String? deviceId;

  try {
    if (Platform.isAndroid) {
      // Android-specific code
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.device;
      print(deviceId); // Unique ID for Android devices
    } else if (Platform.isIOS) {
      // iOS-specific code
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor; // Unique ID for iOS devices
    }
  } catch (e) {
    print("Error fetching device ID: $e");
  }

  return deviceId;
}
