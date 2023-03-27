import 'package:sora_flutter_sdk/sora_flutter_sdk.dart';

import './event_stream.dart';

// SoraClient のイベントを監視する
class SoraClientEventController {
  // TODO: state, timeout, 長時間配信用タイマー
  SoraClientEventController(this.client, {int timeout = 5}) {
    this.timeout = timeout;
    stream = SoraClientEventStream(client);
  }

  final SoraClient client;

  // 接続が完了するまでのタイムアウト
  late final int timeout;

  late final SoraClientEventStream stream;

  // 接続が完了したかどうか
  // type: notify が来ていれば true
  bool get hasConnected => stream.hasOnNotify;

  bool get disposed => client.disposed;

  // 接続する
  // wait = true の場合、接続が完了するまで待つ
  Future<void> connect({bool wait = true}) async {
    await client.connect();
    if (wait) {
      var cont = true;
      await Future.doWhile(() async {
        await Future.delayed(Duration(seconds: 1));
        return cont && !hasConnected && !stream.hasOnDisconnect;
      }).timeout(Duration(seconds: timeout), onTimeout: () {
        cont = false;
      });
    }
  }

  // 切断する
  // 切断済みの場合は false を返す
  Future<bool> dispose() async {
    if (!client.disposed) {
      stream.close();
      await client.dispose();
      return true;
    } else {
      return false;
    }
  }
}
