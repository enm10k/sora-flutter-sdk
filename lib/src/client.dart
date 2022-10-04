import 'dart:async';

import 'package:flutter/services.dart';

import 'video_track.dart';

class SoraClientConfig {
  List<String> signalingUrls = List<String>.empty(growable: true);
  String channelId = "";
  String role = "sendrecv";
  int deviceWidth = 640;
  int deviceHeight = 480;
  String videoCodecType = "";
}

class SoraClient {
  int clientId = 0;
  Function? onAddTrack;
  Function? onRemoveTrack;
  List<SoraVideoTrack> tracks = List<SoraVideoTrack>.empty(growable: true);

  String _eventChannel = "";
  final Future<void> Function(SoraClient) _connector;
  final Future<void> Function(SoraClient) _disposer;
  StreamSubscription<dynamic>? _eventSubscription;

  SoraClient(dynamic resp, this._connector, this._disposer) {
    clientId = resp['client_id'];
    _eventChannel = resp['event_channel'];
    _eventSubscription = EventChannel(_eventChannel)
        .receiveBroadcastStream()
        .listen(_eventListener, onError: _errorListener);
  }

  void _eventListener(dynamic event) {
    final Map<dynamic, dynamic> map = event;
    switch (map['event']) {
      case 'AddTrack':
        String connectionId = map['connection_id'];
        int textureId = map['texture_id'];
        tracks.add(SoraVideoTrack(connectionId, textureId));
        if (onAddTrack != null) {
          onAddTrack!(connectionId, textureId);
        }
        break;
      case 'RemoveTrack':
        String connectionId = map['connection_id'];
        int textureId = map['texture_id'];
        tracks.removeWhere((element) => element.textureId == textureId);
        if (onRemoveTrack != null) {
          onRemoveTrack!(connectionId, textureId);
        }
        break;
    }
  }

  void _errorListener(Object obj) {
    if (obj is Exception) {
      throw obj;
    }
  }

  Future<void> connect() async {
    await _connector(this);
  }

  Future<void> dispose() async {
    _eventSubscription?.cancel();
    await _disposer(this);
  }
}
