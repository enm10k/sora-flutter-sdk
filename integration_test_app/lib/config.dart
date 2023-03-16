import 'package:sora_flutter_sdk/sora_flutter_sdk.dart';

import 'environment.dart';

SoraClientConfig createClientConfig({required SoraRole role}) {
  SoraClientConfig.flutterVersion = Environment.flutterVersion;
  return SoraClientConfig(
      signalingUrls: Environment.urlCandidates,
      channelId: Environment.channelId,
      role: role)
    ..metadata = Environment.signalingMetadata;
}
