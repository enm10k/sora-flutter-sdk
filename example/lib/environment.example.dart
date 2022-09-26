// 接続設定

// 以下の lint ルールを無視する
// ignore_for_file: avoid_classes_with_only_static_members
// ignore_for_file: unnecessary_nullable_for_final_variable_declarations

class Environment {
  static final List<Uri> urlCandidates = [
    Uri.parse('wss://sora.example.com/signaling')
  ];

  static const String channelId = 'sora';

  static const Map<String, dynamic>? signalingMetadata = null;
}
