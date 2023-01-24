import 'dart:async';

import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

import 'video_track.dart';
import 'lyra.dart';
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

/// 音声コーデックを表します。
enum SoraAudioCodecType {
  @JsonValue("OPUS")
  opus,

  @JsonValue("LYRA")
  lyra,
}

@JsonSerializable(includeIfNull: false)
class SoraAudioCodecLyraParams {
  SoraAudioCodecLyraParams({
    this.version,
    this.bitRate,
  });

  String? version;
  int? bitRate;

  factory SoraAudioCodecLyraParams.fromJson(Map<String, dynamic> json) =>
      _$SoraAudioCodecLyraParamsFromJson(json);
  Map<String, dynamic> toJson() => _$SoraAudioCodecLyraParamsToJson(this);
}

/// サイマルキャスト受信映像の rid を表します。
enum SoraSimulcastRid {
  /// r0
  @JsonValue("r0")
  r0,

  /// r1
  @JsonValue("r1")
  r1,

  /// r2
  @JsonValue("r2")
  r2,
}

/// スポットライト受信映像の rid を表します。
enum SoraSpotlightRid {
  /// none
  @JsonValue("none")
  none,

  /// r0
  @JsonValue("r0")
  r0,

  /// r1
  @JsonValue("r1")
  r1,

  /// r2
  @JsonValue("r2")
  r2,
}

@JsonSerializable()

/// DataChannel の設定です。
class SoraDataChannel {
  /// オブジェクトを生成します。
  SoraDataChannel({
    required this.label,
    required this.direction,
  });

  /// メッセージのラベル
  String label;

  /// メッセージの方向
  SoraRole direction;

  /// 順序保証
  bool? ordered;

  /// 最大再送時間
  int? maxPacketLifeTime;

  /// 最大再送回数
  int? maxRetransmits;

  /// プロトコル
  String? protocol;

  /// メッセージの圧縮の可否
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

  /// シグナリング URL のリスト
  List<Uri> signalingUrls;

  /// チャネル ID
  String channelId;

  /// クライアント ID
  String? clientId;

  /// バンドル ID
  String? bundleId;

  /// クライアント名
  String soraClient = "Sora Flutter SDK";

  /// 証明書の検証の可否。 true を指定すると検証を行いません。
  bool? insecure;

  /// 映像の可否
  bool? video;

  /// 音声の可否
  bool? audio;

  /// 映像コーデック
  SoraVideoCodecType? videoCodecType;

  /// 音声コーデック
  SoraAudioCodecType? audioCodecType;

  /// 映像ビットレート
  int? videoBitRate;

  /// 音声ビットレート
  int? audioBitRate;

  SoraAudioCodecLyraParams? audioCodecLyraParams;

  /// メタデータ
  dynamic metadata;

  /// type: notify で指定するメタデータ
  dynamic signalingNotifyMetadata;

  /// ロール
  SoraRole role;

  /// マルチストリームの可否
  bool? multistream;

  /// スポットライト機能の可否
  bool? spotlight;

  /// スポットライト数
  int? spotlightNumber;

  ///スポットライト機能の利用時にフォーカスしている映像の rid
  SoraSpotlightRid? spotlightFocusRid;

  ///スポットライト機能の利用時にフォーカスしない映像の rid
  SoraSpotlightRid? spotlightUnfocusRid;

  /// サイマルキャスト機能の可否
  bool? simulcast;

  /// サイマルキャスト機能の利用時受信する映像の rid
  SoraSimulcastRid? simulcastRid;

  /// DataChannel 経由のシグナリング
  bool? dataChannelSignaling;

  /// DataChannel 経由のシグナリング切断までのタイムアウト時間
  int? dataChannelSignalingTimeout;

  /// WebSocket が閉じても接続の切断とみなさずに無視する
  bool? ignoreDisconnectWebsocket;

  /// 切断までのタイムアウト時間
  int? disconnectWaitTimeout;

  /// DataChannel の設定
  List<SoraDataChannel>? dataChannels;

  /// クライアント証明書ファイル名
  ///
  /// このプロパティは Linux でのみ有効です。
  String? clientCert;

  /// クライアント証明書の秘密鍵ファイル名
  ///
  /// このプロパティは Linux でのみ有効です。
  String? clientKey;

  /// WebSocket が閉じるまでのタイムアウト時間
  int? websocketCloseTimeout;

  /// WebSocket 切断までのタイムアウト時間
  int? websocketConnectionTimeout;

  /// HTTP プロキシサーバーの URL
  String? proxyUrl;

  /// HTTP プロキシのユーザー名
  String? proxyUsername;

  /// HTTP プロキシのパスワード
  String? proxyPassword;

  /// HTTP プロキシのエージェント
  String? proxyAgent;

  /// シグナリング URL リストのランダムな並び替えの可否。
  /// `true` を指定すると、 [signalingUrls] の順に接続します。
  /// `false` を指定すると、ランダムな順序で接続します。
  bool? disableSignalingUrlRandomization;

  /// 音声デバイスの利用の可否
  bool? useAudioDeivce;

  /// ハードウェアエンコーダーの使用の可否
  bool? useHardwareEncoder;

  /// 利用する映像デバイス名
  String? videoDeviceName;

  /// 映像デバイスの横幅
  int? videoDeviceWidth;

  /// 映像デバイスの縦幅
  int? videoDeviceHeight;

  /// 映像デバイスのフレームレート
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
    // モデルファイルをドキュメントディレクトリに書き出す
    // 接続の直前に実行すると書き出しの終了が間に合わないため、
    // ここで早めに実行しておく
    await Lyra.initialize();
    return await SoraFlutterSdk.createSoraClient(config);
  }

  /// クライアント ID
  int clientId = 0;

  /// type: offer の受信時に呼ばれるコールバック
  void Function(String sdp)? onSetOffer;

  /// 切断時に呼ばれるコールバック
  void Function(String errorCode, String message)? onDisconnect;

  /// type: notify の受信時に呼ばれるコールバック
  void Function(String text)? onNotify;

  /// プッシュ通知の受信時に呼ばれるコールバック
  void Function(String text)? onPush;

  /// DataChannel メッセージの受信時に呼ばれるコールバック
  void Function(String label, Uint8List data)? onMessage;

  /// 映像トラックが追加されたときに呼ばれるコールバック
  void Function(SoraVideoTrack track)? onAddTrack;

  /// 映像トラックが本オブジェクトから除去されたときに呼ばれるコールバック
  void Function(SoraVideoTrack track)? onRemoveTrack;

  /// DataChannel の確立時に呼ばれるコールバック
  void Function(String label)? onDataChannel;

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
        _eventSubscription?.cancel();
        _destructor(this);
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
        List<dynamic> rawData = js['data'];
        final data = Uint8List.fromList(rawData.cast<int>());
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

  /// DataChannel を利用してメッセージを送信します。
  ///
  /// メッセージの送信に成功すると `true` を返します。
  Future<bool> sendDataChannel({
    required String label,
    required Uint8List data,
  }) async {
    return await SoraFlutterSdk.sendDataChannel(
      client: this,
      label: label,
      data: data,
    );
  }
}
