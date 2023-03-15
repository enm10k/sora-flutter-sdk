import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart' as path;

import './sdk.dart';

class LyraConfig {
  LyraConfig({this.enabled = true, LyraPathProvider? pathProvider}) {
    this.pathProvider = pathProvider ?? LyraPathProviderImpl();
  }

  bool enabled;
  late LyraPathProvider pathProvider;
}

class Lyra {
  static LyraConfig? config;

  static const String _assetsDir = 'packages/sora_flutter_sdk/assets';
  static const String _modelDir = 'lyra/model_coeffs';
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
    if (config?.enabled == false) {
      return;
    }

    if (_initialized) {
      return;
    }

    final newConfig = config ?? LyraConfig();
    await _installModelFiles(newConfig);
    _initialized = true;
  }

  // モデルファイルのパスを指定する
  static Future<void> _installModelFiles(LyraConfig config) async {
    // アセットのパスを直接扱えないので、
    // ドキュメントディレクトリにファイルを作成してそのパスを使う
    final baseAppDocDir = await config.pathProvider.getModelDirectory();
    final appDocDir = '${baseAppDocDir.path}/$_sdkAppDocDir';
    final outDir = Directory('$appDocDir/$_modelDir');
    await outDir.create(recursive: true);
    for (final file in _modelFiles) {
      late String asset;
      asset = '$_assetsDir/$_modelDir/$file';
      final out = '${outDir.path}/$file';
      final outFile = File(out);
      final data = await rootBundle.load(asset);
      await outFile.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true);
    }

    await SoraFlutterSdk.setLyraModelPath(outDir.path);
  }
}

abstract class LyraPathProvider {
  Future<Directory> getModelDirectory() async {
    throw UnimplementedError();
  }
}

class LyraPathProviderImpl extends LyraPathProvider {
  @override
  Future<Directory> getModelDirectory() async {
    return await path.getApplicationDocumentsDirectory();
  }
}

class CustomLyraPathProvider extends LyraPathProvider {
  CustomLyraPathProvider({required this.modelDirectory});

  final Directory modelDirectory;

  @override
  Future<Directory> getModelDirectory() async {
    return modelDirectory;
  }
}
