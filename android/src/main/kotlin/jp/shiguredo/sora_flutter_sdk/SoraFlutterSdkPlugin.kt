package jp.shiguredo.sora_flutter_sdk

import java.util.HashMap
import java.lang.Integer

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import androidx.activity.result.ActivityResultCaller
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.NonNull
import androidx.core.content.ContextCompat

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener

/** SoraFlutterSdkPlugin */
class SoraFlutterSdkPlugin: FlutterPlugin, MethodCallHandler, RequestPermissionsResultListener, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var binding : FlutterPlugin.FlutterPluginBinding
  private var clientIdCounter : Int = 0
  private var clients : MutableMap<Int, Long> = mutableMapOf<Int, Long>()
  private var activity : Activity? = null
  private var nextSuccess : (() -> Unit)? = null
  private var nextError : ((String) -> Unit)? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    binding = flutterPluginBinding
    setApplicationContext(flutterPluginBinding.applicationContext)
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "sora_flutter_sdk")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "createSoraClient") {
      if (activity == null) {
        result.error("ACTIVITY-NOT-INITIALIZED", null, null)
        return
      }

      nextSuccess = fun() {
        var clientId = clientIdCounter
        clientIdCounter += 1
        var client = createSoraClient(binding, clientId, call, result)
        clients[clientId] = client
        nextSuccess = null
        nextError = null
      }
      nextError = fun(error: String) {
        result.error(error, null, null)
        nextSuccess = null
        nextError = null
      }

      if (ContextCompat.checkSelfPermission(activity!!, Manifest.permission.CAMERA) == PackageManager.PERMISSION_DENIED ||
          ContextCompat.checkSelfPermission(activity!!, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_DENIED) {
        activity!!.requestPermissions(arrayOf(Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO), 0)
      } else {
        nextSuccess!!()
      }
    } else if (call.method == "connectSoraClient") {
      var clientId = call.argument<Int>("client_id");
      var client = clients[clientId]
      connectSoraClient(client!!, call, result)
    } else if (call.method == "disposeSoraClient") {
      var clientId = call.argument<Int>("client_id");
      var client = clients[clientId]
      disposeSoraClient(client!!, call, result)
    } else if (call.method == "destroySoraClient") {
      var clientId = call.argument<Int>("client_id");
      var client = clients[clientId]
      clients.remove(clientId)
      destroySoraClient(client!!, call, result)
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
  external fun destroySoraClient(client: Long, call: MethodCall, result: Result)

  // ActivityAware
  override fun onDetachedFromActivity() {
      activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
      activity = binding.activity
      binding.addRequestPermissionsResultListener(this)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
      activity = binding.activity
      binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
      activity = null
  }

  // RequestPermissionsResultListener

  override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
    if (requestCode != 0) {
      return false
    }
    if (permissions.size == 2 &&
        permissions[0] == Manifest.permission.CAMERA && permissions[1] == Manifest.permission.RECORD_AUDIO &&
        grantResults[0] == PackageManager.PERMISSION_GRANTED && grantResults[1] == PackageManager.PERMISSION_GRANTED) {
      nextSuccess!!()
    } else {
      nextError!!("PERMISSION-ERROR")
    }
    return true
  }
}
