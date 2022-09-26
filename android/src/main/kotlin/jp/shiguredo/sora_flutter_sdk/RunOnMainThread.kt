package jp.shiguredo.sora_flutter_sdk

import java.lang.Runnable

import android.os.Handler
import android.os.Looper

public class RunOnMainThread(private val ptr: Long) {
  var handler = Handler(Looper.getMainLooper())
  fun run() {
    handler.post({
      nativeRun(ptr)
    })
  }
  external fun nativeRun(ptr: Long)
}