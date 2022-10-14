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

#include "sora/audio_device_module.h"
#include "sora/camera_device_capturer.h"
#include "sora/java_context.h"
#include "sora/sora_video_decoder_factory.h"
#include "sora/sora_video_encoder_factory.h"

#if defined(__ANDROID__)

extern "C" JNIEXPORT void JNICALL
Java_jp_shiguredo_sora_1flutter_1sdk_EventChannelHandler_nativeOnListen(JNIEnv* env,
                                         jobject self,
                                         jlong ptr,
                                         jobject arguments,
                                         jobject events) {
  ((sora_flutter_sdk::SoraClient*)ptr)->OnListen(env, self, arguments, events);
}
extern "C" JNIEXPORT void JNICALL
Java_jp_shiguredo_sora_1flutter_1sdk_EventChannelHandler_nativeOnCancel(JNIEnv* env,
                                         jobject self,
                                         jlong ptr,
                                         jobject arguments) {
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
  event_sink_ = nullptr;
}
#endif

SoraClient::SoraClient(SoraClientConfig config)
    : sora::SoraDefaultClient(config), config_(config) {
#if defined(__ANDROID__)
  messenger_ = config_.messenger;
  texture_registry_ = config_.texture_registry;

  // event_channel_ = new EventChannel(messenger_, event_channel);
  // auto handler = new EventChannelHandler(this);
  // event_channel_.setStreamHandler(handler);
  auto env = config_.env;
  webrtc::ScopedJavaLocalRef<jclass> evcls = webrtc::GetClass(env, "io/flutter/plugin/common/EventChannel");
  jmethodID evctorid = env->GetMethodID(evcls.obj(), "<init>", "(Lio/flutter/plugin/common/BinaryMessenger;Ljava/lang/String;)V");
  webrtc::ScopedJavaLocalRef<jobject> evobj(env, env->NewObject(evcls.obj(), evctorid, messenger_.obj(), env->NewStringUTF(config_.event_channel.c_str())));

  webrtc::ScopedJavaLocalRef<jclass> hndcls = webrtc::GetClass(env, "jp/shiguredo/sora_flutter_sdk/EventChannelHandler");
  jmethodID hndctorid = env->GetMethodID(hndcls.obj(), "<init>", "(J)V");
  webrtc::ScopedJavaLocalRef<jobject> hndobj(env, env->NewObject(hndcls.obj(), hndctorid, (jlong)this));

  jmethodID set_stream_handler_id = env->GetMethodID(evcls.obj(), "setStreamHandler", "(Lio/flutter/plugin/common/EventChannel$StreamHandler;)V");
  env->CallVoidMethod(evobj.obj(), set_stream_handler_id, hndobj.obj());

  event_channel_ = evobj;
#elif defined(_WIN32)
  event_channel_.reset(new flutter::EventChannel<flutter::EncodableValue>(
      config_.messenger, config_.event_channel, &flutter::StandardMethodCodec::GetInstance()));

  auto handler = std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
		  [this](
			  const flutter::EncodableValue* arguments,
			  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
		  -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
	  event_sink_ = std::move(events);
	  return nullptr;
  },
		  [this](const flutter::EncodableValue* arguments)
	  -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
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
}

SoraClient::~SoraClient() {
  RTC_LOG(LS_INFO) << "SoraClient dtor";
  ioc_.reset();
  video_track_ = nullptr;
  audio_track_ = nullptr;
  video_source_ = nullptr;
  io_thread_.reset();
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
  cam_config.signaling_thread = signaling_thread();
  video_source_ = sora::CreateCameraDeviceCapturer(cam_config);

  std::string audio_track_id = rtc::CreateRandomString(16);
  std::string video_track_id = rtc::CreateRandomString(16);
  audio_track_ = factory()->CreateAudioTrack(
      audio_track_id,
      factory()->CreateAudioSource(cricket::AudioOptions()).get());
  video_track_ =
      factory()->CreateVideoTrack(video_track_id, video_source_.get());

  ioc_.reset(new boost::asio::io_context(1));

  sora::SoraSignalingConfig config = config_.signaling_config;
  config.pc_factory = factory();
  config.io_context = ioc_.get();
  config.observer = shared_from_this();
  config.network_manager = connection_context()->default_network_manager();
  config.socket_factory = connection_context()->default_socket_factory();
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
  }

  if (video_track_ != nullptr) {
    auto texture_id = renderer_->AddTrack(video_track_.get());
#if defined(__ANDROID__)
    if (!event_sink_.is_null()) {
      // m = new HashMap();
      // m.put("event", "AddTrack");
      // m.put("connection_id", "");
      // m.put("texture_id", texture_id);
      // event_sink_.success(m);
      RunOnMainThread(io_env_, [&, this](JNIEnv* env) {
        webrtc::ScopedJavaLocalRef<jclass> mapcls = webrtc::GetClass(env, "java/util/HashMap");
        jmethodID ctorid = env->GetMethodID(mapcls.obj(), "<init>", "()V");
        webrtc::ScopedJavaLocalRef<jobject> mapobj(env, env->NewObject(mapcls.obj(), ctorid));
        jmethodID putid = env->GetMethodID(mapcls.obj(), "put", "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;");
        webrtc::ScopedJavaLocalRef<jclass> longcls = webrtc::GetClass(env, "java/lang/Long");
        jmethodID value_of_id = env->GetStaticMethodID(longcls.obj(), "valueOf", "(J)Ljava/lang/Long;");
        webrtc::ScopedJavaLocalRef<jobject> texture_id_obj(env, env->CallStaticObjectMethod(longcls.obj(), value_of_id, texture_id));
        env->CallObjectMethod(mapobj.obj(), putid, env->NewStringUTF("event"), env->NewStringUTF("AddTrack"));
        env->CallObjectMethod(mapobj.obj(), putid, env->NewStringUTF("connection_id"), env->NewStringUTF(""));
        env->CallObjectMethod(mapobj.obj(), putid, env->NewStringUTF("texture_id"), texture_id_obj.obj());
        webrtc::ScopedJavaLocalRef<jclass> sinkcls(env, env->GetObjectClass(event_sink_.obj()));
        jmethodID successid = env->GetMethodID(sinkcls.obj(), "success", "(Ljava/lang/Object;)V");
        env->CallVoidMethod(event_sink_.obj(), successid, mapobj.obj());
      });
    }
#elif defined(_WIN32)
    if (event_sink_ != nullptr) {
      flutter::EncodableMap params;
      params[flutter::EncodableValue("event")] = "AddTrack";
      params[flutter::EncodableValue("connection_id")] = "";
      params[flutter::EncodableValue("texture_id")] = flutter::EncodableValue(texture_id);
      event_sink_->Success(flutter::EncodableValue(params));
    }
#elif defined(__APPLE__)
    if (event_sink_ != nullptr) {
        event_sink_(@{@"event" : @"AddTrack",
        @"connection_id" : @"",
        @"texture_id" : @(texture_id),
        });
    }
#else
    if (event_channel_listened_) {
      g_autoptr(FlValue) params = fl_value_new_map();
      fl_value_set_string_take(params, "event", fl_value_new_string("AddTrack"));
      fl_value_set_string_take(params, "connection_id", fl_value_new_string(""));
      fl_value_set_string_take(params, "texture_id", fl_value_new_int(texture_id));
      fl_event_channel_send(event_channel_.get(), params, nullptr, nullptr);
    }
#endif
  }
}
void SoraClient::OnDisconnect(sora::SoraSignalingErrorCode ec,
                             std::string message) {
  RTC_LOG(LS_INFO) << "OnDisconnect: " << message;
  ioc_->stop();
}

void SoraClient::OnTrack(rtc::scoped_refptr<webrtc::RtpTransceiverInterface> transceiver) {
  auto track = transceiver->receiver()->track();
  if (track->kind() == webrtc::MediaStreamTrackInterface::kVideoKind) {
    auto connection_id = transceiver->receiver()->stream_ids()[0];
    auto texture_id = renderer_->AddTrack(
        static_cast<webrtc::VideoTrackInterface*>(track.get()));
    connection_ids_.insert(std::make_pair(texture_id, connection_id));

#if defined(__ANDROID__)
    if (!event_sink_.is_null()) {
      // m = new HashMap();
      // m.put("event", "AddTrack");
      // m.put("connection_id", connection_id);
      // m.put("texture_id", texture_id);
      // event_sink_.success(m);
      RunOnMainThread(io_env_, [&, this](JNIEnv* env) {
        webrtc::ScopedJavaLocalRef<jclass> mapcls = webrtc::GetClass(env, "java/util/HashMap");
        jmethodID ctorid = env->GetMethodID(mapcls.obj(), "<init>", "()V");
        webrtc::ScopedJavaLocalRef<jobject> mapobj(env, env->NewObject(mapcls.obj(), ctorid));
        jmethodID putid = env->GetMethodID(mapcls.obj(), "put", "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;");
        webrtc::ScopedJavaLocalRef<jclass> longcls = webrtc::GetClass(env, "java/lang/Long");
        jmethodID value_of_id = env->GetStaticMethodID(longcls.obj(), "valueOf", "(J)Ljava/lang/Long;");
        webrtc::ScopedJavaLocalRef<jobject> texture_id_obj(env, env->CallStaticObjectMethod(longcls.obj(), value_of_id, texture_id));
        env->CallObjectMethod(mapobj.obj(), putid, env->NewStringUTF("event"), env->NewStringUTF("AddTrack"));
        env->CallObjectMethod(mapobj.obj(), putid, env->NewStringUTF("connection_id"), env->NewStringUTF(connection_id.c_str()));
        env->CallObjectMethod(mapobj.obj(), putid, env->NewStringUTF("texture_id"), texture_id_obj.obj());
        webrtc::ScopedJavaLocalRef<jclass> sinkcls(env, env->GetObjectClass(event_sink_.obj()));
        jmethodID successid = env->GetMethodID(sinkcls.obj(), "success", "(Ljava/lang/Object;)V");
        env->CallVoidMethod(event_sink_.obj(), successid, mapobj.obj());
      });
    }
#elif defined(_WIN32)
    if (event_sink_ != nullptr) {
      flutter::EncodableMap params;
      params[flutter::EncodableValue("event")] = "AddTrack";
      params[flutter::EncodableValue("connection_id")] = connection_id;
      params[flutter::EncodableValue("texture_id")] = flutter::EncodableValue(texture_id);
      event_sink_->Success(flutter::EncodableValue(params));
    }
#elif defined(__APPLE__)
    if (event_sink_ != nullptr) {
        event_sink_(@{@"event" : @"AddTrack",
        @"connection_id" : [SoraUtils stringForStdString: connection_id],
        @"texture_id" : @(texture_id),
        });
    }
#else
    if (event_channel_listened_) {
      g_autoptr(FlValue) params = fl_value_new_map();
      fl_value_set_string_take(params, "event", fl_value_new_string("AddTrack"));
      fl_value_set_string_take(params, "connection_id", fl_value_new_string(connection_id.c_str()));
      fl_value_set_string_take(params, "texture_id", fl_value_new_int(texture_id));
      fl_event_channel_send(event_channel_.get(), params, nullptr, nullptr);
    }
#endif
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
#if defined(__ANDROID__)
      if (!event_sink_.is_null()) {
        auto env = io_env_;
        // m = new HashMap();
        // m.put("event", "RemoveTrack");
        // m.put("connection_id", connection_id);
        // m.put("texture_id", texture_id);
        // event_sink_.success(m);
        RunOnMainThread(io_env_, [&, this](JNIEnv* env) {
          webrtc::ScopedJavaLocalRef<jclass> mapcls = webrtc::GetClass(env, "java/util/HashMap");
          jmethodID ctorid = env->GetMethodID(mapcls.obj(), "<init>", "()V");
          webrtc::ScopedJavaLocalRef<jobject> mapobj(env, env->NewObject(mapcls.obj(), ctorid));
          jmethodID putid = env->GetMethodID(mapcls.obj(), "put", "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;");
          webrtc::ScopedJavaLocalRef<jclass> longcls = webrtc::GetClass(env, "java/lang/Long");
          jmethodID value_of_id = env->GetStaticMethodID(longcls.obj(), "valueOf", "(J)Ljava/lang/Long;");
          webrtc::ScopedJavaLocalRef<jobject> texture_id_obj(env, env->CallStaticObjectMethod(longcls.obj(), value_of_id, texture_id));
          env->CallObjectMethod(mapobj.obj(), putid, env->NewStringUTF("event"), env->NewStringUTF("RemoveTrack"));
          env->CallObjectMethod(mapobj.obj(), putid, env->NewStringUTF("connection_id"), env->NewStringUTF(connection_id.c_str()));
          env->CallObjectMethod(mapobj.obj(), putid, env->NewStringUTF("texture_id"), texture_id_obj.obj());
          webrtc::ScopedJavaLocalRef<jclass> sinkcls(env, env->GetObjectClass(event_sink_.obj()));
          jmethodID successid = env->GetMethodID(sinkcls.obj(), "success", "(Ljava/lang/Object;)V");
          env->CallVoidMethod(event_sink_.obj(), successid, mapobj.obj());
        });
      }
#elif defined(_WIN32)
      if (event_sink_ != nullptr) {
        flutter::EncodableMap params;
        params[flutter::EncodableValue("event")] = "RemoveTrack";
        params[flutter::EncodableValue("connection_id")] = connection_id;
        params[flutter::EncodableValue("texture_id")] = flutter::EncodableValue(texture_id);
        event_sink_->Success(flutter::EncodableValue(params));
      }
#elif defined(__APPLE__)
    if (event_sink_ != nullptr) {
        event_sink_(@{@"event" : @"RemoveTrack",
        @"connection_id" : [SoraUtils stringForStdString: connection_id],
        @"texture_id" : @(texture_id),
        });
    }
#else
    if (event_channel_listened_) {
      g_autoptr(FlValue) params = fl_value_new_map();
      fl_value_set_string_take(params, "event", fl_value_new_string("RemoveTrack"));
      fl_value_set_string_take(params, "connection_id", fl_value_new_string(connection_id.c_str()));
      fl_value_set_string_take(params, "texture_id", fl_value_new_int(texture_id));
      fl_event_channel_send(event_channel_.get(), params, nullptr, nullptr);
    }
#endif
    }
  }
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
