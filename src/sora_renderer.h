#ifndef SORA_FLUTTER_SDK_SORA_RENDERER_H_
#define SORA_FLUTTER_SDK_SORA_RENDERER_H_

#include <mutex>

#if defined(__ANDROID__)
#include <jni.h>
#include <sdk/android/native_api/jni/scoped_java_ref.h>
#include <sdk/android/native_api/video/wrapper.h>
#elif defined(_WIN32)
#include <flutter/texture_registrar.h>
#elif defined(__APPLE__)
#import "SoraBase.h"
#elif defined(__linux__)
#include <flutter_linux/flutter_linux.h>
#endif

// webrtc
#include <api/media_stream_interface.h>
#include <api/video/i420_buffer.h>
#include <api/video/video_frame.h>
#include <api/video/video_sink_interface.h>
#include <libyuv.h>

namespace sora_flutter_sdk {

class SoraRenderer {
 public:
#if defined(__ANDROID__)
  SoraRenderer(JNIEnv* env, jobject texture_registrar);
#elif defined(_WIN32)
  SoraRenderer(flutter::TextureRegistrar* texture_registrar);
#elif defined(__APPLE__)
  SoraRenderer(id<FlutterTextureRegistry> texture_registrar);
#elif defined(__linux__)
  SoraRenderer(FlTextureRegistrar* texture_registrar);
#endif
  int64_t AddTrack(webrtc::VideoTrackInterface* track);
  int64_t RemoveTrack(webrtc::VideoTrackInterface* track);

 private:
  class Sink : public rtc::VideoSinkInterface<webrtc::VideoFrame> {
   public:
#if defined(__ANDROID__)
    Sink(webrtc::VideoTrackInterface* track, JNIEnv* env, jobject texture_registrar);
#elif defined(_WIN32)
    Sink(webrtc::VideoTrackInterface* track, flutter::TextureRegistrar* texture_registrar);
#elif defined(__APPLE__)
    Sink(webrtc::VideoTrackInterface* track, id<FlutterTextureRegistry> texture_registrar);
#elif defined(__linux__)
    Sink(webrtc::VideoTrackInterface* track, FlTextureRegistrar* texture_registrar);
#endif
    ~Sink();

    int64_t GetTextureID() const;

    void OnFrame(const webrtc::VideoFrame& frame) override;

   private:
    rtc::scoped_refptr<webrtc::VideoTrackInterface> track_;
    std::mutex mutex_;
    std::unique_ptr<webrtc::VideoFrame> frame_;
    int64_t texture_id_;
    std::unique_ptr<uint8_t[]> rgba_buffer_;
#if defined(__ANDROID__)
    JNIEnv* env_;
    webrtc::ScopedJavaGlobalRef<jobject> texture_registrar_;
    webrtc::ScopedJavaGlobalRef<jobject> texture_entry_;
    webrtc::ScopedJavaGlobalRef<jobject> egl_renderer_;
    int width_ = 0;
    int height_ = 0;
#elif defined(_WIN32)
    flutter::TextureRegistrar* texture_registrar_;
    std::unique_ptr<flutter::TextureVariant> texture_;
    std::unique_ptr<FlutterDesktopPixelBuffer> pixel_buffer_;
#elif defined(__APPLE__)
    id<FlutterTextureRegistry> texture_registrar_;
    id<FlutterTexture> texture_;
    CVPixelBufferRef pixel_buffer_;
#elif defined(__linux__)
    std::shared_ptr<FlTexture> texture_;
    FlTextureRegistrar* texture_registrar_;
    int width_ = 0;
    int height_ = 0;
#endif
  };

 private:
  typedef std::vector<
      std::pair<webrtc::VideoTrackInterface*, std::unique_ptr<Sink>>>
      VideoSinkVector;
  VideoSinkVector sinks_;
#if defined(__ANDROID__)
  JNIEnv* env_;
  webrtc::ScopedJavaGlobalRef<jobject> texture_registrar_;
#elif defined(_WIN32)
  flutter::TextureRegistrar* texture_registrar_;
#elif defined(__APPLE__)
  id<FlutterTextureRegistry> texture_registrar_;
#elif defined(__linux__)
  FlTextureRegistrar* texture_registrar_;
#endif
};

}  // namespace sora_flutter_sdk

#endif