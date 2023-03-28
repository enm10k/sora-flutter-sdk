import 'package:sora_flutter_sdk/sora_flutter_sdk.dart';

import './event_stream.dart';

// SoraClient のイベントを監視する
class SoraClientEventController {
  // TODO: state, timeout, 長時間配信用タイマー
  SoraClientEventController(this.client, {int timeout = 5}) {
    this.timeout = timeout;
    stream = SoraClientEventStream(client, onDisconnect: (_) {
      hasOnDisconnect = true;
      _finishAttempt();
    });
  }

  final SoraClient client;

  // 接続試行のタイムアウト (秒)
  // SoraClientConfig の disconnectWaitTime とは別で、
  // disconnectWaitTime にかかわらずタイムアウトする
  late final int timeout;

  late final SoraClientEventStream stream;

  bool hasOnDisconnect = false;

  // 接続が完了したかどうか
  // type: notify が来ていれば true
  bool get hasConnected => stream.hasOnNotify;

  // 切断済みかどうか
  bool get disposed => client.disposed;

  // 接続試行開始から接続完了または失敗までに待機した時間 (ミリ秒)
  int waitedTime = 0;

  DateTime? _attemptStartTime;

  void _finishAttempt() {
    if (_attemptStartTime != null) {
      waitedTime = DateTime.now().difference(_attemptStartTime!).inMilliseconds;
      _attemptStartTime = null;
    }
  }

  // 接続する
  // wait = true の場合、接続が完了するまで待つ
  Future<void> connect({bool wait = true}) async {
    _attemptStartTime = DateTime.now();
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
    _finishAttempt();
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
