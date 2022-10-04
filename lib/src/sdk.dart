import 'platform_interface.dart';

import 'client.dart';

class SoraFlutterSdk {
  static Future<SoraClient> createSoraClient(SoraClientConfig config) {
    return SoraFlutterSdkPlatform.instance.createSoraClient(config);
  }
}
