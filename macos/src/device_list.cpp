#include "device_list.h"

// webrtc
#include <api/task_queue/default_task_queue_factory.h>
#include <modules/audio_device/include/audio_device.h>
#include <modules/audio_device/include/audio_device_factory.h>
#include <modules/video_capture/video_capture.h>
#include <modules/video_capture/video_capture_factory.h>
#include <rtc_base/logging.h>

#ifdef __ANDROID__
#include <sdk/android/native_api/audio_device_module/audio_device_android.h>
#include <sdk/android/native_api/jni/jvm.h>
#include <sora/android/android_capturer.h>
#endif

#if defined(__APPLE__)
#include <sora/mac/mac_capturer.h>
#endif

#if defined(__ANDROID__)
void* GetAndroidApplicationContext(void*);
#endif

#if defined(__linux__)
#include <errno.h>
#include <fcntl.h>
#include <linux/videodev2.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/select.h>
#include <unistd.h>
#endif

namespace sora_flutter_sdk {

#if defined(__linux__)
bool DeviceList::FindDevice(const char* deviceUniqueIdUTF8,
                            const std::string& device) {
  int fd;
  if ((fd = open(device.c_str(), O_RDONLY)) != -1) {
    // query device capabilities
    struct v4l2_capability cap;
    if (ioctl(fd, VIDIOC_QUERYCAP, &cap) == 0) {
      if (cap.bus_info[0] != 0) {
        if (strncmp((const char*)cap.bus_info, (const char*)deviceUniqueIdUTF8,
                    strlen((const char*)deviceUniqueIdUTF8)) ==
            0)  // match with device id
        {
          close(fd);
          return true;
        }
      }
    }
    close(fd);  // close since this is not the matching device
  }
  return false;
}
#endif

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

#if defined(__linux__)
    /* detect /dev/video [0-63] entries */
    char device[32];
    int n;
    bool found = false;
    for (n = 0; n < 64; n++) {
      sprintf(device, "/dev/video%d", n);
      if (FindDevice(unique_name, device)) {
        found = true;
        strcpy(unique_name, device);
        break;
      }
    }
    if (!found) {
      RTC_LOG(LS_WARNING) << "device not found for '" << unique_name << "'";
    }
#endif

    RTC_LOG(LS_INFO) << "EnumVideoCapturer: device_name=" << device_name
                     << " unique_name=" << unique_name;
    f(device_name, unique_name);
  }
  return true;

#endif
}

}  // namespace sora_flutter_sdk