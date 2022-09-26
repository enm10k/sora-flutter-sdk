#ifndef FLUTTER_PLUGIN_SORA_FLUTTER_SDK_PLUGIN_H_
#define FLUTTER_PLUGIN_SORA_FLUTTER_SDK_PLUGIN_H_

#ifdef _WIN32
#include <rtc_base/win/scoped_com_initializer.h>
#endif

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "sora_client.h"

namespace sora_flutter_sdk {

class SoraFlutterSdkPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar *registrar);

  SoraFlutterSdkPlugin(flutter::PluginRegistrar* registrar);

  virtual ~SoraFlutterSdkPlugin();

  // Disallow copy and assign.
  SoraFlutterSdkPlugin(const SoraFlutterSdkPlugin&) = delete;
  SoraFlutterSdkPlugin& operator=(const SoraFlutterSdkPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  webrtc::ScopedCOMInitializer init_;

  flutter::BinaryMessenger *messenger_;
  flutter::TextureRegistrar *texture_registrar_;
  int client_id_ = 1;
  std::map<int, std::shared_ptr<SoraClient>> clients_;
};

}  // namespace sora_flutter_sdk

#endif  // FLUTTER_PLUGIN_SORA_FLUTTER_SDK_PLUGIN_H_
