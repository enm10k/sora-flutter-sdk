#include <jni.h>
#include <memory>
#include <string>
#include <thread>

#include <rtc_base/logging.h>
#include <sdk/android/native_api/jni/scoped_java_ref.h>
#include <sdk/android/native_api/jni/class_loader.h>

#include "sora_client.h"

struct SoraClientWrapper {
  std::shared_ptr<sora_flutter_sdk::SoraClient> p;
};

jobject g_ctx;

void SetAndroidApplicationContext(JNIEnv* env, jobject ctx) {
  if (g_ctx != nullptr) {
    env->DeleteGlobalRef(g_ctx);
    g_ctx = nullptr;
  }
  if (ctx != nullptr) {
    g_ctx = env->NewGlobalRef(ctx);
  }
}
void* GetAndroidApplicationContext(void* env) {
  return g_ctx;
}

extern "C" JNIEXPORT void JNICALL
Java_jp_shiguredo_sora_1flutter_1sdk_SoraFlutterSdkPlugin_setApplicationContext(JNIEnv* env,
                                         jobject /* this */,
                                         jobject ctx) {
  SetAndroidApplicationContext(env, ctx);
}
extern "C" JNIEXPORT jlong JNICALL
Java_jp_shiguredo_sora_1flutter_1sdk_SoraFlutterSdkPlugin_createSoraClient(JNIEnv* env,
                                         jobject /* this */, jobject binding, jint client_id, jobject call, jobject result) {
  std::string event_channel = "SoraFlutterSdk/SoraClient/Event/" + std::to_string(client_id);

  sora_flutter_sdk::SoraClientConfig config;
  // config.signaling_urls = call.argument<String[]>("signaling_urls");
  // config.channel_id = call.argument<String>("channel_id");
  // config.role = call.argument<String>("role");
  // config.device_width = call.argument<Integer>("device_width");
  // config.device_height = call.argument<Integer>("device_height");
  // config.video_codec_type = call.argument<String>("video_codec_type");
  webrtc::ScopedJavaLocalRef<jclass> callcls(env, env->GetObjectClass(call));
  jmethodID arg_id = env->GetMethodID(callcls.obj(), "argument", "(Ljava/lang/String;)Ljava/lang/Object;");
  {
    webrtc::ScopedJavaLocalRef<jobject> obj(env, env->CallObjectMethod(call, arg_id, env->NewStringUTF("signaling_urls")));
    webrtc::ScopedJavaLocalRef<jclass> listcls = webrtc::GetClass(env, "java/util/List");
    jmethodID get_id = env->GetMethodID(listcls.obj(), "get", "(I)Ljava/lang/Object;");
    jmethodID size_id = env->GetMethodID(listcls.obj(), "size", "()I");
    int length = env->CallIntMethod(obj.obj(), size_id);
    for (int i = 0; i < length; i++) {
      webrtc::ScopedJavaLocalRef<jstring> str(env, (jstring)env->CallObjectMethod(obj.obj(), get_id, i));
      const char* p = env->GetStringUTFChars(str.obj(), nullptr);
      config.signaling_urls.push_back(p);
      env->ReleaseStringUTFChars(str.obj(), p);
    }
  }
  {
    webrtc::ScopedJavaLocalRef<jstring> str(env, (jstring)env->CallObjectMethod(call, arg_id, env->NewStringUTF("channel_id")));
    const char* p = env->GetStringUTFChars(str.obj(), nullptr);
    config.channel_id = p;
    env->ReleaseStringUTFChars(str.obj(), p);
  }
  {
    webrtc::ScopedJavaLocalRef<jstring> str(env, (jstring)env->CallObjectMethod(call, arg_id, env->NewStringUTF("role")));
    const char* p = env->GetStringUTFChars(str.obj(), nullptr);
    config.role = p;
    env->ReleaseStringUTFChars(str.obj(), p);
  }
  {
    webrtc::ScopedJavaLocalRef<jobject> value(env, env->CallObjectMethod(call, arg_id, env->NewStringUTF("device_width")));
    webrtc::ScopedJavaLocalRef<jclass> intcls = webrtc::GetClass(env, "java/lang/Integer");
    jmethodID int_value_id = env->GetMethodID(intcls.obj(), "intValue", "()I");
    config.device_width = env->CallIntMethod(value.obj(), int_value_id);
  }
  {
    webrtc::ScopedJavaLocalRef<jobject> value(env, env->CallObjectMethod(call, arg_id, env->NewStringUTF("device_height")));
    webrtc::ScopedJavaLocalRef<jclass> intcls = webrtc::GetClass(env, "java/lang/Integer");
    jmethodID int_value_id = env->GetMethodID(intcls.obj(), "intValue", "()I");
    config.device_height = env->CallIntMethod(value.obj(), int_value_id);
  }
  {
    webrtc::ScopedJavaLocalRef<jstring> str(env, (jstring)env->CallObjectMethod(call, arg_id, env->NewStringUTF("video_codec_type")));
    const char* p = env->GetStringUTFChars(str.obj(), nullptr);
    config.video_codec_type = p;
    env->ReleaseStringUTFChars(str.obj(), p);
  }
  config.event_channel = event_channel;
  config.env = env;
  // config.binary_messenger = binding.getBinaryMessenger();
  // config.texture_registry = binding.getTextureRegistry();
  webrtc::ScopedJavaLocalRef<jclass> bindingcls(env, env->GetObjectClass(binding));
  jmethodID getbin = env->GetMethodID(bindingcls.obj(), "getBinaryMessenger", "()Lio/flutter/plugin/common/BinaryMessenger;");
  jmethodID gettex = env->GetMethodID(bindingcls.obj(), "getTextureRegistry", "()Lio/flutter/view/TextureRegistry;");
  webrtc::ScopedJavaLocalRef<jobject> messenger(env, env->CallObjectMethod(binding, getbin));
  webrtc::ScopedJavaLocalRef<jobject> texture_registry(env, env->CallObjectMethod(binding, gettex));
  config.messenger = messenger;
  config.texture_registry = texture_registry;
  auto client = new SoraClientWrapper();
  client->p = sora::CreateSoraClient<sora_flutter_sdk::SoraClient>(config);

  // m = new HashMap();
  // m.put("client_id", client_id);
  // m.put("event_channel", event_channel);
  // result.success(m);
  webrtc::ScopedJavaLocalRef<jclass> mapcls = webrtc::GetClass(env, "java/util/HashMap");
  jmethodID ctorid = env->GetMethodID(mapcls.obj(), "<init>", "()V");
  webrtc::ScopedJavaLocalRef<jobject> mapobj(env, env->NewObject(mapcls.obj(), ctorid));
  jmethodID putid = env->GetMethodID(mapcls.obj(), "put", "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;");
  webrtc::ScopedJavaLocalRef<jclass> intcls = webrtc::GetClass(env, "java/lang/Integer");
  jmethodID value_of_id = env->GetStaticMethodID(intcls.obj(), "valueOf", "(I)Ljava/lang/Integer;");
  webrtc::ScopedJavaLocalRef<jobject> client_id_obj(env, env->CallStaticObjectMethod(intcls.obj(), value_of_id, client_id));
  env->CallObjectMethod(mapobj.obj(), putid, env->NewStringUTF("client_id"), client_id_obj.obj());
  env->CallObjectMethod(mapobj.obj(), putid, env->NewStringUTF("event_channel"), env->NewStringUTF(event_channel.c_str()));
  webrtc::ScopedJavaLocalRef<jclass> resultcls(env, env->GetObjectClass(result));
  jmethodID successid = env->GetMethodID(resultcls.obj(), "success", "(Ljava/lang/Object;)V");
  env->CallVoidMethod(result, successid, mapobj.obj());

  return (jlong)client;
}

extern "C" JNIEXPORT void JNICALL
Java_jp_shiguredo_sora_1flutter_1sdk_SoraFlutterSdkPlugin_connectSoraClient(JNIEnv* env,
                                         jobject /* this */, jlong client, jobject call, jobject result) {
  reinterpret_cast<SoraClientWrapper*>(client)->p->Connect();

  // result.success(null);
  webrtc::ScopedJavaLocalRef<jclass> resultcls(env, env->GetObjectClass(result));
  jmethodID successid = env->GetMethodID(resultcls.obj(), "success", "(Ljava/lang/Object;)V");
  env->CallVoidMethod(result, successid, nullptr);
}

extern "C" JNIEXPORT void JNICALL
Java_jp_shiguredo_sora_1flutter_1sdk_SoraFlutterSdkPlugin_disposeSoraClient(JNIEnv* env,
                                         jobject /* this */, jlong client, jobject call, jobject result) {
  delete reinterpret_cast<SoraClientWrapper*>(client);

  // result.success(null);
  webrtc::ScopedJavaLocalRef<jclass> resultcls(env, env->GetObjectClass(result));
  jmethodID successid = env->GetMethodID(resultcls.obj(), "success", "(Ljava/lang/Object;)V");
  env->CallVoidMethod(result, successid, nullptr);
}