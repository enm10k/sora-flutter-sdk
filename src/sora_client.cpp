#include "sora_client.h"

#if defined(__ANDROID__)
#include <sdk/android/native_api/jni/class_loader.h>
#include <sdk/android/native_api/jni/jvm.h>
#elif defined(_WIN32)
#include <flutter/event_stream_handler_functions.h>
#include <flutter/event_stream_handler.h>
#include <flutter/standard_method_codec.h>
#elif defined(__linux__)
#endif

// WebRTC
#include <rtc_base/logging.h>

#if TARGET_OS_IPHONE
#import <sdk/objc/components/audio/RTCAudioSession.h>
#import <sdk/objc/components/audio/RTCAudioSessionConfiguration.h>
#endif

#include <sora/audio_device_module.h>
#include <sora/java_context.h>
#include <sora/sora_video_decoder_factory.h>
#include <sora/sora_video_encoder_factory.h>

#if defined(__ANDROID__)
#include <sora/android/android_capturer.h>
#endif

#if defined(__ANDROID__)

extern "C" JNIEXPORT void JNICALL
Java_jp_shiguredo_sora_1flutter_1sdk_EventChannelHandler_nativeOnListen(JNIEnv* env,
                                         jobject self,
                                         jlong ptr,
                                         jobject arguments,
                                         jobject events) {
  if (ptr == 0) {
    return;
  }
  ((sora_flutter_sdk::SoraClient*)ptr)->OnListen(env, self, arguments, events);
}
extern "C" JNIEXPORT void JNICALL
Java_jp_shiguredo_sora_1flutter_1sdk_EventChannelHandler_nativeOnCancel(JNIEnv* env,
                                         jobject self,
                                         jlong ptr,
                                         jobject arguments) {
  if (ptr == 0) {
    return;
  }
  ((sora_flutter_sdk::SoraClient*)ptr)->OnCancel(env, self, arguments);
}

void RunOnMainThread(JNIEnv* env, std::function<void (JNIEnv*)> f);

#elif defined(__APPLE__)

#import "SoraUtils.h"

typedef FlutterError *_Nullable (^StreamHandlerOnListen)(id _Nullable, FlutterEventSink __nonnull);

@interface SoraClientStreamHandler : NSObject <FlutterStreamHandler>

@property (nonatomic) StreamHandlerOnListen onListen;

- (instancetype)initWithOnListen:(StreamHandlerOnListen)onListen;

@end

#endif

namespace sora_flutter_sdk {

#if defined(__ANDROID__)
void SoraClient::OnListen(JNIEnv* env, jobject self, jobject arguments, jobject events) {
  event_sink_ = webrtc::ScopedJavaLocalRef<jobject>(env, events);
}
void SoraClient::OnCancel(JNIEnv* env, jobject self, jobject arguments) {
  RTC_LOG(LS_INFO) << "OnCancel: this=" << (void*)this;
  event_sink_ = nullptr;
}
#endif

SoraClient::SoraClient(SoraClientConfig config)
    : config_(config) {
#if defined(__ANDROID__)
  auto env = config_.env;

  messenger_ = webrtc::JavaParamRef<jobject>(config_.messenger);
  texture_registry_ = webrtc::JavaParamRef<jobject>(config_.texture_registry);

  // event_channel_ = new EventChannel(messenger_, event_channel);
  // event_handler_ = new EventChannelHandler(this);
  // event_channel_.setStreamHandler(handler);
  webrtc::ScopedJavaLocalRef<jclass> evcls = webrtc::GetClass(env, "io/flutter/plugin/common/EventChannel");
  jmethodID evctorid = env->GetMethodID(evcls.obj(), "<init>", "(Lio/flutter/plugin/common/BinaryMessenger;Ljava/lang/String;)V");
  webrtc::ScopedJavaLocalRef<jobject> evobj(env, env->NewObject(evcls.obj(), evctorid, messenger_.obj(), env->NewStringUTF(config_.event_channel.c_str())));

  webrtc::ScopedJavaLocalRef<jclass> hndcls = webrtc::GetClass(env, "jp/shiguredo/sora_flutter_sdk/EventChannelHandler");
  jmethodID hndctorid = env->GetMethodID(hndcls.obj(), "<init>", "(J)V");
  webrtc::ScopedJavaLocalRef<jobject> hndobj(env, env->NewObject(hndcls.obj(), hndctorid, (jlong)this));

  jmethodID set_stream_handler_id = env->GetMethodID(evcls.obj(), "setStreamHandler", "(Lio/flutter/plugin/common/EventChannel$StreamHandler;)V");
  env->CallVoidMethod(evobj.obj(), set_stream_handler_id, hndobj.obj());

  event_channel_ = evobj;
  event_handler_ = hndobj;
#elif defined(_WIN32)
  event_channel_.reset(new flutter::EventChannel<flutter::EncodableValue>(
      config_.messenger, config_.event_channel, &flutter::StandardMethodCodec::GetInstance()));

  auto handler = std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
    [this](
        const flutter::EncodableValue* arguments,
        std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events
    ) -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
      RTC_LOG(LS_INFO) << "WindowsEventHandler OnListen";
      event_sink_ = std::move(events);
      return nullptr;
    },
    [this](const flutter::EncodableValue* arguments)
      -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
      RTC_LOG(LS_INFO) << "WindowsEventHandler OnCancel";
      event_sink_ = nullptr;
      return nullptr;
    });

  event_channel_->SetStreamHandler(std::move(handler));
#elif defined(__APPLE__)
  event_channel_ = [[FlutterEventChannel alloc] initWithName: [SoraUtils stringForStdString: config.event_channel]
   binaryMessenger: config_.messenger
    codec: [FlutterStandardMethodCodec sharedInstance]];
  stream_handler_ = [[SoraClientStreamHandler alloc] initWithOnListen:
    ^(id _Nullable arguments, FlutterEventSink __nonnull events) {
    event_sink_ = events;
    return (FlutterError *)nil;
  }];
  [event_channel_ setStreamHandler: stream_handler_];
#else
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlEventChannel) channel = fl_event_channel_new(config_.messenger, config_.event_channel.c_str(), FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(
    channel,
    [](FlEventChannel* channel,
       FlValue* args,
       gpointer user_data) -> FlMethodErrorResponse* {
      ((SoraClient*)user_data)->event_channel_listened_ = true;
      return nullptr;
    },
    [](FlEventChannel* channel,
       FlValue* args,
       gpointer user_data) -> FlMethodErrorResponse* {
      ((SoraClient*)user_data)->event_channel_listened_ = false;
      return nullptr;
    }, this, nullptr);
  event_channel_.reset(channel, [](FlEventChannel* p) { g_object_unref(p); });
  channel = nullptr;
#endif

  ioc_.reset(new boost::asio::io_context(1));
}

SoraClient::~SoraClient() {
  RTC_LOG(LS_INFO) << "SoraClient dtor";
}

void SoraClient::Destroy() {
  RTC_LOG(LS_INFO) << "SoraClient::Destroy";

  io_thread_.reset();

#if defined(__ANDROID__)
  auto env = config_.env;

  // event_handler_.clear();
  webrtc::ScopedJavaLocalRef<jclass> hndcls(env, env->GetObjectClass(event_handler_.obj()));
  jmethodID clearid = env->GetMethodID(hndcls.obj(), "clear", "()V");
  env->CallVoidMethod(event_handler_.obj(), clearid);

  // event_channel_.setStreamHandler(null);
  webrtc::ScopedJavaLocalRef<jclass> evcls(env, env->GetObjectClass(event_channel_.obj()));
  jmethodID set_stream_handler_id = env->GetMethodID(evcls.obj(), "setStreamHandler", "(Lio/flutter/plugin/common/EventChannel$StreamHandler;)V");
  env->CallVoidMethod(event_channel_.obj(), set_stream_handler_id, NULL);
#elif defined(_WIN32)
  event_channel_->SetStreamHandler(nullptr);
#elif defined(__APPLE__)
  [event_channel_ setStreamHandler: nil];
#else
  fl_event_channel_set_stream_handlers(event_channel_.get(), nullptr, nullptr, nullptr, nullptr);
#endif
}

void SoraClient::Connect() {
#if TARGET_OS_IPHONE
    auto config = [RTCAudioSessionConfiguration webRTCConfiguration];
    config.category = AVAudioSessionCategoryPlayAndRecord;
    [[RTCAudioSession sharedInstance] initializeInput:^(NSError* error) {
      if (error != nil) {
        RTC_LOG(LS_ERROR) << [error.localizedDescription UTF8String];
        return;
     }
    }];
#endif
  io_thread_ = rtc::Thread::Create();
  io_thread_->SetName("Sora Flutter SDK IO Thread", nullptr);
  io_thread_->Start();
  io_thread_->PostTask([self = shared_from_this()]() {
#if defined(__ANDROID__)
    self->io_env_ = webrtc::AttachCurrentThreadIfNeeded();
#endif
    self->DoConnect();
  });
}

void SoraClient::DoConnect() {
#if defined(__ANDROID__)
  renderer_.reset(new SoraRenderer(io_env_, texture_registry_.obj()));
#else
  renderer_.reset(new SoraRenderer(config_.texture_registrar));
#endif

  if (config_.signaling_config.video) {
    sora::CameraDeviceCapturerConfig cam_config;
    cam_config.device_name = config_.video_device_name;
    cam_config.width = config_.video_device_width;
    cam_config.height = config_.video_device_height;
    cam_config.fps = config_.video_device_fps;
#if defined(__ANDROID__)
    auto env = io_env_;
    cam_config.jni_env = env;
    cam_config.application_context = GetAndroidApplicationContext(env);
#endif
    cam_config.signaling_thread = context()->signaling_thread();
    video_source_ = sora::CreateCameraDeviceCapturer(cam_config);

    std::string video_track_id = rtc::CreateRandomString(16);
    video_track_ =
        factory()->CreateVideoTrack(video_track_id, video_source_.get());
  }

  if (config_.signaling_config.audio) {
    std::string audio_track_id = rtc::CreateRandomString(16);
    audio_track_ = factory()->CreateAudioTrack(
        audio_track_id,
        factory()->CreateAudioSource(cricket::AudioOptions()).get());
  }

  sora::SoraSignalingConfig config = config_.signaling_config;
  config.pc_factory = factory();
  config.io_context = ioc_.get();
  config.observer = shared_from_this();
  config.network_manager = context()->signaling_thread()->BlockingCall([this]() {
    return context()->connection_context()->default_network_manager();
  });
  config.socket_factory = context()->signaling_thread()->BlockingCall([this]() {
    return context()->connection_context()->default_socket_factory();
  });
  conn_ = sora::SoraSignaling::Create(config);

  boost::asio::executor_work_guard<boost::asio::io_context::executor_type>
      work_guard(ioc_->get_executor());

  boost::asio::signal_set signals(*ioc_, SIGINT, SIGTERM);
  signals.async_wait(
      [this](const boost::system::error_code&, int) { conn_->Disconnect(); });

  conn_->Connect();
  ioc_->run();
}

void SoraClient::Disconnect() {
  boost::asio::post(*ioc_, [self = shared_from_this()]() {
    self->conn_->Disconnect();
  });
}

bool SoraClient::SendDataChannel(std::string label, std::string data) {
  return conn_->SendDataChannel(label, data);
}

void SoraClient::SetVideoEnabled(bool flag) {
  if (video_track_ != nullptr) {
    video_track_->set_enabled(flag);
  }
}

void SoraClient::SetAudioEnabled(bool flag) {
  if (audio_track_ != nullptr) {
    audio_track_->set_enabled(flag);
  }
}

void SoraClient::OnSetOffer(std::string offer) {
  std::string stream_id = rtc::CreateRandomString(16);
  if (audio_track_ != nullptr) {
    webrtc::RTCErrorOr<rtc::scoped_refptr<webrtc::RtpSenderInterface>>
        audio_result =
            conn_->GetPeerConnection()->AddTrack(audio_track_, {stream_id});
  }
  if (video_track_ != nullptr) {
    webrtc::RTCErrorOr<rtc::scoped_refptr<webrtc::RtpSenderInterface>>
        video_result =
            conn_->GetPeerConnection()->AddTrack(video_track_, {stream_id});
   if (video_result.ok()) {
     video_sender_ = video_result.value();
   }
  }

  if (video_track_ != nullptr) {
    auto texture_id = renderer_->AddTrack(video_track_.get());
    boost::json::object obj;
    obj["event"] = "AddTrack";
    obj["connection_id"] = "";
    obj["texture_id"] = texture_id;
    SendEvent(obj);
  }

  {
    boost::json::object obj;
    obj["event"] = "SetOffer";
    obj["offer"] = offer;
    SendEvent(obj);
  }
}

void SoraClient::OnDisconnect(sora::SoraSignalingErrorCode ec,
                             std::string message) {
  RTC_LOG(LS_INFO) << "OnDisconnect: " << message;
  ioc_->stop();

#if defined(__ANDROID__)
  static_cast<sora::AndroidCapturer*>(video_source_.get())->Stop();
#endif
  renderer_ = nullptr;
  video_track_ = nullptr;
  audio_track_ = nullptr;
  video_sender_ = nullptr;
  video_source_ = nullptr;

  boost::json::object obj;
  obj["event"] = "Disconnect";
  std::string s;
  switch (ec) {
    case sora::SoraSignalingErrorCode::CLOSE_SUCCEEDED: s = "CLOSE_SUCCEEDED"; break;
    case sora::SoraSignalingErrorCode::CLOSE_FAILED: s = "CLOSE_FAILED"; break;
    case sora::SoraSignalingErrorCode::INTERNAL_ERROR: s = "INTERNAL_ERROR"; break;
    case sora::SoraSignalingErrorCode::INVALID_PARAMETER: s = "INVALID_PARAMETER"; break;
    case sora::SoraSignalingErrorCode::WEBSOCKET_HANDSHAKE_FAILED: s = "WEBSOCKET_HANDSHAKE_FAILED"; break;
    case sora::SoraSignalingErrorCode::WEBSOCKET_ONCLOSE: s = "WEBSOCKET_ONCLOSE"; break;
    case sora::SoraSignalingErrorCode::WEBSOCKET_ONERROR: s = "WEBSOCKET_ONERROR"; break;
    case sora::SoraSignalingErrorCode::PEER_CONNECTION_STATE_FAILED: s = "PEER_CONNECTION_STATE_FAILED"; break;
    case sora::SoraSignalingErrorCode::ICE_FAILED: s = "ICE_FAILED"; break;
    case sora::SoraSignalingErrorCode::LYRA_VERSION_INCOMPATIBLE: s = "LYRA_VERSION_INCOMPATIBLE"; break;
  }
  obj["error_code"] = s;
  obj["message"] = message;
  SendEvent(obj);
}

void SoraClient::OnNotify(std::string text) {
  boost::json::object obj;
  obj["event"] = "Notify";
  obj["text"] = text;
  SendEvent(obj);
}
void SoraClient::OnPush(std::string text) {
  boost::json::object obj;
  obj["event"] = "Push";
  obj["text"] = text;
  SendEvent(obj);
}
void SoraClient::OnMessage(std::string label, std::string data) {
  boost::json::object obj;
  obj["event"] = "Message";
  obj["label"] = label;
  boost::json::array bytes;
  for (int i = 0; i < data.length(); i++) {
    bytes.push_back((uint8_t)data[i]);
  }
  obj["data"] = bytes;
  SendEvent(obj);
}

void SoraClient::OnTrack(rtc::scoped_refptr<webrtc::RtpTransceiverInterface> transceiver) {
  auto track = transceiver->receiver()->track();
  if (track->kind() == webrtc::MediaStreamTrackInterface::kVideoKind) {
    auto connection_id = transceiver->receiver()->stream_ids()[0];
    auto texture_id = renderer_->AddTrack(
        static_cast<webrtc::VideoTrackInterface*>(track.get()));
    connection_ids_.insert(std::make_pair(texture_id, connection_id));

    boost::json::object obj;
    obj["event"] = "AddTrack";
    obj["connection_id"] = connection_id;
    obj["texture_id"] = texture_id;
    SendEvent(obj);
  }
}
void SoraClient::OnRemoveTrack(
    rtc::scoped_refptr<webrtc::RtpReceiverInterface> receiver) {
  auto track = receiver->track();
  if (track->kind() == webrtc::MediaStreamTrackInterface::kVideoKind) {
    auto texture_id = renderer_->RemoveTrack(
        static_cast<webrtc::VideoTrackInterface*>(track.get()));
    auto connection_id = connection_ids_[texture_id];
    connection_ids_.erase(texture_id);

    if (texture_id != 0) {
      boost::json::object obj;
      obj["event"] = "RemoveTrack";
      obj["connection_id"] = connection_id;
      obj["texture_id"] = texture_id;
      SendEvent(obj);
    }
  }
}

void SoraClient::OnDataChannel(std::string label) {
  boost::json::object obj;
  obj["event"] = "DataChannel";
  obj["label"] = label;
  SendEvent(obj);
}

void SoraClient::SendEvent(const boost::json::value& v) {
  std::string json = boost::json::serialize(v);
  RTC_LOG(LS_INFO) << "SendEvent: event=" << v.at("event").as_string() << " json=" << json;
#if defined(__ANDROID__)
  if (!event_sink_.is_null()) {
    auto env = io_env_;
    // m = new HashMap();
    // m.put("json", json);
    // event_sink_.success(m);
    RunOnMainThread(io_env_, [&, this](JNIEnv* env) {
      webrtc::ScopedJavaLocalRef<jclass> mapcls = webrtc::GetClass(env, "java/util/HashMap");
      jmethodID ctorid = env->GetMethodID(mapcls.obj(), "<init>", "()V");
      webrtc::ScopedJavaLocalRef<jobject> mapobj(env, env->NewObject(mapcls.obj(), ctorid));
      jmethodID putid = env->GetMethodID(mapcls.obj(), "put", "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;");
      env->CallObjectMethod(mapobj.obj(), putid, env->NewStringUTF("json"), env->NewStringUTF(json.c_str()));
      webrtc::ScopedJavaLocalRef<jclass> sinkcls(env, env->GetObjectClass(event_sink_.obj()));
      jmethodID successid = env->GetMethodID(sinkcls.obj(), "success", "(Ljava/lang/Object;)V");
      env->CallVoidMethod(event_sink_.obj(), successid, mapobj.obj());
    });
  }
#elif defined(_WIN32)
  if (event_sink_ != nullptr) {
    flutter::EncodableMap params;
    params[flutter::EncodableValue("json")] = flutter::EncodableValue(json);
    event_sink_->Success(flutter::EncodableValue(params));
  }
#elif defined(__APPLE__)
  if (event_sink_ != nullptr) {
      event_sink_(@{
        @"json" : [SoraUtils stringForStdString: json],
      });
  }
#else
  if (event_channel_listened_) {
    g_autoptr(FlValue) params = fl_value_new_map();
    fl_value_set_string_take(params, "json", fl_value_new_string(json.c_str()));
    fl_event_channel_send(event_channel_.get(), params, nullptr, nullptr);
  }
#endif
}

void SoraClient::SwitchVideoDevice(const sora::CameraDeviceCapturerConfig &config) {
  boost::asio::post(*ioc_, [self = shared_from_this(), config]() {
    self->DoSwitchVideoDevice(config);
  });
}

void SoraClient::DoSwitchVideoDevice(const sora::CameraDeviceCapturerConfig &baseConfig) {
  auto old_texture_id = renderer_->RemoveTrack(video_track_.get());
  video_sender_->SetTrack(nullptr);
  video_track_ = nullptr;

#if defined(__ANDROID__)
  static_cast<sora::AndroidCapturer*>(video_source_.get())->Stop();
#endif

  video_source_ = nullptr;

  sora::CameraDeviceCapturerConfig config = baseConfig;
#if defined(__ANDROID__)
  auto env = io_env_;
  config.jni_env = env;
  config.application_context = GetAndroidApplicationContext(env);
#endif
  config.signaling_thread = context()->signaling_thread();

  auto source = sora::CreateCameraDeviceCapturer(config);
  if (source == nullptr) {
    return;
  }

  std::string video_track_id = rtc::CreateRandomString(16);
  auto track = factory()->CreateVideoTrack(video_track_id, source.get());
  if (track == nullptr) {
    return;
  }

  video_source_ = source;
  video_track_ = track;

  // pc に新しいトラックを追加して sender を作り直すと映像が送信されないので
  // 既存の sender のトラックを置き換える
  video_sender_->SetTrack(video_track_.get());

  auto new_texture_id = renderer_->AddTrack(video_track_.get());
  boost::json::object obj;
  obj["event"] = "SwitchVideoTrack";
  obj["connection_id"] = "";
  obj["old_texture_id"] = old_texture_id;
  obj["new_texture_id"] = new_texture_id;
  SendEvent(obj);
}

}

#ifdef __APPLE__
@implementation SoraClientStreamHandler

- (instancetype)initWithOnListen:(StreamHandlerOnListen)onListen
{
    if (self = [super init]) {
        self.onListen = onListen;
    }
    return self;
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:
                                           (nonnull FlutterEventSink)events
{
  NSLog(@"EventSink: onListenWithArguments");
    return self.onListen(arguments, events);
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments
{
    return nil;
}

@end
#endif
