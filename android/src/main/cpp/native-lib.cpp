#include <jni.h>
#include <memory>
#include <string>
#include <thread>

#include <rtc_base/logging.h>
#include <sdk/android/native_api/jni/scoped_java_ref.h>
#include <sdk/android/native_api/jni/class_loader.h>

#include "sora_client.h"
#include "config_reader.h"
#include "device_list.h"

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
  config.messenger = env->CallObjectMethod(binding, getbin);
  config.texture_registry = env->CallObjectMethod(binding, gettex);
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
  reinterpret_cast<SoraClientWrapper*>(client)->p->Disconnect();

  // result.success(null);
  webrtc::ScopedJavaLocalRef<jclass> resultcls(env, env->GetObjectClass(result));
  jmethodID successid = env->GetMethodID(resultcls.obj(), "success", "(Ljava/lang/Object;)V");
  env->CallVoidMethod(result, successid, nullptr);
}

void RunOnMainThread(JNIEnv* env, std::function<void (JNIEnv*)> f);

extern "C" JNIEXPORT void JNICALL
Java_jp_shiguredo_sora_1flutter_1sdk_SoraFlutterSdkPlugin_destroySoraClient(JNIEnv* env,
                                         jobject /* this */, jlong client, jobject call, jobject result) {
  auto wrapper = reinterpret_cast<SoraClientWrapper*>(client);
  wrapper->p->Destroy();
  delete wrapper;

  // result.success(null);
  webrtc::ScopedJavaLocalRef<jclass> resultcls(env, env->GetObjectClass(result));
  jmethodID successid = env->GetMethodID(resultcls.obj(), "success", "(Ljava/lang/Object;)V");
  env->CallVoidMethod(result, successid, nullptr);
}

extern "C" JNIEXPORT void JNICALL
Java_jp_shiguredo_sora_1flutter_1sdk_SoraFlutterSdkPlugin_sendDataChannel(JNIEnv* env,
                                         jobject /* this */, jlong client, jstring label, jbyteArray data, jobject call, jobject result) {
  std::string c_label = env->GetStringUTFChars(label, 0);

  jsize data_len = env->GetArrayLength(data);
  jbyte *data_bytes = env->GetByteArrayElements(data, JNI_FALSE);
  std::string c_data;
  for (int i = 0; i < data_len; i++) {
    c_data.push_back(data_bytes[i]);
  }

  bool resp = reinterpret_cast<SoraClientWrapper*>(client)->p->SendDataChannel(c_label, c_data);

  // b = Boolean(resp);
  // result.success(b);
  webrtc::ScopedJavaLocalRef<jclass> boolcls = webrtc::GetClass(env, "java/lang/Boolean");
  jmethodID ctorid = env->GetMethodID(boolcls.obj(), "<init>", "(Z)V");
  webrtc::ScopedJavaLocalRef<jobject> boolobj(env, env->NewObject(boolcls.obj(), ctorid, resp));
  webrtc::ScopedJavaLocalRef<jclass> resultcls(env, env->GetObjectClass(result));
  jmethodID successid = env->GetMethodID(resultcls.obj(), "success", "(Ljava/lang/Object;)V");
  env->CallVoidMethod(result, successid, boolobj.obj());
}

extern "C" JNIEXPORT void JNICALL
Java_jp_shiguredo_sora_1flutter_1sdk_SoraFlutterSdkPlugin_enumVideoCapturers(JNIEnv* env,
                                         jobject /* this */, jobject call, jobject result) {
  // alist = ArrayList();
  webrtc::ScopedJavaLocalRef<jclass> alistcls = webrtc::GetClass(env, "java/lang/ArrayList");
  jmethodID alist_ctorid = env->GetMethodID(alistcls.obj(), "<init>", "()V");
  webrtc::ScopedJavaLocalRef<jobject> alistobj(env, env->NewObject(alistcls.obj(), alist_ctorid));
  jmethodID alist_addid = env->GetMethodID(alistcls.obj(), "add", "(Ljava/lang/Object;)Z");

  webrtc::ScopedJavaLocalRef<jclass> mapcls = webrtc::GetClass(env, "java/util/HashMap");
  jmethodID map_ctorid = env->GetMethodID(mapcls.obj(), "<init>", "()V");
  jmethodID map_putid = env->GetMethodID(mapcls.obj(), "put", "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;");
  sora_flutter_sdk::DeviceList::EnumVideoCapturer(
    [alistobj, alist_addid, mapcls, map_ctorid, map_putid, env]
    (std::string device_name, std::string unique_name) {
     // m = new HashMap();
     // m.put("device", device_name);
     // m.put("unique", unique_name);
     // alist.add(m);
    webrtc::ScopedJavaLocalRef<jobject> mapobj(env, env->NewObject(mapcls.obj(), map_ctorid));
    env->CallObjectMethod(mapobj.obj(), map_putid, env->NewStringUTF("device"), env->NewStringUTF(device_name.c_str()));
    env->CallObjectMethod(mapobj.obj(), map_putid, env->NewStringUTF("unique"), env->NewStringUTF(unique_name.c_str()));
    env->CallObjectMethod(alistobj.obj(), alist_addid, mapobj.obj());
  });

  // result.success(alist);
  webrtc::ScopedJavaLocalRef<jclass> resultcls(env, env->GetObjectClass(result));
  jmethodID successid = env->GetMethodID(resultcls.obj(), "success", "(Ljava/lang/Object;)V");
  env->CallVoidMethod(result, successid, alistobj.obj());
}

extern "C" JNIEXPORT void JNICALL
Java_jp_shiguredo_sora_1flutter_1sdk_SoraFlutterSdkPlugin_switchVideoDevice(JNIEnv* env,
                                         jobject /* this */, jobject client, jobject call, jobject result) {
   reinterpret_cast<SoraClientWrapper*>(client)->p->Connect();

  sora::CameraDeviceCapturerConfig config;
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
  config = sora_flutter_sdk::JsonToCameraDeviceCapturerConfig(json);
  reinterpret_cast<SoraClientWrapper*>(client)->p->SwitchVideoDevice(config);

   // result.success(null);
   webrtc::ScopedJavaLocalRef<jclass> resultcls(env, env->GetObjectClass(result));
   jmethodID successid = env->GetMethodID(resultcls.obj(), "success", "(Ljava/lang/Object;)V");
   env->CallVoidMethod(result, successid, nullptr);
}