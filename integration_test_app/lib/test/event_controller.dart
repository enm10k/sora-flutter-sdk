import 'package:sora_flutter_sdk/sora_flutter_sdk.dart';

import './event_stream.dart';

class SoraClientEventController {
  // TODO: state, timeout, 長時間配信用タイマー
  SoraClientEventController(this.client) {
    stream = SoraClientEventStream(client);
  }

  final SoraClient client;

  late final SoraClientEventStream stream;

  bool get hasConnected => stream.hasOnNotify;

  Future<void> connect({bool wait = true}) async {
    await client.connect();
    if (wait) {
      print('wait');
      await Future.doWhile(() async {
        return !hasConnected;
      });
    }
  }

  Future<void> dispose() async {
    await client.dispose();
    stream.close();
  }
}
