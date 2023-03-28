import 'dart:async';

import 'package:sora_flutter_sdk/sora_flutter_sdk.dart';

import './event.dart';

// SoraClient のイベントをストリームで扱う
// 取得したイベントはブロードキャストで配信される
class SoraClientEventStream extends Stream {
  SoraClientEventStream(this.client, {this.onDisconnect}) {
    // TODO: 各コールバック
    client.onDisconnect = (errorCode, message) {
      hasOnDisconnect = true;
      final event = SoraClientEvent.onDisconnect(errorCode, message);
      _add(event);
      if (onDisconnect != null) {
        onDisconnect!(event);
      }
      close();
    };
    client.onNotify = (text) {
      hasOnNotify = true;
      _add(SoraClientEvent.onNotify(text));
    };
  }

  final SoraClient client;

  late final _controller = StreamController<SoraClientEvent>.broadcast();

  var hasOnDisconnect = false;
  var hasOnNotify = false;

  final void Function(SoraClientEvent)? onDisconnect;

  void _add(SoraClientEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  @override
  StreamSubscription listen(
    void Function(dynamic event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  void close() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
