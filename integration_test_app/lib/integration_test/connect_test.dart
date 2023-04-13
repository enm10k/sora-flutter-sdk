import 'dart:io';
import 'dart:ui';

import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test_app/config.dart';
import 'package:integration_test_app/environment.dart';
import 'package:integration_test_app/main.dart' as app;
import 'package:integration_test_app/test/event_controller.dart';
import 'package:sora_flutter_sdk/sora_flutter_sdk.dart';

void connectTest() {
  group('接続テスト', () {
    testWidgets('接続と切断 (recvonly)', (tester) async {
      // アプリが起動するまで待つ
      await tester.pumpAndSettle();

      final config = createClientConfig(role: SoraRole.recvonly);
      final client = await SoraClient.create(config);
      final controller = SoraClientEventController(client);

      await controller.connect();
      expect(controller.hasConnected, isTrue);
      expect(controller.disposed, isFalse);
      await controller.dispose();
      expect(controller.disposed, isTrue);
    });

    testWidgets('接続と切断 (sendonly)', (tester) async {
      await tester.pumpAndSettle();

      final config = createClientConfig(role: SoraRole.sendonly);
      final client = await SoraClient.create(config);
      final controller = SoraClientEventController(client);

      await controller.connect();
      expect(controller.hasConnected, isTrue);
      expect(controller.disposed, isFalse);
      await controller.dispose();
      expect(controller.disposed, isTrue);
    });

    testWidgets('接続と切断 (sendrecv)', (tester) async {
      await tester.pumpAndSettle();

      final config = createClientConfig(role: SoraRole.sendrecv);
      final client = await SoraClient.create(config);
      final controller = SoraClientEventController(client);

      await controller.connect();
      expect(controller.hasConnected, isTrue);
      expect(controller.disposed, isFalse);
      await controller.dispose();
      expect(controller.disposed, isTrue);
    });

    testWidgets('接続と切断を繰り返す', (tester) async {
      await tester.pumpAndSettle();

      final n = 10;
      for (var i = 0; i < n; i++) {
        final config = createClientConfig(role: SoraRole.recvonly);
        final client = await SoraClient.create(config);
        final controller = SoraClientEventController(client);

        await controller.connect();
        expect(controller.hasConnected, isTrue);
        expect(controller.disposed, isFalse);
        await controller.dispose();
        expect(controller.disposed, isTrue);
      }
    });

    testWidgets('WebSocket 接続タイムアウト', (tester) async {
      await tester.pumpAndSettle();

      final config = createClientConfig(
        role: SoraRole.recvonly,
        signalingUrls: [Uri.parse('ws://localhost:8080')],
      );
      final client = await SoraClient.create(config);
      final controller = SoraClientEventController(client);

      // 何もしないサーバーを起動
      final server = await HttpServer.bind('localhost', 8080);

      await controller.connect();
      expect(controller.onDisconnectCalled, isTrue);
      expect(controller.hasConnected, isFalse);
      expect(controller.disposed, isTrue);
      await controller.dispose();

      server.close();
    });

    testWidgets('複数同時接続 (recvonly)', (tester) async {
      final controllers = <SoraClientEventController>[];
      for (var i = 0; i < 10; i++) {
        final config = createClientConfig(role: SoraRole.recvonly);
        final client = await SoraClient.create(config);
        final controller = SoraClientEventController(client);
        controllers.add(controller);
      }

      // 接続
      for (var controller in controllers) {
        await controller.connect();
        expect(controller.hasConnected, isTrue);
        expect(controller.disposed, isFalse);
      }

      // すべての接続の完了後、接続を維持できているかどうか
      for (var controller in controllers) {
        expect(controller.hasConnected, isTrue);
        expect(controller.disposed, isFalse);
      }

      // 切断
      for (var controller in controllers) {
        await controller.dispose();
        expect(controller.disposed, isTrue);
      }
    });

    // TODO: sendonly + recvonly * n
    // TODO: sendrecv + recvonly * n
  });
}
