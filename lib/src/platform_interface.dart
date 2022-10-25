import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel.dart';
import 'client.dart';

abstract class SoraFlutterSdkPlatform extends PlatformInterface {
  /// Constructs a SoraFlutterSdkPlatform.
  SoraFlutterSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static SoraFlutterSdkPlatform _instance = MethodChannelSoraFlutterSdk();

  /// The default instance of [SoraFlutterSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelSoraFlutterSdk].
  static SoraFlutterSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SoraFlutterSdkPlatform] when
  /// they register themselves.
  static set instance(SoraFlutterSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<SoraClient> createSoraClient(SoraClientConfig config) {
    throw UnimplementedError('createSoraClient() has not been implemented.');
  }
}
