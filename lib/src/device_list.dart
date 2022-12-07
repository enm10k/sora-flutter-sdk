import 'dart:math';

import 'package:flutter/services.dart';
import 'package:sora_flutter_sdk/src/platform_interface.dart';

class DeviceList {
  static String _randomEventChannelName() {
    final n = Random().nextInt(10000);
    return 'SoraFlutterSdk/DeviceList/Event/$n';
  }

  static void videoCapturers(
      void Function(String deviceName, String uniqueName) f) {
    final callback = _randomEventChannelName();
    SoraFlutterSdkPlatform.instance.videoCapturers(callback);
    EventChannel(callback).receiveBroadcastStream().listen((event) {
      final Map<dynamic, dynamic> map = event;
      f(map['device'], map['unique']);
    }, onError: (obj) {
      if (obj is Exception) {
        throw obj;
      }
    });
  }
}
