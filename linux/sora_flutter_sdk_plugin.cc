#include "include/sora_flutter_sdk/sora_flutter_sdk_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>
#include <string>
#include <iostream>

#include "sora_client.h"
#include "config_reader.h"

#define SORA_FLUTTER_SDK_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), sora_flutter_sdk_plugin_get_type(), \
                              SoraFlutterSdkPlugin))

struct SoraFlutterSdkPluginData {
  int client_id = 1;
  std::map<int, std::shared_ptr<sora_flutter_sdk::SoraClient>> clients;
};

struct _SoraFlutterSdkPlugin {
  GObject parent_instance;
  void* data;
  FlBinaryMessenger* messenger;
  FlTextureRegistrar* texture_registrar;
};

G_DEFINE_TYPE(SoraFlutterSdkPlugin, sora_flutter_sdk_plugin, g_object_get_type())

std::string get_as_string(FlValue* value, const std::string& key) {
  FlValue* val = fl_value_lookup_string(value, key.c_str());
  return fl_value_get_string(val);
}

int64_t get_as_integer(FlValue* value, const std::string& key) {
  FlValue* val = fl_value_lookup_string(value, key.c_str());
  return fl_value_get_int(val);
}

// Called when a method call is received from Flutter.
static void sora_flutter_sdk_plugin_handle_method_call(
    SoraFlutterSdkPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);
  auto data = (SoraFlutterSdkPluginData*)self->data;

  if (strcmp(method, "createSoraClient") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    if (args == nullptr) {
      fl_method_call_respond_error(method_call, "Bad Arguments", "Null constraints arguments received", nullptr, nullptr);
      return;
    }

    std::string event_channel = "SoraFlutterSdk/SoraClient/Event/" + std::to_string(data->client_id);

    sora_flutter_sdk::SoraClientConfig config;
    std::string json = get_as_string(args, "config");
    config = sora_flutter_sdk::JsonToClientConfig(json);
    config.signaling_config = sora_flutter_sdk::JsonToSignalingConfig(json);
    config.event_channel = event_channel;
    config.messenger = self->messenger;
    config.texture_registrar = self->texture_registrar;
    auto client = sora::CreateSoraClient<sora_flutter_sdk::SoraClient>(config);
    data->clients.insert(std::make_pair(data->client_id, client));

    g_autoptr(FlValue) resp = fl_value_new_map();
    fl_value_set_string_take(resp, "client_id", fl_value_new_int(data->client_id));
    fl_value_set_string_take(resp, "event_channel", fl_value_new_string(event_channel.c_str()));

    data->client_id += 1;

    fl_method_call_respond_success(method_call, resp, nullptr);
  } else if (strcmp(method, "connectSoraClient") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    if (args == nullptr) {
      fl_method_call_respond_error(method_call, "Bad Arguments", "Null constraints arguments received", nullptr, nullptr);
      return;
    }

    int client_id = (int)get_as_integer(args, "client_id");
    auto it = data->clients.find(client_id);
    if (it == data->clients.end()) {
      fl_method_call_respond_error(method_call, "Client Not Found", "", nullptr, nullptr);
      return;
    }

    it->second->Connect();
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "disposeSoraClient") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    if (args == nullptr) {
      fl_method_call_respond_error(method_call, "Bad Arguments", "Null constraints arguments received", nullptr, nullptr);
      return;
    }

    int client_id = (int)get_as_integer(args, "client_id");
    auto it = data->clients.find(client_id);
    if (it == data->clients.end()) {
      fl_method_call_respond_success(method_call, nullptr, nullptr);
      return;
    }

    it->second->Disconnect();
    data->clients.erase(it);
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "sendDataChannel") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    if (args == nullptr) {
      fl_method_call_respond_error(method_call, "Bad Arguments", "Null constraints arguments received", nullptr, nullptr);
      return;
    }

    int client_id = (int)get_as_integer(args, "client_id");
    auto it = data->clients.find(client_id);
    if (it == data->clients.end()) {
      fl_method_call_respond_success(method_call, nullptr, nullptr);
      return;
    }

    std::string label = get_as_string(args, "label");
    std::string data = get_as_string(args, "data");
    bool status = it->second->SendDataChannel(label, data);
    g_autoptr(FlValue) resp = fl_value_new_bool(status);

    fl_method_call_respond_success(method_call, resp, nullptr);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    fl_method_call_respond(method_call, response, nullptr);
  }
}

static void sora_flutter_sdk_plugin_dispose(GObject* object) {
  auto plugin = SORA_FLUTTER_SDK_PLUGIN(object);
  delete (SoraFlutterSdkPluginData*)plugin->data;
  G_OBJECT_CLASS(sora_flutter_sdk_plugin_parent_class)->dispose(object);
}

static void sora_flutter_sdk_plugin_class_init(SoraFlutterSdkPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = sora_flutter_sdk_plugin_dispose;
}

static void sora_flutter_sdk_plugin_init(SoraFlutterSdkPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  SoraFlutterSdkPlugin* plugin = SORA_FLUTTER_SDK_PLUGIN(user_data);
  sora_flutter_sdk_plugin_handle_method_call(plugin, method_call);
}

void sora_flutter_sdk_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  //rtc::LogMessage::LogToDebug(rtc::LS_INFO);
  //rtc::LogMessage::LogTimestamps();
  //rtc::LogMessage::LogThreads();

  SoraFlutterSdkPlugin* plugin = SORA_FLUTTER_SDK_PLUGIN(
      g_object_new(sora_flutter_sdk_plugin_get_type(), nullptr));
  plugin->data = new SoraFlutterSdkPluginData();
  plugin->messenger = fl_plugin_registrar_get_messenger(registrar);
  plugin->texture_registrar = fl_plugin_registrar_get_texture_registrar(registrar);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "sora_flutter_sdk",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
