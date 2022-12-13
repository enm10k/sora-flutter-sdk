import 'dart:io';

import 'package:sora_flutter_sdk/src/platform_interface.dart';

class DeviceName {
  DeviceName({required this.device, required this.unique});
  final String device;
  final String unique;
}

class DeviceList {
  static String? get frontCamera {
    try {
      if (Platform.isIOS) {
        return 'Front Camera';
      } else {
        return null;
      }
    } on Exception catch (_) {
      return null;
    }
  }

  static String? get backCamera {
    try {
      if (Platform.isIOS) {
        return 'Back Camera';
      } else {
        return null;
      }
    } on Exception catch (_) {
      return null;
    }
  }

  static Future<List<DeviceName>> videoCapturers() async {
    final capturers = await SoraFlutterSdkPlatform.instance.videoCapturers();
    return capturers.map((resp) {
      final Map<dynamic, dynamic> map = resp;
      return DeviceName(device: map['device'], unique: map['unique']);
    }).toList();
  }
}
