import 'package:sora_flutter_sdk/sora_flutter_sdk.dart';

import './event_stream.dart';

class SoraClientEventController {
  // TODO: state, timeout, 長時間配信用タイマー
  SoraClientEventController(this.client, {int timeout = 5}) {
    this.timeout = timeout;
    stream = SoraClientEventStream(client);
  }

  final SoraClient client;
  late final int timeout;
  late final SoraClientEventStream stream;

  bool get hasConnected => stream.hasOnNotify;

  Future<void> connect({bool wait = true}) async {
    await client.connect();
    if (wait) {
      print('wait: timeout $timeout');
      var cont = true;
      await Future.doWhile(() async {
        await Future.delayed(Duration(seconds: 1));
        return cont && !hasConnected && !stream.hasOnDisconnect;
      }).timeout(Duration(seconds: timeout), onTimeout: () {
        cont = false;
      });
      print('end wait');
    }
  }

  Future<void> dispose() async {
    await client.dispose();
    stream.close();
  }
}
