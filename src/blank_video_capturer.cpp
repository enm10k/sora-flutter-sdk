#include "blank_video_capturer.h"

// WebRTC
#include <modules/video_capture/video_capture_defines.h>
#include <rtc_base/logging.h>

BlankVideoCapturer::BlankVideoCapturer(BlankVideoCapturerConfig config)
    : sora::ScalableVideoTrackSource(config), config_(config) {
  StartCapture();
}

BlankVideoCapturer::~BlankVideoCapturer() {
  StopCapture();
}

void BlankVideoCapturer::StartCapture() {
  StopCapture();
  stopped_ = false;
  started_at_ = std::chrono::high_resolution_clock::now();
}

void BlankVideoCapturer::StopCapture() {
  stopped_ = true;
}
