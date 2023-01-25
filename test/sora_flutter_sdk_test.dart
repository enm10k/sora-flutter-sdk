/*
import 'package:flutter_test/flutter_test.dart';
import 'package:sora_flutter_sdk/sora_client.dart';
import 'package:sora_flutter_sdk/sora_flutter_sdk.dart';
import 'package:sora_flutter_sdk/sora_flutter_sdk_platform_interface.dart';
import 'package:sora_flutter_sdk/sora_flutter_sdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSoraFlutterSdkPlatform
    with MockPlatformInterfaceMixin
    implements SoraFlutterSdkPlatform {
  @override
  Future<SoraClient> createSoraClient(SoraClientConfig config) =>
      Future.value(SoraClient({'client_id': 0, 'event_channel': 'test'},
          (config) async {}, (config) async {}));
}

void main() {
  final SoraFlutterSdkPlatform initialPlatform =
      SoraFlutterSdkPlatform.instance;

  test('$MethodChannelSoraFlutterSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSoraFlutterSdk>());
  });

  test('createSoraClient', () async {
    //SoraFlutterSdk soraFlutterSdkPlugin = SoraFlutterSdk();
    //MockSoraFlutterSdkPlatform fakePlatform = MockSoraFlutterSdkPlatform();
    //SoraFlutterSdkPlatform.instance = fakePlatform;

    //var config = SoraClientConfig();
    //await soraFlutterSdkPlugin.createSoraClient(config);
  });
}
*/
