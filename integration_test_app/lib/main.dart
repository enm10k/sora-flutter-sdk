import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test_app/integration_test/connect_test.dart';
import 'package:integration_test_app/integration_test/integration_test.dart';
import 'package:sora_flutter_sdk/sora_flutter_sdk.dart';

import 'environment.dart';

void main() async {
  SDKIntegrationTest.setup();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (SDKIntegrationTest.isAppRunMode) {
      SDKIntegrationTest.runAllTests();
    }

    return MaterialApp(
        home: Scaffold(
      body: Container(),
    ));
  }
}
