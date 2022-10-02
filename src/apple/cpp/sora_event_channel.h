#ifndef SORA_FLUTTER_SDK_SORA_EVENT_CHANNEL_H_
#define SORA_FLUTTER_SDK_SORA_EVENT_CHANNEL_H_

#include <functional>
#include <string>
#include <memory>

#include <RTCMacros.h>

RTC_FWD_DECL_OBJC_CLASS(FlutterBinaryMessenger);
RTC_FWD_DECL_OBJC_CLASS(FlutterStandardMethodCodec);

namespace sora_flutter_sdk {

typedef std::function<void (const std::string&)> SoraEventSink;

class SoraEventChannel {
public:
  static std::shared_ptr<SoraEventChannel> Create(const std::string& name, void* messenger, void* codec);
  virtual void SetStreamHandler(const std::function<void (const SoraEventSink&)>& f) = 0;
};

}

#endif
