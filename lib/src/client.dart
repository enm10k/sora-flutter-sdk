import 'dart:async';

import 'package:flutter/services.dart';
import 'package:collection/collection.dart';

import 'video_track.dart';
import 'sdk.dart';

enum SoraRole {
  sendonly,
  recvonly,
  sendrecv,
}

enum SoraVideoCodecType {
  vp8,
  vp9,
  av1,
  h264,
  h265,
}

extension SoraRoleRawValue on SoraRole {
  static final Map<SoraRole, String> _rawValues = {
    SoraRole.sendonly: "sendonly",
    SoraRole.recvonly: "recvonly",
    SoraRole.sendrecv: "sendrecv",
  };
  String get rawValues => _rawValues[this]!;
}

extension SoraVideoCodecTypeRawValue on SoraVideoCodecType {
  static final Map<SoraVideoCodecType, String> _rawValues = {
    SoraVideoCodecType.vp8: "VP8",
    SoraVideoCodecType.vp9: "VP9",
    SoraVideoCodecType.av1: "AV1",
    SoraVideoCodecType.h264: "H264",
    SoraVideoCodecType.h265: "H265",
  };
  String get rawValues => _rawValues[this]!;
}

class SoraClientConfig {
  SoraClientConfig({
    required this.signalingUrls,
    required this.channelId,
    required this.role,
  });

  List<String> signalingUrls = List<String>.empty(growable: true);
  String channelId;
  SoraRole role;
  int deviceWidth = 640;
  int deviceHeight = 480;
  SoraVideoCodecType? videoCodecType;
}

class SoraClient {
  static Future<SoraClient> create(SoraClientConfig config) async {
    return await SoraFlutterSdk.createSoraClient(config);
  }

  int clientId = 0;
  void Function(SoraVideoTrack)? onAddTrack;
  void Function(SoraVideoTrack)? onRemoveTrack;
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
        final track = SoraVideoTrack(connectionId, textureId);
        tracks.add(track);
        if (onAddTrack != null) {
          onAddTrack!(track);
        }
        break;
      case 'RemoveTrack':
        String connectionId = map['connection_id'];
        int textureId = map['texture_id'];
        SoraVideoTrack? track = tracks.firstWhereOrNull((element) =>
            element.connectionId == connectionId &&
            element.textureId == textureId);
        if (track != null) {
          tracks.remove(track);
          if (onRemoveTrack != null) {
            onRemoveTrack!(track);
          }
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
