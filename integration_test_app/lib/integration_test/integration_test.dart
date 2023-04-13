import 'package:integration_test_app/environment.dart';
import 'package:integration_test_app/integration_test/connect_test.dart';
import 'package:sora_flutter_sdk/sora_flutter_sdk.dart';

abstract class _DartDefine {
  static const String testMode = 'TEST_MODE';
  static const String testTarget = 'TEST_TARGET';
}

enum SDKIntegrationTestMode {
  standard,
  app_run,
}

abstract class SDKIntegrationTest {
  static SDKIntegrationTestMode loadTestMode() {
    final s = String.fromEnvironment(_DartDefine.testMode,
        defaultValue: SDKIntegrationTestMode.standard.name);
    return SDKIntegrationTestMode.values.firstWhere((e) => e.name == s);
  }

  static bool get isStandardMode =>
      loadTestMode() == SDKIntegrationTestMode.standard;

  static bool get isAppRunMode =>
      loadTestMode() == SDKIntegrationTestMode.app_run;

  static void setup() {
    SoraClientConfig.flutterVersion = Environment.flutterVersion;
  }

  static void runAllTests() {
    final s = String.fromEnvironment(_DartDefine.testMode);
    if (s.isEmpty || s == 'connect') {
      connectTest();
    }
  }
}
