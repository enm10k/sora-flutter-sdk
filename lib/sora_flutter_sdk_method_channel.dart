import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sora_flutter_sdk_platform_interface.dart';
import 'sora_client.dart';

/// An implementation of [SoraFlutterSdkPlatform] that uses method channels.
class MethodChannelSoraFlutterSdk extends SoraFlutterSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sora_flutter_sdk');

  @override
  Future<SoraClient> createSoraClient(SoraClientConfig config) async {
    final req = {
      'signaling_urls': config.signalingUrls,
      'channel_id': config.channelId,
      'role': config.role,
      'device_width': config.deviceWidth,
      'device_height': config.deviceHeight,
      'video_codec_type': config.videoCodecType,
    };
    final resp = await methodChannel.invokeMethod('createSoraClient', req);
    final client = SoraClient(resp, _connectSoraClient, _disposeSoraClient);
    return client;
  }

  Future<void> _connectSoraClient(SoraClient client) async {
    await methodChannel.invokeMethod('connectSoraClient', {
      'client_id': client.clientId,
    });
  }

  Future<void> _disposeSoraClient(SoraClient client) async {
    await methodChannel.invokeMethod('disposeSoraClient', {
      'client_id': client.clientId,
    });
  }
}
