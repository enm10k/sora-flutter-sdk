import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test_app/environment.dart';
import 'package:integration_test_app/integration_test/connect_test.dart';
import 'package:integration_test_app/integration_test/integration_test.dart';
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
  // fromEnvironment の値は static const に入れる必要がある
  static const _testMode = String.fromEnvironment(_DartDefine.testMode);
  static const _testTarget = String.fromEnvironment(_DartDefine.testTarget);

  static SDKIntegrationTestMode get testMode {
    return SDKIntegrationTestMode.values.firstWhere(
      (e) => e.name == _testMode,
      orElse: () => SDKIntegrationTestMode.standard,
    );
  }

  static bool get isStandardMode => testMode == SDKIntegrationTestMode.standard;

  static bool get isAppRunMode => testMode == SDKIntegrationTestMode.app_run;

  static String? get testTarget => _testTarget.isEmpty ? null : _testTarget;

  static TestWidgetsFlutterBinding? _binding;

  static void setup() {
    if (isAppRunMode) {
      _binding = LiveTestWidgetsFlutterBinding.ensureInitialized();
    } else {
      _binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    }

    SoraClientConfig.flutterVersion = Environment.flutterVersion;
  }

  static void runAllTests() {
    if (testTarget == null || testTarget == 'connect') {
      connectTest();
    }

    // デスクトップの場合はテストが終了したら強制的にアプリを終了する
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_binding != null && !_binding!.inTest) {
          timer.cancel();
          exit(0);
        }
      });
    }
  }
}
