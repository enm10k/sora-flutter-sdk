#ifndef BLANK_VIDEO_CAPTURER_H_
#define BLANK_VIDEO_CAPTURER_H_

#include <memory>
#include <thread>

// Sora C++ SDK
#include <sora/scalable_track_source.h>

// WebRTC
#include <api/video/i420_buffer.h>
#include <rtc_base/ref_counted_object.h>

struct BlankVideoCapturerConfig : sora::ScalableVideoTrackSourceConfig {
  int width;
  int height;
  int fps;
};

class BlankVideoCapturer : public sora::ScalableVideoTrackSource {
  BlankVideoCapturer(BlankVideoCapturerConfig config);
  friend class rtc::RefCountedObject<BlankVideoCapturer>;

 public:
  static rtc::scoped_refptr<BlankVideoCapturer> Create(
      BlankVideoCapturerConfig config) {
    return rtc::make_ref_counted<BlankVideoCapturer>(std::move(config));
  }

  ~BlankVideoCapturer();

  void StartCapture();
  void StopCapture();

 private:
  // std::unique_ptr<std::thread> thread_;
  BlankVideoCapturerConfig config_;
  std::atomic_bool stopped_{false};
  std::chrono::high_resolution_clock::time_point started_at_;
};

#endif
