import 'dart:async';

import 'package:sora_flutter_sdk/sora_flutter_sdk.dart';

import './event.dart';

class SoraClientEventStream extends Stream {
  SoraClientEventStream(this.client) {
    // TODO: 各コールバック
    client.onDisconnect = (errorCode, message) {
      print('onDisconnect');
      hasOnDisconnect = true;
      _controller.add(SoraClientEvent.onDisconnect(errorCode, message));
      _controller.close();
    };
    client.onNotify = (text) {
      print('onNotify');
      hasOnNotify = true;
      _controller.add(SoraClientEvent.onNotify(text));
    };
  }

  final SoraClient client;

  late final _controller = StreamController<SoraClientEvent>.broadcast();

  var hasOnDisconnect = false;
  var hasOnNotify = false;

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
    _controller.close();
  }
}
