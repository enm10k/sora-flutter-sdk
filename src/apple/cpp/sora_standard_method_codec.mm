#import "sora_standard_method_codec.h"

#import "../SoraBase.h"

namespace sora_flutter_sdk {

FlutterStandardMethodCodec* GetStandardMethodCodec() {
  return [FlutterStandardMethodCodec sharedInstance];
}

}
