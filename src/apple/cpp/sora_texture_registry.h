#ifndef SORA_FLUTTER_SDK_SORA_TEXTURE_REGISTRY_H_
#define SORA_FLUTTER_SDK_SORA_TEXTURE_REGISTRY_H_

#include <memory>

#include <RTCMacros.h>

RTC_FWD_DECL_OBJC_CLASS(FlutterTextureRegistry);
RTC_FWD_DECL_OBJC_CLASS(FlutterTexture);

namespace sora_flutter_sdk {

class SoraTextureRegistry {
public:
  virtual int64_t RegisterTexture(FlutterTexture* texture) = 0;
  virtual void UnregisterTexture(int64_t texture_id) = 0;
  virtual void MarkTextureFrameAvailable(int64_t texture_id) = 0;
  static std::shared_ptr<SoraTextureRegistry> Create(void* registrar);
};

}

#endif
