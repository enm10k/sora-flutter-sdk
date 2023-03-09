import 'dart:io';

import 'package:collection/collection.dart';
import 'package:sora_flutter_sdk/src/platform_interface.dart';

/// 端末に搭載されているデバイスの名前です。
/// デバイス名は [DeviceList.videoCapturers] などの API で取得できます。
///
/// デバイス名は [SoraClientConfig.videoDeviceName] や [SoraClient.switchVideoDevice] でカメラを指定するのに使います。
/// [device], [unique] のどちらも使用できます。
class DeviceName {
  DeviceName({required this.index, required this.device, required this.unique});

  final int index;

  /// デバイス名
  final String device;

  /// デバイスのユニーク名
  final String unique;

  @override
  String toString() {
    return '<Device $index, $device, $unique>';
  }

  @override
  bool operator ==(Object other) {
    return other is DeviceName && unique == other.unique;
  }

  @override
  int get hashCode {
    return unique.hashCode;
  }
}

/// 端末に搭載されているデバイスのリストを取得します。
class DeviceList {
  /// 前面カメラの名前を返します。
  ///
  /// 本メソッドは iOS と Android のみ対応しています。
  static Future<String?> frontCamera() async {
    try {
      if (Platform.isIOS) {
        return 'Front Camera';
      } else if (Platform.isAndroid) {
        return (await videoCapturers())
            .firstWhereOrNull(
              (DeviceName e) => e.device.contains('@+frontfacing'),
            )
            ?.device;
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
  static Future<String?> backCamera() async {
    try {
      if (Platform.isIOS) {
        return 'Back Camera';
      } else if (Platform.isAndroid) {
        return (await videoCapturers())
            .firstWhereOrNull(
              (DeviceName e) => e.device.contains('@+backfacing'),
            )
            ?.device;
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
    var i = 0;
    return capturers.map((resp) {
      final Map<dynamic, dynamic> map = resp;
      final device = DeviceName(
        index: i,
        device: map['device'],
        unique: map['unique'],
      );
      i++;
      return device;
    }).toList();
  }
}
