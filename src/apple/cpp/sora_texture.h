#ifndef SORA_FLUTTER_SDK_SORA_TEXTURE_H_
#define SORA_FLUTTER_SDK_SORA_TEXTURE_H_

#include <memory>
#include <functional>

#include <RTCMacros.h>

#include <CoreVideo/CVPixelBuffer.h>

RTC_FWD_DECL_OBJC_CLASS(FlutterTexture);

namespace sora_flutter_sdk {

class SoraTexture {
public:
  static std::shared_ptr<SoraTexture> Create(std::function<CVPixelBufferRef ()> copy_texture);
  virtual FlutterTexture* GetFlutterTexture() const = 0;
};

}

#endif
