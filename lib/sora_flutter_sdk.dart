import 'sora_flutter_sdk_platform_interface.dart';

import 'sora_client.dart';

class SoraFlutterSdk {
  Future<SoraClient> createSoraClient(SoraClientConfig config) {
    return SoraFlutterSdkPlatform.instance.createSoraClient(config);
  }
}
