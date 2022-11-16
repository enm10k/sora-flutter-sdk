import 'dart:async';

import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

import 'video_track.dart';
import 'sdk.dart';

// 次のコマンドで生成できる (build_runner のインストールが必要)
// flutter pub run build_runner build
part 'client.g.dart';

/// 接続時のロールを表します。
enum SoraRole {
  /// 送信のみ
  sendonly,

  /// 受信のみ
  recvonly,

  /// 送受信
  sendrecv,
}

/// 映像コーデックを表します。
enum SoraVideoCodecType {
  /// VP8
  @JsonValue("VP8")
  vp8,
  /// VP9
  @JsonValue("VP9")
  vp9,
  /// AV1
  @JsonValue("AV1")
  av1,
  /// H.264
  @JsonValue("H264")
  h264,
  /// H.265
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

/// 接続設定です。
@JsonSerializable()
class SoraClientConfig {
  /// 本オブジェクトを生成します。
  SoraClientConfig({
    required this.signalingUrls,
    required this.channelId,
    required this.role,
  });

  // SoraSignalingConfig の設定

  /// シグナリング URL のリスト
  List<Uri> signalingUrls;

  /// チャネル ID
  String channelId;
  String? clientId;
  String? bundleId;

  String soraClient = "Sora Flutter SDK";

  bool? insecure;
  bool? video;
  bool? audio;
  /// 映像コーデック
  SoraVideoCodecType? videoCodecType;
  SoraAudioCodecType? audioCodecType;
  int? videoBitRate;
  int? audioBitRate;
  dynamic metadata;
  dynamic signalingNotifyMetadata;
  /// ロール
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
  /// 送信する映像の横幅
  int? videoDeviceWidth;
  /// 送信する映像の縦幅
  int? videoDeviceHeight;
  int? videoDeviceFps;

  factory SoraClientConfig.fromJson(Map<String, dynamic> json) =>
      _$SoraClientConfigFromJson(json);
  Map<String, dynamic> toJson() => _$SoraClientConfigToJson(this);
}

/// Sora に接続します。
///
/// 本オブジェクトの使用後は必ず [dispose] を呼んで終了処理を行ってください。
class SoraClient {
  /// [config] を接続設定として本オブジェクトを生成します。
  ///
  /// 生成した時点では Sora に接続されていません。
  /// 接続するには [connect] を呼んでください。
  static Future<SoraClient> create(SoraClientConfig config) async {
    return await SoraFlutterSdk.createSoraClient(config);
  }

  /// クライアント ID
  int clientId = 0;
  void Function(String)? onSetOffer;
  void Function(String, String)? onDisconnect;
  void Function(String)? onNotify;
  void Function(String)? onPush;
  void Function(String, String)? onMessage;
  /// 映像トラックが追加されたときに呼ばれるコールバック
  void Function(SoraVideoTrack)? onAddTrack;
  /// 映像トラックが本オブジェクトから除去されたときに呼ばれるコールバック
  void Function(SoraVideoTrack)? onRemoveTrack;
  void Function(String)? onDataChannel;
  /// 映像トラックのリスト
  List<SoraVideoTrack> tracks = List<SoraVideoTrack>.empty(growable: true);

  String _eventChannel = "";
  final Future<void> Function(SoraClient) _connector;
  final Future<void> Function(SoraClient) _disposer;
  final Future<void> Function(SoraClient) _destructor;
  StreamSubscription<dynamic>? _eventSubscription;

  /// 本コンストラクタは内部実装で使われるので使わないでください。
  /// 本オブジェクトを生成するには [create] を使ってください。
  SoraClient(dynamic resp, this._connector, this._disposer, this._destructor) {
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
        _destructor(this);
        _eventSubscription?.cancel();
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

  /// Sora に接続します。
  ///
  /// 本オブジェクトの使用後は必ず [dispose] を呼んで終了処理を行ってください。
  Future<void> connect() async {
    await _connector(this);
  }

  /// 終了処理を行います。
  Future<void> dispose() async {
    await _disposer(this);
  }

  Future<bool> sendDataChannel({
    required String label,
    required Object data,
  }) async {
    if (data is ByteData) {
      data = data.buffer.asUint8List();
    }
    final buf = StringBuffer();
    if (data is String) {
      buf.write(data);
    } else if (data is Uint8List) {
      for (int n in data) {
        buf.writeCharCode(n);
      }
    } else {
      throw ArgumentError('data must be String, ByteData or Uint8List');
    }
    return await SoraFlutterSdk.sendDataChannel(
      client: this,
      label: label,
      data: buf.toString(),
    );
  }
}
