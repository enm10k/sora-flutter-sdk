// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SoraAudioCodecLyraParams _$SoraAudioCodecLyraParamsFromJson(
        Map<String, dynamic> json) =>
    SoraAudioCodecLyraParams(
      version:
          json['version'] as String? ?? SoraAudioCodecLyraParams.defaultVersion,
      bitRate: json['bitRate'] as int?,
    )..usedtx = json['usedtx'] as bool?;

Map<String, dynamic> _$SoraAudioCodecLyraParamsToJson(
    SoraAudioCodecLyraParams instance) {
  final val = <String, dynamic>{
    'version': instance.version,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('bitRate', instance.bitRate);
  writeNotNull('usedtx', instance.usedtx);
  return val;
}

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

Map<String, dynamic> _$SoraDataChannelToJson(SoraDataChannel instance) {
  final val = <String, dynamic>{
    'label': instance.label,
    'direction': _$SoraRoleEnumMap[instance.direction]!,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('ordered', instance.ordered);
  writeNotNull('maxPacketLifeTime', instance.maxPacketLifeTime);
  writeNotNull('maxRetransmits', instance.maxRetransmits);
  writeNotNull('protocol', instance.protocol);
  writeNotNull('compress', instance.compress);
  return val;
}

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
      ..audioStreamingLanguageCode =
          json['audioStreamingLanguageCode'] as String?
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
      ..videoDeviceName =
          SoraClientConfig._videoDeviceNameFrom(json['videoDeviceName'])
      ..videoDeviceWidth = json['videoDeviceWidth'] as int?
      ..videoDeviceHeight = json['videoDeviceHeight'] as int?
      ..videoDeviceFps = json['videoDeviceFps'] as int?
      ..noVideoDevice = json['noVideoDevice'] as bool;

Map<String, dynamic> _$SoraClientConfigToJson(SoraClientConfig instance) {
  final val = <String, dynamic>{
    'signalingUrls': instance.signalingUrls.map((e) => e.toString()).toList(),
    'channelId': instance.channelId,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('clientId', instance.clientId);
  writeNotNull('bundleId', instance.bundleId);
  val['soraClient'] = instance.soraClient;
  writeNotNull('insecure', instance.insecure);
  writeNotNull('video', instance.video);
  writeNotNull('audio', instance.audio);
  writeNotNull(
      'videoCodecType', _$SoraVideoCodecTypeEnumMap[instance.videoCodecType]);
  writeNotNull(
      'audioCodecType', _$SoraAudioCodecTypeEnumMap[instance.audioCodecType]);
  writeNotNull('videoBitRate', instance.videoBitRate);
  writeNotNull('audioBitRate', instance.audioBitRate);
  val['audioCodecLyraParams'] = instance.audioCodecLyraParams;
  writeNotNull(
      'audioStreamingLanguageCode', instance.audioStreamingLanguageCode);
  writeNotNull('metadata', instance.metadata);
  writeNotNull('signalingNotifyMetadata', instance.signalingNotifyMetadata);
  val['role'] = _$SoraRoleEnumMap[instance.role]!;
  writeNotNull('multistream', instance.multistream);
  writeNotNull('spotlight', instance.spotlight);
  writeNotNull('spotlightNumber', instance.spotlightNumber);
  writeNotNull('spotlightFocusRid',
      _$SoraSpotlightRidEnumMap[instance.spotlightFocusRid]);
  writeNotNull('spotlightUnfocusRid',
      _$SoraSpotlightRidEnumMap[instance.spotlightUnfocusRid]);
  writeNotNull('simulcast', instance.simulcast);
  writeNotNull(
      'simulcastRid', _$SoraSimulcastRidEnumMap[instance.simulcastRid]);
  writeNotNull('dataChannelSignaling', instance.dataChannelSignaling);
  writeNotNull(
      'dataChannelSignalingTimeout', instance.dataChannelSignalingTimeout);
  writeNotNull('ignoreDisconnectWebsocket', instance.ignoreDisconnectWebsocket);
  writeNotNull('disconnectWaitTimeout', instance.disconnectWaitTimeout);
  writeNotNull('dataChannels', instance.dataChannels);
  writeNotNull('clientCert', instance.clientCert);
  writeNotNull('clientKey', instance.clientKey);
  writeNotNull('websocketCloseTimeout', instance.websocketCloseTimeout);
  writeNotNull(
      'websocketConnectionTimeout', instance.websocketConnectionTimeout);
  writeNotNull('proxyUrl', instance.proxyUrl);
  writeNotNull('proxyUsername', instance.proxyUsername);
  writeNotNull('proxyPassword', instance.proxyPassword);
  writeNotNull('proxyAgent', instance.proxyAgent);
  writeNotNull('disableSignalingUrlRandomization',
      instance.disableSignalingUrlRandomization);
  writeNotNull('useAudioDeivce', instance.useAudioDeivce);
  writeNotNull('useHardwareEncoder', instance.useHardwareEncoder);
  writeNotNull('videoDeviceName',
      SoraClientConfig._videoDeviceNameOf(instance.videoDeviceName));
  writeNotNull('videoDeviceWidth', instance.videoDeviceWidth);
  writeNotNull('videoDeviceHeight', instance.videoDeviceHeight);
  writeNotNull('videoDeviceFps', instance.videoDeviceFps);
  val['noVideoDevice'] = instance.noVideoDevice;
  return val;
}

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
