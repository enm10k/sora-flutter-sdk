#ifndef SORA_FLUTTER_SDK_SORA_IOS_AUDIO_INIT_H_
#define SORA_FLUTTER_SDK_SORA_IOS_AUDIO_INIT_H_

#include <functional>
#include <string>

namespace sora_flutter_sdk {

void IosAudioInit(std::function<void(std::string)> on_complete);

}

#endif
