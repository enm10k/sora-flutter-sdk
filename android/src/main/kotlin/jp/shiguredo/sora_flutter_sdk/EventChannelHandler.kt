package jp.shiguredo.sora_flutter_sdk

import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.EventChannel.EventSink

class EventChannelHandler(private var ptr: Long): StreamHandler {
  override fun onListen(arguments: Any?, events: EventSink) {
    nativeOnListen(ptr, arguments, events)
  }
  override fun onCancel(arguments: Any?) {
    nativeOnCancel(ptr, arguments)
  }
  external fun nativeOnListen(ptr: Long, arguments: Any?, events: EventSink)
  external fun nativeOnCancel(ptr: Long, arguments: Any?)
}
