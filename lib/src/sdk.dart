import 'dart:typed_data';

import 'client.dart';
import 'platform_interface.dart';

class SoraFlutterSdk {
  static Future<SoraClient> createSoraClient(SoraClientConfig config) {
    return SoraFlutterSdkPlatform.instance.createSoraClient(config);
  }

  static Future<bool> sendDataChannel({
    required SoraClient client,
    required String label,
    required Uint8List data,
  }) async {
    return SoraFlutterSdkPlatform.instance.sendDataChannel(
      client: client,
      label: label,
      data: data,
    );
  }

  static Future<void> setVideoEnabled({
    required SoraClient client,
    required bool flag,
  }) async =>
      await SoraFlutterSdkPlatform.instance
          .setVideoEnabled(client: client, flag: flag);

  static Future<void> setAudioEnabled({
    required SoraClient client,
    required bool flag,
  }) async =>
      await SoraFlutterSdkPlatform.instance
          .setAudioEnabled(client: client, flag: flag);

  static Future<void> setLyraModelPath(String path) async {
    SoraFlutterSdkPlatform.instance.setLyraModelPath(path);
  }
}
