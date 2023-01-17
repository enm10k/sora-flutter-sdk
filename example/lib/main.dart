import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sora_flutter_sdk/sora_flutter_sdk.dart';

import 'environment.dart';

void main() async {
  SoraClientConfig.flutterVersion = Environment.flutterVersion;

  // 映像キャプチャーデバイス一覧
  WidgetsFlutterBinding.ensureInitialized();
  final devices = await DeviceList.videoCapturers();
  for (final device in devices) {
    print('device => ${device.device}, ${device.unique}');
  }
  final frontCamera = await DeviceList.frontCamera();
  final backCamera = await DeviceList.backCamera();
  print('front camera => $frontCamera');
  print('back camera => $backCamera');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  SoraClient? _soraClient;
  var _isConnected = false;
  List<DeviceName> _capturers = List<DeviceName>.empty();
  var _capturerNum = 0;

  // 接続時に使用するカメラ、または使用中のカメラ
  String? _connectDevice;
  var _video = true;
  var _audio = true;

  @override
  void initState() {
    super.initState();

    // initState は async にできないのでクロージャーで実行する
    () async {
      final capturers = await DeviceList.videoCapturers();
      setState(() {
        _capturers = capturers;
        _connectDevice = _capturers.firstOrNull?.device;
      });
    }();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(builder: _buildMain),
      ),
    );
  }

  Widget _buildMain(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Center(
      child: Column(
        children: [
          SizedBox(
            height: screenSize.height * 0.8,
            child: VideoGroupView(
              soraClient: _soraClient,
            ),
          ),
          SizedBox(
            height: screenSize.height * 0.2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DeviceListDropdownButton(
                    connectDevice: _connectDevice,
                    capturers: _capturers,
                    onChanged: (device) {
                      setState(() {
                        _connectDevice = device;
                        if (_soraClient?.switchingVideoDevice == true) {
                          _setCamera(device);
                        }
                      });
                    }),
                ConnectButtons(
                  onConnect: _connect,
                  onDisconnect: _disconnect,
                  canSwitchCamera: _canSwitchCamera,
                  onSwitchCamera: _switchCamera,
                ),
                const SizedBox(height: 8),
                MuteButtons(
                  enabled: _isConnected,
                  video: _video,
                  audio: _audio,
                  onChanged: (video, audio) {
                    setState(() {
                      _video = video;
                      _audio = audio;
                      _soraClient?.setVideoEnabled(_video);
                      _soraClient?.setVideoEnabled(_audio);
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connect() async {
    if (_isConnected) {
      return;
    }

    await _soraClient?.dispose();

    final config = SoraClientConfig(
      signalingUrls: Environment.urlCandidates,
      channelId: Environment.channelId,
      role: SoraRole.sendrecv,
    )
      ..metadata = Environment.signalingMetadata
      ..videoDeviceName = _connectDevice;

    final soraClient = await SoraClient.create(config)
      ..onDisconnect = (String errorCode, String message) {
        print("OnDisconnect: ec=$errorCode message=$message");
        _disconnect();
      }
      ..onSetOffer = (String offer) {
        print("OnSetOffer: $offer");
      }
      ..onNotify = (String text) {
        print("OnNotify: $text");
      }
      ..onSwitchTrack = (SoraVideoTrack track) {
        setState(() {/* カメラのトラックが交換されたので描画し直す */});
      }
      ..onAddTrack = (SoraVideoTrack track) {
        setState(() {/* soraClient.tracks の数が変動したので描画し直す */});
      }
      ..onRemoveTrack = (SoraVideoTrack track) {
        setState(() {/* soraClient.tracks の数が変動したので描画し直す */});
      };

    try {
      await soraClient.connect();

      setState(() {
        _soraClient = soraClient;
        _isConnected = true;
      });
    } on Exception catch (e) {
      print('connect failed => $e');
    }
  }

  Future<void> _disconnect() async {
    if (!_isConnected && _soraClient == null) {
      return;
    }
    print('disconnect');

    try {
      await _soraClient?.dispose();
    } on Exception catch (e) {
      print('dispose failed => $e');
    }

    setState(() {
      _soraClient = null;
      _isConnected = false;
      _video = true;
      _audio = true;
    });
  }

  Future<void> _setCamera(String? name) async {
    if (name == null) {
      return;
    }

    if (_soraClient != null) {
      // 接続済みであれば切り替える
      await _doSwitchCamera(name);
    } else {
      // 接続済みでなければ接続設定にする
      setState(() {
        _connectDevice = name;
      });
    }
  }

  bool get _canSwitchCamera {
    if ((Platform.isIOS || Platform.isAndroid) &&
        _soraClient != null &&
        _soraClient?.switchingVideoDevice != true) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> _switchCamera() async {
    if (_soraClient == null || _capturers.isEmpty) {
      return;
    }

    // 次に使用するカメラを決める
    var next = _capturerNum + 1;
    if (next >= _capturers.length) {
      next = 0;
    }
    final name = _capturers[next].device;
    final result = await _doSwitchCamera(name);
    if (result) {
      setState(() {
        _capturerNum = next;
      });
    }
  }

  Future<bool> _doSwitchCamera(String name) async {
    print('switch => ${name}');

    // カメラの切替中は切替ボタンを無効にしたいので、
    // switchVideoDevice を非同期で呼んでから画面を更新する。
    // 切替中は _soraClient.switchingVideoDevice が true になる
    final future = _soraClient!.switchVideoDevice(name: name);

    // _soraClient.switchingVideoDevice で有効・無効を判断するボタンは
    // この更新で無効になる
    setState(() {});

    // 切替終了まで待って残りの処理を行う
    final result = await future;
    setState(() {
      if (result) {
        print('switched device => $name, ${_soraClient!.switchingVideoDevice}');
        _connectDevice = name;
      } else {
        print('switch failed');
      }
    });
    return result;
  }
}

class DeviceListDropdownButton extends StatelessWidget {
  DeviceListDropdownButton({
    super.key,
    required this.connectDevice,
    required this.capturers,
    required this.onChanged,
  });

  final String? connectDevice;
  final List<DeviceName> capturers;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('カメラ: '),
          DropdownButton(
            value: connectDevice,
            items: capturers
                .map((DeviceName name) => DropdownMenuItem(
                      child: Text(name.device),
                      value: name.device,
                    ))
                .toList(),

            // カメラの切替中はボタンを無効にする
            onChanged: onChanged,
          ),
        ],
      );
}

class ConnectButtons extends StatelessWidget {
  ConnectButtons({
    super.key,
    required this.onConnect,
    required this.onDisconnect,
    required this.canSwitchCamera,
    required this.onSwitchCamera,
  });

  final void Function() onConnect;
  final void Function() onDisconnect;
  final bool canSwitchCamera;
  final void Function() onSwitchCamera;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: onConnect,
            child: const Text('接続する'),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: onDisconnect,
            child: const Text('切断する'),
          ),
          const SizedBox(width: 20),
          SwitchCameraButton(
            enabled: canSwitchCamera,
            onPressed: onSwitchCamera,
          ),
        ],
      );
}

class MuteButtons extends StatelessWidget {
  MuteButtons({
    super.key,
    required this.enabled,
    required this.video,
    required this.audio,
    required this.onChanged,
  });

  final bool enabled;
  final bool video;
  final bool audio;
  final void Function(bool video, bool audio) onChanged;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('ミュート:'),
          const SizedBox(width: 20),
          const Text('映像'),
          Switch(
            value: video,
            onChanged: enabled
                ? (flag) {
                    onChanged(flag, audio);
                  }
                : null,
          ),
          const SizedBox(width: 8),
          const Text('音声'),
          Switch(
            value: audio,
            onChanged: enabled
                ? (flag) {
                    onChanged(video, flag);
                  }
                : null,
          ),
        ],
      );
}

class SwitchCameraButton extends StatelessWidget {
  SwitchCameraButton({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: enabled ? onPressed : null,
        child: Icon(Icons.flip_camera_ios),
      );
}

class VideoGroupView extends StatelessWidget {
  VideoGroupView({
    super.key,
    required this.soraClient,
  });

  final SoraClient? soraClient;

  @override
  Widget build(BuildContext context) {
    var renderers = List<SoraRenderer>.empty();
    if (soraClient != null) {
      renderers = soraClient!.tracks
          .map((track) => SoraRenderer(
                width: 320,
                height: 240,
                track: track,
              ))
          .toList();
    }

    return SingleChildScrollView(
      child: Center(
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          children: renderers,
        ),
      ),
    );
  }
}
