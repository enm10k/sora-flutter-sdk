import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sora_flutter_sdk/sora_flutter_sdk.dart';

import 'environment.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  SoraClient? _soraClient;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return;
    }

    final config = SoraClientConfig(
      signalingUrls:
          Environment.urlCandidates.map((e) => e.toString()).toList(),
      channelId: Environment.channelId,
      role: SoraRole.sendrecv,
    );
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
      ..onAddTrack = (SoraVideoTrack track) {
        setState(() {/* soraClient.tracks の数が変動したので描画し直す */});
      }
      ..onRemoveTrack = (SoraVideoTrack track) {
        setState(() {/* soraClient.tracks の数が変動したので描画し直す */});
      };
    await soraClient.connect();

    setState(() {
      _soraClient = soraClient;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: GridView.count(
            crossAxisCount: 2,
            children: _soraClient == null
                ? []
                : _soraClient!.tracks
                    .map(
                      (track) => SoraRenderer(
                        width: 320,
                        height: 240,
                        track: track,
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }
}
