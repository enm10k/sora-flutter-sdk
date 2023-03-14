#ifndef SORA_FLUTTER_SDK_DEVICE_LIST_H
#define SORA_FLUTTER_SDK_DEVICE_LIST_H

#include <functional>
#include <string>

namespace sora_flutter_sdk {

class DeviceList {
 public:
  static bool EnumVideoCapturer(
      std::function<void(std::string, std::string)> f);
 private:
#if defined(__linux__)
  static bool FindDevice(const char* deviceUniqueIdUTF8, const std::string& device);
#endif
};

}  // namespace sora_flutter_sdk

#endif //SORA_FLUTTER_SDK_DEVICE_LIST_H
