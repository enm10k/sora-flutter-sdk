#include <jni.h>
#include <memory>
#include <string>
#include <thread>

#include <rtc_base/logging.h>
#include <sdk/android/native_api/jni/scoped_java_ref.h>
#include <sdk/android/native_api/jni/class_loader.h>

#include "sora_client.h"
#include "client_reader.h"

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
  // var json = call.argument<String[]>("config");
  webrtc::ScopedJavaLocalRef<jclass> callcls(env, env->GetObjectClass(call));
  jmethodID arg_id = env->GetMethodID(callcls.obj(), "argument", "(Ljava/lang/String;)Ljava/lang/Object;");
  std::string json;
  {
    webrtc::ScopedJavaLocalRef<jstring> str(env, (jstring)env->CallObjectMethod(call, arg_id, env->NewStringUTF("config")));
    const char* p = env->GetStringUTFChars(str.obj(), nullptr);
    json = p;
    env->ReleaseStringUTFChars(str.obj(), p);
  }
  config = sora_flutter_sdk::JsonToClientConfig(json);
  config.signaling_config = sora_flutter_sdk::JsonToSignalingConfig(json);
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
