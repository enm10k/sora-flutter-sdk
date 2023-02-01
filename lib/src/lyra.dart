import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import './sdk.dart';

class Lyra {
  static const String _assetsDir = 'packages/sora_flutter_sdk/assets';
  static const String _modelDir = 'lyra/model_coeffs';
  static const String _linuxModelDir = 'linux/_install/lyra/share/model_coeffs';
  static const String _sdkAppDocDir = 'sora_flutter_sdk';

  static const List<String> _modelFiles = [
    'lyra_config.binarypb',
    'lyragan.tflite',
    'quantizer.tflite',
    'soundstream_encoder.tflite',
    'test_playback.wav',
  ];

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _installModelFiles();
    _initialized = true;
  }

  // モデルファイルのパスを指定する
  static Future<void> _installModelFiles() async {
    // アセットのパスを直接扱えないので、
    // ドキュメントディレクトリにファイルを作成してそのパスを使う
    final baseAppDocDir = await getApplicationDocumentsDirectory();
    final appDocDir = '${baseAppDocDir.path}/$_sdkAppDocDir';
    final outDir = Directory('$appDocDir/$_modelDir');
    await outDir.create(recursive: true);
    for (final file in _modelFiles) {
      late String asset;
      if (Platform.isLinux) {
        asset = '$_linuxModelDir/$file';
      }else {
        asset = '$_assetsDir/$_modelDir/$file';
      }
      final out = '${outDir.path}/$file';
      final outFile = File(out);
      if (!(await outFile.exists())) {
        final data = await rootBundle.load(asset);
        await outFile.writeAsBytes(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
            flush: true);
      }
    }

    await SoraFlutterSdk.setLyraModelPath(outDir.path);
  }
}
