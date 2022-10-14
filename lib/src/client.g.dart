// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
          .map((e) => e as String)
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
      ..audioOpusParamsClockRate = json['audioOpusParamsClockRate'] as int?
      ..metadata = json['metadata'] as Map<String, dynamic>?
      ..signalingNotifyMetadata =
          json['signalingNotifyMetadata'] as Map<String, dynamic>?
      ..multistream = json['multistream'] as bool?
      ..spotlight = json['spotlight'] as bool?
      ..spotlightNumber = json['spotlightNumber'] as int?
      ..spotlightFocusRid = json['spotlightFocusRid'] as String?
      ..spotlightUnfocusRid = json['spotlightUnfocusRid'] as String?
      ..simulcast = json['simulcast'] as bool?
      ..simulcastRid = json['simulcastRid'] as String?
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
      ..videoDeviceHeight = json['videoDeviceHeight'] as int?;

Map<String, dynamic> _$SoraClientConfigToJson(SoraClientConfig instance) =>
    <String, dynamic>{
      'signalingUrls': instance.signalingUrls,
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
      'audioOpusParamsClockRate': instance.audioOpusParamsClockRate,
      'metadata': instance.metadata,
      'signalingNotifyMetadata': instance.signalingNotifyMetadata,
      'role': _$SoraRoleEnumMap[instance.role]!,
      'multistream': instance.multistream,
      'spotlight': instance.spotlight,
      'spotlightNumber': instance.spotlightNumber,
      'spotlightFocusRid': instance.spotlightFocusRid,
      'spotlightUnfocusRid': instance.spotlightUnfocusRid,
      'simulcast': instance.simulcast,
      'simulcastRid': instance.simulcastRid,
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
};
