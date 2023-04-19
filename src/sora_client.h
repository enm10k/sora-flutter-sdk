#ifndef SORA_FLUTTER_SDK_SORA_CLIENT_H_
#define SORA_FLUTTER_SDK_SORA_CLIENT_H_

#if defined(__ANDROID__)
#include <jni.h>
#include <sdk/android/native_api/jni/scoped_java_ref.h>
#elif defined(_WIN32)
#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/event_sink.h>
#include <flutter/event_channel.h>
#include <flutter/texture_registrar.h>
#elif defined(__APPLE__)
#import "SoraBase.h"
#else
#include <flutter_linux/flutter_linux.h>
#endif

#include <sora/sora_client_context.h>
#include <sora/camera_device_capturer.h>

#include "sora_renderer.h"

#if defined(__ANDROID__)
void* GetAndroidApplicationContext(void*);
#endif

namespace sora_flutter_sdk {

struct SoraClientConfig {
  std::string video_device_name;
  int video_device_width = 640;
  int video_device_height = 480;
  int video_device_fps = 30;

  sora::SoraSignalingConfig signaling_config;
  sora::SoraClientContextConfig context_config;

  std::string event_channel;
#if defined(__ANDROID__)
  JNIEnv* env;
  jobject messenger;
  jobject texture_registry;
#elif defined(_WIN32)
  flutter::BinaryMessenger *messenger;
  flutter::TextureRegistrar *texture_registrar;
#elif defined(__APPLE__)
  id<FlutterBinaryMessenger> messenger;
  id<FlutterTextureRegistry> texture_registrar;
#else
  FlBinaryMessenger *messenger;
  FlTextureRegistrar *texture_registrar;
#endif
};

class SoraClient : public std::enable_shared_from_this<SoraClient>,
                  public sora::SoraSignalingObserver {
 public:
  SoraClient(SoraClientConfig config);
  virtual ~SoraClient();
  void Destroy();

  void Connect();
  void Disconnect();
  bool SendDataChannel(std::string label, std::string data);
  void SwitchVideoDevice(const sora::CameraDeviceCapturerConfig &config);

  void SetVideoEnabled(bool flag);
  void SetAudioEnabled(bool flag);

  void OnSetOffer(std::string offer) override;
  void OnDisconnect(sora::SoraSignalingErrorCode ec,
                    std::string message) override;

  void OnNotify(std::string text) override;
  void OnPush(std::string text) override;
  void OnMessage(std::string label, std::string data) override;

  void OnTrack(rtc::scoped_refptr<webrtc::RtpTransceiverInterface> transceiver)
      override;
  void OnRemoveTrack(
      rtc::scoped_refptr<webrtc::RtpReceiverInterface> receiver) override;

  void OnDataChannel(std::string label) override;

#if defined(__ANDROID__)
  void* GetAndroidApplicationContext(void* env) { return ::GetAndroidApplicationContext(env); }
  void OnListen(JNIEnv* env, jobject self, jobject arguments, jobject events);
  void OnCancel(JNIEnv* env, jobject self, jobject arguments);
#endif

 private:
  void DoConnect();
  void SendEvent(const boost::json::value& v);
  void DoSwitchVideoDevice(const sora::CameraDeviceCapturerConfig &config);

  static std::shared_ptr<sora::SoraClientContext> CreateClientContext(const sora::SoraClientContextConfig& new_config) {
    std::unique_lock<std::mutex> lock(context_mutex_);
    if (!shared_context_ || shared_context_config_.use_audio_device != new_config.use_audio_device || shared_context_config_.use_hardware_encoder != new_config.use_hardware_encoder) {
      shared_context_config_ = new_config;
      shared_context_ = sora::SoraClientContext::Create(shared_context_config_);
    }
    return shared_context_;
  }

  static sora::SoraClientContextConfig shared_context_config_;
  static std::shared_ptr<sora::SoraClientContext> shared_context_;
  static std::mutex context_mutex_;

  rtc::scoped_refptr<webrtc::PeerConnectionFactoryInterface> factory() const {
    return context_->peer_connection_factory();
  }

 private:
  SoraClientConfig config_;
  rtc::scoped_refptr<webrtc::VideoTrackSourceInterface> video_source_;
  rtc::scoped_refptr<webrtc::AudioTrackInterface> audio_track_;
  rtc::scoped_refptr<webrtc::VideoTrackInterface> video_track_;
  rtc::scoped_refptr<webrtc::RtpSenderInterface> video_sender_;

  std::shared_ptr<sora::SoraSignaling> conn_;
  std::shared_ptr<sora::SoraClientContext> context_;
  std::unique_ptr<boost::asio::io_context> ioc_;
  std::unique_ptr<rtc::Thread> io_thread_;

  std::unique_ptr<SoraRenderer> renderer_;
  std::map<int64_t, std::string> connection_ids_;

#if defined(__ANDROID__)
  JNIEnv* io_env_;
  webrtc::ScopedJavaGlobalRef<jobject> messenger_;
  webrtc::ScopedJavaGlobalRef<jobject> texture_registry_;
  webrtc::ScopedJavaGlobalRef<jobject> event_channel_;
  webrtc::ScopedJavaGlobalRef<jobject> event_handler_;
  webrtc::ScopedJavaGlobalRef<jobject> event_sink_;
#elif defined(_WIN32)
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> event_channel_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;
#elif defined(__APPLE__)
  FlutterEventChannel *event_channel_;
  NSObject<FlutterStreamHandler> *stream_handler_;
  FlutterEventSink event_sink_;
#else
  std::shared_ptr<FlEventChannel> event_channel_ = nullptr;
  bool event_channel_listened_ = false;
#endif
};

}

#endif
