/// 映像トラックです。
class SoraVideoTrack {
  /// コネクション ID
  final String connectionId;

  /// テクスチャ ID
  final int textureId;

  /// 使用しないでください。内部実装で使われます。
  SoraVideoTrack(this.connectionId, this.textureId);
}
