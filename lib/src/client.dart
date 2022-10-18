import 'dart:async';

import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

import 'video_track.dart';
import 'sdk.dart';

// 次のコマンドで生成できる (build_runner のインストールが必要)
// dart run build_runner build
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
  int? audioBitRate;
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
  void Function(String)? onSetOffer;
  void Function(String, String)? onDisconnect;
  void Function(String)? onNotify;
  void Function(String)? onPush;
  void Function(String, String)? onMessage;
  void Function(SoraVideoTrack)? onAddTrack;
  void Function(SoraVideoTrack)? onRemoveTrack;
  void Function(String)? onDataChannel;
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
      case 'SetOffer':
        String offer = js['offer'];
        if (onSetOffer != null) {
          onSetOffer!(offer);
        }
        break;
      case 'Disconnect':
        String errorCode = js['error_code'];
        String message = js['message'];
        if (onDisconnect != null) {
          onDisconnect!(errorCode, message);
        }
        break;
      case 'Notify':
        String text = js['text'];
        if (onNotify != null) {
          onNotify!(text);
        }
        break;
      case 'Push':
        String text = js['text'];
        if (onPush != null) {
          onPush!(text);
        }
        break;
      case 'Message':
        String label = js['label'];
        String data = js['data'];
        if (onMessage != null) {
          onMessage!(label, data);
        }
        break;
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
      case 'DataChannel':
        String label = js['label'];
        if (onDataChannel != null) {
          onDataChannel!(label);
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
