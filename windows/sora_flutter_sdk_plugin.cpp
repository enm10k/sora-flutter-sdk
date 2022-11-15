#include "sora_flutter_sdk_plugin.h"

#ifdef _WIN32
// This must be included before many other Windows headers.
#include <windows.h>
#endif

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

#include "config_reader.h"

namespace sora_flutter_sdk {

// static
void SoraFlutterSdkPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrar *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "sora_flutter_sdk",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<SoraFlutterSdkPlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

SoraFlutterSdkPlugin::SoraFlutterSdkPlugin(flutter::PluginRegistrar * registrar)
  : messenger_(registrar->messenger())
  , texture_registrar_(registrar->texture_registrar())
#ifdef _WIN32
  , init_(
      webrtc::ScopedCOMInitializer::kMTA)
#endif
{
  if (!init_.Succeeded()) {
    std::cerr << "CoInitializeEx failed" << std::endl;
    return;
  }

  // rtc::LogMessage::LogToDebug(rtc::LS_INFO);
  // rtc::LogMessage::LogTimestamps();
  // rtc::LogMessage::LogThreads();
}

SoraFlutterSdkPlugin::~SoraFlutterSdkPlugin() {}

static int64_t get_as_integer(const flutter::EncodableMap& map, const std::string& key) {
  for (auto it : map) {
    if (key == std::get<std::string>(it.first)) {
      if (std::holds_alternative<int64_t>(it.second)) {
        return std::get<int64_t>(it.second);
      } else if (std::holds_alternative<int32_t>(it.second)) {
        return std::get<int32_t>(it.second);
      }
      return -1;
    }
  }
  return -1;
}

void SoraFlutterSdkPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("createSoraClient") == 0) {
    if (!method_call.arguments()) {
      result->Error("Bad Arguments", "Null constraints arguments received");
      return;
    }
    const flutter::EncodableMap req =
        std::get<flutter::EncodableMap>(*method_call.arguments());

    std::string event_channel = "SoraFlutterSdk/SoraClient/Event/" + std::to_string(client_id_);

    SoraClientConfig config;
    std::string json = std::get<std::string>(req.at(flutter::EncodableValue("config")));
    config = JsonToClientConfig(json);
    config.signaling_config = JsonToSignalingConfig(json);
    config.event_channel = event_channel;
    config.messenger = messenger_;
    config.texture_registrar = texture_registrar_;
    auto client = sora::CreateSoraClient<SoraClient>(config);
    clients_.insert(std::make_pair(client_id_, client));

    flutter::EncodableMap resp;
    resp[flutter::EncodableValue("client_id")] = flutter::EncodableValue(client_id_);
    resp[flutter::EncodableValue("event_channel")] = flutter::EncodableValue(event_channel);

    client_id_ += 1;

    result->Success(resp);
  } else if (method_call.method_name().compare("connectSoraClient") == 0) {
    if (!method_call.arguments()) {
      result->Error("Bad Arguments", "Null constraints arguments received");
      return;
    }
    const flutter::EncodableMap params =
        std::get<flutter::EncodableMap>(*method_call.arguments());
    int client_id = (int)get_as_integer(params, "client_id");
    auto it = clients_.find(client_id);
    if (it == clients_.end()) {
      result->Error("Client Not Found", "");
      return;
    }

    it->second->Connect();
    result->Success();
  } else if (method_call.method_name().compare("disposeSoraClient") == 0) {
    if (!method_call.arguments()) {
      result->Error("Bad Arguments", "Null constraints arguments received");
      return;
    }
    const flutter::EncodableMap params =
        std::get<flutter::EncodableMap>(*method_call.arguments());
    int client_id = (int)get_as_integer(params, "client_id");
    auto it = clients_.find(client_id);
    if (it == clients_.end()) {
      result->Success();
      return;
    }

    it->second->Disconnect();
    result->Success();
  } else if (method_call.method_name().compare("destroySoraClient") == 0) {
    if (!method_call.arguments()) {
      result->Error("Bad Arguments", "Null constraints arguments received");
      return;
    }
    const flutter::EncodableMap params =
        std::get<flutter::EncodableMap>(*method_call.arguments());
    int client_id = (int)get_as_integer(params, "client_id");
    auto it = clients_.find(client_id);
    if (it == clients_.end()) {
      result->Success();
      return;
    }

    it->second->Destroy();
    clients_.erase(it);
    result->Success();
  } else if (method_call.method_name().compare("sendDataChannel") == 0) {
    if (!method_call.arguments()) {
      result->Error("Bad Arguments", "Null constraints arguments received");
      return;
    }
    const flutter::EncodableMap params =
        std::get<flutter::EncodableMap>(*method_call.arguments());
    int client_id = (int)get_as_integer(params, "client_id");
    auto it = clients_.find(client_id);
    if (it == clients_.end()) {
      result->Success();
      return;
    }

    std::string label = std::get<std::string>(params.at(flutter::EncodableValue("label")));
    std::string data = std::get<std::string>(params.at(flutter::EncodableValue("data")));
    bool status = it->second->SendDataChannel(label, data);
    auto resp = flutter::EncodableValue(status);
    result->Success(resp);
  } else {
    result->NotImplemented();
  }
}

}  // namespace sora_flutter_sdk
