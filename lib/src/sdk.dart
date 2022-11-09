import 'platform_interface.dart';

import 'client.dart';

class SoraFlutterSdk {
  static Future<SoraClient> createSoraClient(SoraClientConfig config) {
    return SoraFlutterSdkPlatform.instance.createSoraClient(config);
  }

  static Future<bool> sendDataChannel({
    required SoraClient client,
    required String label,
    required String data,
  }) async {
    return SoraFlutterSdkPlatform.instance.sendDataChannel(
      client: client,
      label: label,
      data: data,
    );
  }
}
