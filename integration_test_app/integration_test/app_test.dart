import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test_app/config.dart';
import 'package:integration_test_app/main.dart' as app;
import 'package:integration_test_app/test/event_controller.dart';
import 'package:sora_flutter_sdk/sora_flutter_sdk.dart';

// 実行方法
// $ flutter test integration_test/app_test.dart -d <DEVICE_ID>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('', () {
    testWidgets('', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final config = createClientConfig(role: SoraRole.recvonly);
      config.noVideoDevice = true;
      //config.video = false;
      //config.audio = false;
      final client = await SoraClient.create(config);
      final controller = SoraClientEventController(client);
      final queue = StreamQueue(controller.stream);
      await controller.connect();
      await controller.tryDispose();
    });
  });
}
