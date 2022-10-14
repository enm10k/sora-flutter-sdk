import 'dart:async';

import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

import 'video_track.dart';
import 'sdk.dart';

part 'client.g.dart';

enum SoraRole {
  sendonly,
  recvonly,
  sendrecv,
}

enum SoraVideoCodecType {
  @JsonValue("VP8")
  vp8,
  @JsonValue("VP9")
  vp9,
  @JsonValue("AV1")
  av1,
  @JsonValue("H264")
  h264,
  @JsonValue("H265")
  h265,
}

enum SoraAudioCodecType {
  @JsonValue("OPUS")
  opus,
}

extension SoraRoleRawValue on SoraRole {
  static final Map<SoraRole, String> _rawValues = {
    SoraRole.sendonly: "sendonly",
    SoraRole.recvonly: "recvonly",
    SoraRole.sendrecv: "sendrecv",
  };
  String get rawValue => _rawValues[this]!;
}

extension SoraVideoCodecTypeRawValue on SoraVideoCodecType {
  static final Map<SoraVideoCodecType, String> _rawValues = {
    SoraVideoCodecType.vp8: "VP8",
    SoraVideoCodecType.vp9: "VP9",
    SoraVideoCodecType.av1: "AV1",
    SoraVideoCodecType.h264: "H264",
    SoraVideoCodecType.h265: "H265",
  };
  String get rawValue => _rawValues[this]!;
}

@JsonSerializable()
class SoraDataChannel {
  SoraDataChannel({
    required this.label,
    required this.direction,
  });
  String label;
  SoraRole direction;
  bool? ordered;
  int? maxPacketLifeTime;
  int? maxRetransmits;
  String? protocol;
  bool? compress;

  factory SoraDataChannel.fromJson(Map<String, dynamic> json) =>
      _$SoraDataChannelFromJson(json);
  Map<String, dynamic> toJson() => _$SoraDataChannelToJson(this);
}

@JsonSerializable()
class SoraClientConfig {
  SoraClientConfig({
    required this.signalingUrls,
    required this.channelId,
    required this.role,
  });

  // SoraSignalingConfig の設定

  List<String> signalingUrls;
  String channelId;
  String? clientId;
  String? bundleId;

  String soraClient = "Sora Flutter SDK";

  bool? insecure;
  bool? video;
  bool? audio;
  SoraVideoCodecType? videoCodecType;
  SoraAudioCodecType? audioCodecType;
  int? videoBitRate;
  int? audioOpusParamsClockRate;
  Map<String, dynamic>? metadata;
  Map<String, dynamic>? signalingNotifyMetadata;
  SoraRole role;
  bool? multistream;
  bool? spotlight;
  int? spotlightNumber;
  String? spotlightFocusRid;
  String? spotlightUnfocusRid;
  bool? simulcast;
  String? simulcastRid;
  bool? dataChannelSignaling;
  int? dataChannelSignalingTimeout;
  bool? ignoreDisconnectWebsocket;
  int? disconnectWaitTimeout;
  List<SoraDataChannel>? dataChannels;

  String? clientCert;
  String? clientKey;

  int? websocketCloseTimeout;
  int? websocketConnectionTimeout;

  String? proxyUrl;
  String? proxyUsername;
  String? proxyPassword;
  String? proxyAgent;

  bool? disableSignalingUrlRandomization;

  // SoraClientConfig の設定

  bool? useAudioDeivce;
  bool? useHardwareEncoder;
  String? videoDeviceName;
  int? videoDeviceWidth;
  int? videoDeviceHeight;
  int? videoDeviceFps;

  factory SoraClientConfig.fromJson(Map<String, dynamic> json) =>
      _$SoraClientConfigFromJson(json);
  Map<String, dynamic> toJson() => _$SoraClientConfigToJson(this);
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
    final Map<String, dynamic> js = json.decode(map['json']);
    switch (js['event']) {
      case 'AddTrack':
        String connectionId = js['connection_id'];
        int textureId = js['texture_id'];
        final track = SoraVideoTrack(connectionId, textureId);
        tracks.add(track);
        if (onAddTrack != null) {
          onAddTrack!(track);
        }
        break;
      case 'RemoveTrack':
        String connectionId = js['connection_id'];
        int textureId = js['texture_id'];
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
