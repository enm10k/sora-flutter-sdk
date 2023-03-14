import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:sora_flutter_sdk/src/platform_interface.dart';

/// 端末に搭載されているデバイスの名前です。
/// デバイス名は [DeviceList.videoCapturers] などの API で取得できます。
///
/// デバイス名は [SoraClientConfig.videoDeviceName] や [SoraClient.switchVideoDevice] でカメラを指定するのに使います。
class DeviceName {
  @protected
  DeviceName({
    required String name,
    required String id,
  }) {
    _name = name;
    _id = id;
  }

  /// デバイス名
  String get name => _name;

  late final String _name;

  /// デバイス ID
  String get id => _id;

  late final String _id;

  @override
  String toString() {
    return '<Device "$_name", "$_id">';
  }

  @override
  bool operator ==(Object other) {
    return other is DeviceName && _id == other._id;
  }

  @override
  int get hashCode {
    return _id.hashCode;
  }
}

/// 端末に搭載されているデバイスのリストを取得します。
class DeviceList {
  static Future<DeviceName?> _findDeviceName(String name) async {
    return (await videoCapturers()).firstWhereOrNull(
      (DeviceName e) => e.name.contains(name),
    );
  }

  /// 前面カメラの名前を返します。
  ///
  /// 本メソッドは iOS と Android のみ対応しています。
  static Future<DeviceName?> frontCamera() async {
    try {
      if (Platform.isIOS) {
        return _findDeviceName('Front Camera');
      } else if (Platform.isAndroid) {
        return _findDeviceName('@+frontfacing');
      } else {
        return null;
      }
    } on Exception catch (_) {
      return null;
    }
  }

  /// 背面カメラの名前を返します。
  ///
  /// 本メソッドは iOS と Android のみ対応しています。
  static Future<DeviceName?> backCamera() async {
    try {
      if (Platform.isIOS) {
        return _findDeviceName('Back Camera');
      } else if (Platform.isAndroid) {
        return _findDeviceName('@+backfacing');
      } else {
        return null;
      }
    } on Exception catch (_) {
      return null;
    }
  }

  /// 端末に搭載されているカメラのリストを返します。
  static Future<List<DeviceName>> videoCapturers() async {
    final capturers = await SoraFlutterSdkPlatform.instance.videoCapturers();
    return capturers.map((resp) {
      final Map<dynamic, dynamic> map = resp;
      return DeviceName(
        name: map['device'],
        id: map['unique'],
      );
    }).toList();
  }
}
