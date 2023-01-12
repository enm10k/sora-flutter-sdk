import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sora_flutter_sdk/sora_flutter_sdk.dart';

import 'environment.dart';

void main() async {
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

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initAppState();
  }

  Future<void> initPlatformState() async {
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return;
    }
  }

  Future<void> initAppState() async {
    _capturers = await DeviceList.videoCapturers();
    setState(() {
      _connectDevice = _capturers.firstOrNull?.device;
    });
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
            child:
            SingleChildScrollView(
              child:
              Center(
                child: _buildRenderers(),
              ),
            ),
          ),
          SizedBox(
            height: screenSize.height * 0.2,
            child:
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDeviceList(),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await _connect();
                        },
                        child: const Text('接続する'),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await _disconnect();
                        },
                        child: const Text('切断する'),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        // iOS, Android のみサポート
                        // カメラの切替中はボタンを無効にする
                        onPressed: _canSwitchCamera,
                        child: Icon(Icons.flip_camera_ios),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRenderers() {
    print('build renderers');
    var renderers = List<SoraRenderer>.empty();
    if (_soraClient != null) {
      renderers = _soraClient!.tracks
          .map((track) => SoraRenderer(
        width: 320,
        height: 240,
        track: track,
      ))
          .toList();
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      children: renderers,
    );
  }

  Widget _buildDeviceList() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('カメラ: '),
          DropdownButton(
            value: _connectDevice,
            items: _capturers
                .map((DeviceName name) => DropdownMenuItem(
                      child: Text(name.device),
                      value: name.device,
                    ))
                .toList(),

            // カメラの切替中はボタンを無効にする
            onChanged:
                _soraClient?.switchingVideoDevice == true ? null : _setCamera,
          ),
        ],
      );

  Future<void> _connect() async {
    if (_isConnected) {
      return;
    }
    if (_soraClient != null) {
      dispose();
    }

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

  void Function()? get _canSwitchCamera {
    if ((Platform.isIOS || Platform.isAndroid) &&
        _soraClient != null &&
        _soraClient?.switchingVideoDevice != true) {
      return _switchCamera;
    } else {
      return null;
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
