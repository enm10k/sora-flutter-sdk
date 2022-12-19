#include "device_list.h"

// webrtc
#include <api/task_queue/default_task_queue_factory.h>
#include <modules/audio_device/include/audio_device.h>
#include <modules/audio_device/include/audio_device_factory.h>
#include <modules/video_capture/video_capture.h>
#include <modules/video_capture/video_capture_factory.h>
#include <rtc_base/logging.h>

#ifdef __ANDROID__
#include <sora/android/android_capturer.h>
#include <sdk/android/native_api/audio_device_module/audio_device_android.h>
#include <sdk/android/native_api/jni/jvm.h>
#endif

#if defined(__APPLE__)
#include <sora/mac/mac_capturer.h>
#endif

#if defined(__ANDROID__)
void* GetAndroidApplicationContext(void*);
#endif

namespace sora_flutter_sdk {

bool DeviceList::EnumVideoCapturer(
    std::function<void(std::string, std::string)> f) {
#if defined(__APPLE__)

  return sora::MacCapturer::EnumVideoDevice(f);

#elif defined(__ANDROID__)

  JNIEnv* env = webrtc::AttachCurrentThreadIfNeeded();
  auto context = (jobject)GetAndroidApplicationContext(env);
  if (context != nullptr) {
    return sora::AndroidCapturer::EnumVideoDevice(env, context, f);
  } else {
    return false;
  }

#else

  std::unique_ptr<webrtc::VideoCaptureModule::DeviceInfo> info(
      webrtc::VideoCaptureFactory::CreateDeviceInfo());
  if (!info) {
    RTC_LOG(LS_WARNING) << "Failed to CreateDeviceInfo";
    return false;
  }

  int num_devices = info->NumberOfDevices();
  for (int i = 0; i < num_devices; i++) {
    char device_name[256];
    char unique_name[256];
    if (info->GetDeviceName(i, device_name, sizeof(device_name), unique_name,
                            sizeof(unique_name)) != 0) {
      RTC_LOG(LS_WARNING) << "Failed to GetDeviceName: index=" << i;
      continue;
    }

    RTC_LOG(LS_INFO) << "EnumVideoCapturer: device_name=" << device_name
                     << " unique_name=" << unique_name;
    f(device_name, unique_name);
  }
  return true;

#endif
}

}  // namespace sora_flutter_sdk