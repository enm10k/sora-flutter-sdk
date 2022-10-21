import 'platform_interface.dart';

import 'client.dart';

class SoraFlutterSdk {
  static Future<SoraClient> createSoraClient(SoraClientConfig config) {
    return SoraFlutterSdkPlatform.instance.createSoraClient(config);
  }

  static Future<void> destroySoraClient(SoraClient client) async {
    return await SoraFlutterSdkPlatform.instance.destroySoraClient(client);
  }
}
