#include "include/sora_flutter_sdk/sora_flutter_sdk_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "sora_flutter_sdk_plugin.h"

void SoraFlutterSdkPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  sora_flutter_sdk::SoraFlutterSdkPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
