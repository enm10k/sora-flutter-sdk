import 'dart:async';
import 'dart:typed_data';

import 'package:sora_flutter_sdk/sora_flutter_sdk.dart';

enum SoraClientEventType {
  onSetOffer,
  onDisconnect,
  onNotify,
  onPush,
  onMessage,
  onDataChannel,
  onAddTrack,
  onRemoveTrack,
  onSwitchTrack,
}

class SoraClientEvent {
  SoraClientEvent(
    this.type, {
    this.sdp,
    this.errorCode,
    this.errorMessage,
    this.text,
    this.label,
    this.data,
    this.track,
  });

  final SoraClientEventType type;

  final String? sdp;
  final String? errorCode;
  final String? errorMessage;
  final String? text;
  final String? label;
  final Uint8List? data;
  final SoraVideoTrack? track;

  factory SoraClientEvent.onSetOffer(String sdp) {
    return SoraClientEvent(SoraClientEventType.onSetOffer, sdp: sdp);
  }

  factory SoraClientEvent.onDisconnect(String errorCode, String message) {
    return SoraClientEvent(SoraClientEventType.onDisconnect,
        errorCode: errorCode, errorMessage: message);
  }

  factory SoraClientEvent.onNotify(String text) {
    return SoraClientEvent(SoraClientEventType.onNotify, text: text);
  }

  factory SoraClientEvent.onPush(String text) {
    return SoraClientEvent(SoraClientEventType.onPush, text: text);
  }

  factory SoraClientEvent.onMessage(String label, Uint8List data) {
    return SoraClientEvent(SoraClientEventType.onMessage,
        label: label, data: data);
  }

  factory SoraClientEvent.onDatachannel(String label) {
    return SoraClientEvent(SoraClientEventType.onDataChannel, label: label);
  }

  factory SoraClientEvent.onAddTrack(SoraVideoTrack track) {
    return SoraClientEvent(SoraClientEventType.onAddTrack, track: track);
  }

  factory SoraClientEvent.onRemoveTrack(SoraVideoTrack track) {
    return SoraClientEvent(SoraClientEventType.onRemoveTrack, track: track);
  }

  factory SoraClientEvent.onSwitchTrack(SoraVideoTrack track) {
    return SoraClientEvent(SoraClientEventType.onSwitchTrack, track: track);
  }
}
