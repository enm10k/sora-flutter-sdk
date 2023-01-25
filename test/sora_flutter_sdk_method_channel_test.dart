/*
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sora_flutter_sdk/sora_client.dart';
import 'package:sora_flutter_sdk/sora_flutter_sdk_method_channel.dart';

void main() {
  MethodChannelSoraFlutterSdk platform = MethodChannelSoraFlutterSdk();
  const MethodChannel channel = MethodChannel('sora_flutter_sdk');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return {'client_id': 0, 'event_channel': 'test'};
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('createSoraClient', () async {
    var config = SoraClientConfig();
    await platform.createSoraClient(config);
  });
}
*/
