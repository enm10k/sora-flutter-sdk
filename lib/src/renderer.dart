import 'package:flutter/widgets.dart';
import 'video_track.dart';

/// 映像を描画するウィジェットです。
class SoraRenderer extends StatelessWidget {
  /// 本オブジェクトを生成します。
  ///
  /// 描画する映像の横幅・縦幅・映像トラックを指定します。
  const SoraRenderer({
    super.key,
    required this.width,
    required this.height,
    required this.track,
  });

  /// 映像の横幅
  final int width;

  /// 映像の縦幅
  final int height;

  /// 映像トラック
  final SoraVideoTrack track;

  /// 本ウィジェットを生成します。
  @override
  Widget build(BuildContext context) => SizedBox(
        width: width.toDouble(),
        height: height.toDouble(),
        child: Texture(textureId: track.textureId),
      );
}
