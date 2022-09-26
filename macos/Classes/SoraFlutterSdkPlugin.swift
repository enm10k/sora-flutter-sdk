import Cocoa
import FlutterMacOS

public class SoraFlutterSdkPlugin: NSObject, FlutterPlugin {

    private var messageHandler: SoraFlutterMessageHandler?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "sora_flutter_sdk", binaryMessenger: registrar.messenger)
    let instance = SoraFlutterSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

      instance.messageHandler = SoraFlutterMessageHandler(messenger: registrar.messenger, textureRegistry: registrar.textures)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      messageHandler?.handle(call, result: result)
  }
}
