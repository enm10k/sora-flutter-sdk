import 'package:sora_flutter_sdk/sora_flutter_sdk.dart';

import 'environment.dart';

SoraClientConfig createClientConfig({
  required SoraRole role,
  List<Uri>? signalingUrls,
}) {
  SoraClientConfig.flutterVersion = Environment.flutterVersion;
  return SoraClientConfig(
      signalingUrls: signalingUrls ?? Environment.urlCandidates,
      channelId: Environment.channelId,
      role: role)
    ..metadata = Environment.signalingMetadata
    ..noVideoDevice = true;
}
