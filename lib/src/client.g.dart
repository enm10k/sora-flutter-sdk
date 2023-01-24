// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SoraAudioCodecLyraParams _$SoraAudioCodecLyraParamsFromJson(
        Map<String, dynamic> json) =>
    SoraAudioCodecLyraParams()
      ..version = json['version'] as String?
      ..bitRate = json['bitRate'] as int?;

Map<String, dynamic> _$SoraAudioCodecLyraParamsToJson(
        SoraAudioCodecLyraParams instance) =>
    <String, dynamic>{
      'version': instance.version,
      'bitRate': instance.bitRate,
    };

SoraDataChannel _$SoraDataChannelFromJson(Map<String, dynamic> json) =>
    SoraDataChannel(
      label: json['label'] as String,
      direction: $enumDecode(_$SoraRoleEnumMap, json['direction']),
    )
      ..ordered = json['ordered'] as bool?
      ..maxPacketLifeTime = json['maxPacketLifeTime'] as int?
      ..maxRetransmits = json['maxRetransmits'] as int?
      ..protocol = json['protocol'] as String?
      ..compress = json['compress'] as bool?;

Map<String, dynamic> _$SoraDataChannelToJson(SoraDataChannel instance) =>
    <String, dynamic>{
      'label': instance.label,
      'direction': _$SoraRoleEnumMap[instance.direction]!,
      'ordered': instance.ordered,
      'maxPacketLifeTime': instance.maxPacketLifeTime,
      'maxRetransmits': instance.maxRetransmits,
      'protocol': instance.protocol,
      'compress': instance.compress,
    };

const _$SoraRoleEnumMap = {
  SoraRole.sendonly: 'sendonly',
  SoraRole.recvonly: 'recvonly',
  SoraRole.sendrecv: 'sendrecv',
};

SoraClientConfig _$SoraClientConfigFromJson(Map<String, dynamic> json) =>
    SoraClientConfig(
      signalingUrls: (json['signalingUrls'] as List<dynamic>)
          .map((e) => Uri.parse(e as String))
          .toList(),
      channelId: json['channelId'] as String,
      role: $enumDecode(_$SoraRoleEnumMap, json['role']),
    )
      ..clientId = json['clientId'] as String?
      ..bundleId = json['bundleId'] as String?
      ..soraClient = json['soraClient'] as String
      ..insecure = json['insecure'] as bool?
      ..video = json['video'] as bool?
      ..audio = json['audio'] as bool?
      ..videoCodecType = $enumDecodeNullable(
          _$SoraVideoCodecTypeEnumMap, json['videoCodecType'])
      ..audioCodecType = $enumDecodeNullable(
          _$SoraAudioCodecTypeEnumMap, json['audioCodecType'])
      ..videoBitRate = json['videoBitRate'] as int?
      ..audioBitRate = json['audioBitRate'] as int?
      ..audioCodecLyraParams = SoraAudioCodecLyraParams.fromJson(
          json['audioCodecLyraParams'] as Map<String, dynamic>)
      ..metadata = json['metadata']
      ..signalingNotifyMetadata = json['signalingNotifyMetadata']
      ..multistream = json['multistream'] as bool?
      ..spotlight = json['spotlight'] as bool?
      ..spotlightNumber = json['spotlightNumber'] as int?
      ..spotlightFocusRid = $enumDecodeNullable(
          _$SoraSpotlightRidEnumMap, json['spotlightFocusRid'])
      ..spotlightUnfocusRid = $enumDecodeNullable(
          _$SoraSpotlightRidEnumMap, json['spotlightUnfocusRid'])
      ..simulcast = json['simulcast'] as bool?
      ..simulcastRid =
          $enumDecodeNullable(_$SoraSimulcastRidEnumMap, json['simulcastRid'])
      ..dataChannelSignaling = json['dataChannelSignaling'] as bool?
      ..dataChannelSignalingTimeout =
          json['dataChannelSignalingTimeout'] as int?
      ..ignoreDisconnectWebsocket = json['ignoreDisconnectWebsocket'] as bool?
      ..disconnectWaitTimeout = json['disconnectWaitTimeout'] as int?
      ..dataChannels = (json['dataChannels'] as List<dynamic>?)
          ?.map((e) => SoraDataChannel.fromJson(e as Map<String, dynamic>))
          .toList()
      ..clientCert = json['clientCert'] as String?
      ..clientKey = json['clientKey'] as String?
      ..websocketCloseTimeout = json['websocketCloseTimeout'] as int?
      ..websocketConnectionTimeout = json['websocketConnectionTimeout'] as int?
      ..proxyUrl = json['proxyUrl'] as String?
      ..proxyUsername = json['proxyUsername'] as String?
      ..proxyPassword = json['proxyPassword'] as String?
      ..proxyAgent = json['proxyAgent'] as String?
      ..disableSignalingUrlRandomization =
          json['disableSignalingUrlRandomization'] as bool?
      ..useAudioDeivce = json['useAudioDeivce'] as bool?
      ..useHardwareEncoder = json['useHardwareEncoder'] as bool?
      ..videoDeviceName = json['videoDeviceName'] as String?
      ..videoDeviceWidth = json['videoDeviceWidth'] as int?
      ..videoDeviceHeight = json['videoDeviceHeight'] as int?
      ..videoDeviceFps = json['videoDeviceFps'] as int?;

Map<String, dynamic> _$SoraClientConfigToJson(SoraClientConfig instance) =>
    <String, dynamic>{
      'signalingUrls': instance.signalingUrls.map((e) => e.toString()).toList(),
      'channelId': instance.channelId,
      'clientId': instance.clientId,
      'bundleId': instance.bundleId,
      'soraClient': instance.soraClient,
      'insecure': instance.insecure,
      'video': instance.video,
      'audio': instance.audio,
      'videoCodecType': _$SoraVideoCodecTypeEnumMap[instance.videoCodecType],
      'audioCodecType': _$SoraAudioCodecTypeEnumMap[instance.audioCodecType],
      'videoBitRate': instance.videoBitRate,
      'audioBitRate': instance.audioBitRate,
      'audioCodecLyraParams': instance.audioCodecLyraParams,
      'metadata': instance.metadata,
      'signalingNotifyMetadata': instance.signalingNotifyMetadata,
      'role': _$SoraRoleEnumMap[instance.role]!,
      'multistream': instance.multistream,
      'spotlight': instance.spotlight,
      'spotlightNumber': instance.spotlightNumber,
      'spotlightFocusRid':
          _$SoraSpotlightRidEnumMap[instance.spotlightFocusRid],
      'spotlightUnfocusRid':
          _$SoraSpotlightRidEnumMap[instance.spotlightUnfocusRid],
      'simulcast': instance.simulcast,
      'simulcastRid': _$SoraSimulcastRidEnumMap[instance.simulcastRid],
      'dataChannelSignaling': instance.dataChannelSignaling,
      'dataChannelSignalingTimeout': instance.dataChannelSignalingTimeout,
      'ignoreDisconnectWebsocket': instance.ignoreDisconnectWebsocket,
      'disconnectWaitTimeout': instance.disconnectWaitTimeout,
      'dataChannels': instance.dataChannels,
      'clientCert': instance.clientCert,
      'clientKey': instance.clientKey,
      'websocketCloseTimeout': instance.websocketCloseTimeout,
      'websocketConnectionTimeout': instance.websocketConnectionTimeout,
      'proxyUrl': instance.proxyUrl,
      'proxyUsername': instance.proxyUsername,
      'proxyPassword': instance.proxyPassword,
      'proxyAgent': instance.proxyAgent,
      'disableSignalingUrlRandomization':
          instance.disableSignalingUrlRandomization,
      'useAudioDeivce': instance.useAudioDeivce,
      'useHardwareEncoder': instance.useHardwareEncoder,
      'videoDeviceName': instance.videoDeviceName,
      'videoDeviceWidth': instance.videoDeviceWidth,
      'videoDeviceHeight': instance.videoDeviceHeight,
      'videoDeviceFps': instance.videoDeviceFps,
    };

const _$SoraVideoCodecTypeEnumMap = {
  SoraVideoCodecType.vp8: 'VP8',
  SoraVideoCodecType.vp9: 'VP9',
  SoraVideoCodecType.av1: 'AV1',
  SoraVideoCodecType.h264: 'H264',
  SoraVideoCodecType.h265: 'H265',
};

const _$SoraAudioCodecTypeEnumMap = {
  SoraAudioCodecType.opus: 'OPUS',
  SoraAudioCodecType.lyra: 'LYRA',
};

const _$SoraSpotlightRidEnumMap = {
  SoraSpotlightRid.none: 'none',
  SoraSpotlightRid.r0: 'r0',
  SoraSpotlightRid.r1: 'r1',
  SoraSpotlightRid.r2: 'r2',
};

const _$SoraSimulcastRidEnumMap = {
  SoraSimulcastRid.r0: 'r0',
  SoraSimulcastRid.r1: 'r1',
  SoraSimulcastRid.r2: 'r2',
};
