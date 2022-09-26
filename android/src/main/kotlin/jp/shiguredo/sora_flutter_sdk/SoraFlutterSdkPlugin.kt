package jp.shiguredo.sora_flutter_sdk

import java.util.HashMap
import java.lang.Integer

import androidx.annotation.NonNull
import android.content.Context

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** SoraFlutterSdkPlugin */
class SoraFlutterSdkPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var binding : FlutterPlugin.FlutterPluginBinding
  private var clientIdCounter : Int = 0
  private var clients : MutableMap<Int, Long> = mutableMapOf<Int, Long>()

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    binding = flutterPluginBinding
    setApplicationContext(flutterPluginBinding.applicationContext)
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "sora_flutter_sdk")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "createSoraClient") {
      var clientId = clientIdCounter
      clientIdCounter += 1
      var client = createSoraClient(binding, clientId, call, result)
      clients[clientId] = client
    } else if (call.method == "connectSoraClient") {
      var clientId = call.argument<Int>("client_id");
      var client = clients[clientId]
      connectSoraClient(client!!, call, result)
    } else if (call.method == "disposeSoraClient") {
      var clientId = call.argument<Int>("client_id");
      var client = clients[clientId]
      disposeSoraClient(client!!, call, result)
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  companion object {
      init {
          System.loadLibrary("sora_flutter_sdk")
      }
  }

  external fun setApplicationContext(context: Context)
  external fun createSoraClient(binding: FlutterPlugin.FlutterPluginBinding, clientId: Int, call: MethodCall, result: Result): Long
  external fun connectSoraClient(client: Long, call: MethodCall, result: Result)
  external fun disposeSoraClient(client: Long, call: MethodCall, result: Result)
}
