import 'package:flutter/widgets.dart';
import 'video_track.dart';

class SoraRenderer extends StatelessWidget {
  const SoraRenderer({
    super.key,
    required this.width,
    required this.height,
    required this.track,
  });

  final int width;
  final int height;
  final SoraVideoTrack track;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width.toDouble(),
        height: height.toDouble(),
        child: Texture(textureId: track.textureId),
      );
}
