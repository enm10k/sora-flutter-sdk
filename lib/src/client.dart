import 'dart:async';

import 'package:flutter/services.dart';
import 'package:collection/collection.dart';

import 'video_track.dart';
import 'sdk.dart';

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
  vp8,

  /// VP9
  vp9,

  /// AV1
  av1,

  /// H.264
  h264,

  /// H.265
  h265,
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

/// 接続設定です。
class SoraClientConfig {
  /// 本オブジェクトを生成します。
  SoraClientConfig({
    required this.signalingUrls,
    required this.channelId,
    required this.role,
  });

  /// シグナリング URL のリスト
  List<String> signalingUrls = List<String>.empty(growable: true);

  /// チャネル ID
  String channelId;

  /// ロール
  SoraRole role;

  /// 送信する映像の横幅
  int deviceWidth = 640;

  /// 送信する映像の縦幅
  int deviceHeight = 480;

  /// 映像コーデック
  SoraVideoCodecType? videoCodecType;
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

  /// 映像トラックが追加されたときに呼ばれるコールバック
  void Function(SoraVideoTrack)? onAddTrack;

  /// 映像トラックが本オブジェクトから除去されたときに呼ばれるコールバック
  void Function(SoraVideoTrack)? onRemoveTrack;

  /// 映像トラックのリスト
  List<SoraVideoTrack> tracks = List<SoraVideoTrack>.empty(growable: true);

  String _eventChannel = "";
  final Future<void> Function(SoraClient) _connector;
  final Future<void> Function(SoraClient) _disposer;
  StreamSubscription<dynamic>? _eventSubscription;

  /// 本コンストラクタは内部実装で使われるので使わないでください。
  /// 本オブジェクトを生成するには [create] を使ってください。
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

  /// Sora に接続します。
  ///
  /// 本オブジェクトの使用後は必ず [dispose] を呼んで終了処理を行ってください。
  Future<void> connect() async {
    await _connector(this);
  }

  /// 終了処理を行います。
  Future<void> dispose() async {
    _eventSubscription?.cancel();
    await _disposer(this);
  }
}
