#ifndef SORA_FLUTTER_SDK_CONFIG_READER_H_
#define SORA_FLUTTER_SDK_CONFIG_READER_H_

#include <string>

// Boost
#include <boost/json.hpp>

// Sora C++ SDK
#include <sora/sora_signaling.h>
#include <sora/camera_device_capturer.h>

#include "sora_client.h"

namespace sora_flutter_sdk {

static bool FindKey(const boost::json::value& v, const std::string& key, boost::json::value& a, std::string& error) {
  if (!v.is_object()) {
    error = "root is not object";
    return false;
  }
  auto it = v.as_object().find(key);
  if (it == v.as_object().end()) {
    error = "'" + key + "' not found";
    return false;
  }
  a = it->value();
  return true;
}

template<class T>
static bool SetStringArray(const boost::json::value& v, const std::string& key, T* p, std::string& error) {
  boost::json::value a;
  if (!FindKey(v, key, a, error)) {
    return false;
  }

  // null はただの未指定なので許可する
  if (a.is_null()) {
    return true;
  }
  if (!a.is_array()) {
    error = "'" + key + "' type is not array";
    return false;
  }
  std::vector<std::string> r;
  for (const auto& x : a.as_array()) {
    if (!x.is_string()) {
      error = "'" + key + "[n]' type is not string";
      return false;
    }
    r.push_back(x.as_string().c_str());
  }
  *p = r;
  return true;
}

template<class T>
static bool SetString(const boost::json::value& v, const std::string& key, T* p, std::string& error) {
  boost::json::value a;
  if (!FindKey(v, key, a, error)) {
    return false;
  }

  if (a.is_null()) {
    return true;
  }
  if (!a.is_string()) {
    error = "'" + key + "' type is not string";
    return false;
  }
  *p = a.as_string().c_str();
  return true;
}

template<class T>
static bool SetInteger(const boost::json::value& v, const std::string& key, T* p, std::string& error) {
  boost::json::value a;
  if (!FindKey(v, key, a, error)) {
    return false;
  }

  if (a.is_null()) {
    return true;
  }
  if (!a.is_number()) {
    error = "'" + key + "' type is not number";
    return false;
  }
  std::error_code ec;
  *p = (T)a.to_number<int64_t>(ec);
  if (ec) {
    error = ec.message();
    return false;
  }
  return true;
}

template<class T>
static bool SetBoolean(const boost::json::value& v, const std::string& key, T* p, std::string& error) {
  boost::json::value a;
  if (!FindKey(v, key, a, error)) {
    return false;
  }

  if (a.is_null()) {
    return true;
  }
  if (!a.is_bool()) {
    error = "'" + key + "' type is not bool";
    return false;
  }
  *p = a.as_bool();
  return true;
}

template<class T>
static bool SetJson(const boost::json::value& v, const std::string& key, T* p, std::string& error) {
  boost::json::value a;
  if (!FindKey(v, key, a, error)) {
    return false;
  }

  if (a.is_null()) {
    return true;
  }
  *p = a;
  return true;
}

sora::SoraSignalingConfig JsonToSignalingConfig(const std::string& json) {
  boost::json::value v = boost::json::parse(json);
  sora::SoraSignalingConfig c;
  std::vector<std::string> errors;
#define F(func, name, field) \
  if (std::string error; !func(v, name, field, error)) \
    errors.push_back(error)

  F(SetStringArray, "signalingUrls", &c.signaling_urls);
  F(SetString, "channelId", &c.channel_id);
  F(SetString, "clientId", &c.client_id);
  F(SetString, "bundleId", &c.bundle_id);

  F(SetString, "soraClient", &c.sora_client);

  F(SetBoolean, "insecure", &c.insecure);
  F(SetBoolean, "video", &c.video);
  F(SetBoolean, "audio", &c.audio);
  F(SetString, "videoCodecType", &c.video_codec_type);
  F(SetString, "audioCodecType", &c.audio_codec_type);
  F(SetInteger, "videoBitRate", &c.video_bit_rate);
  F(SetInteger, "audioBitRate", &c.audio_bit_rate);
  /*
  if (c.audio_codec_type == "LYRA") {
    F(SetJson, "audioCodecLyraParams", &c.audio_codec_lyra_params);
  }
  */
  F(SetString, "audioStreamingLanguageCode", &c.audio_streaming_language_code);
  F(SetJson, "metadata", &c.metadata);
  F(SetJson, "signalingNotifyMetadata", &c.signaling_notify_metadata);
  F(SetString, "role", &c.role);
  F(SetBoolean, "multistream", &c.multistream);
  F(SetBoolean, "spotlight", &c.spotlight);
  F(SetInteger, "spotlightNumber", &c.spotlight_number);
  F(SetString, "spotlightFocusRid", &c.spotlight_focus_rid);
  F(SetString, "spotlightUnfocusRid", &c.spotlight_unfocus_rid);
  F(SetBoolean, "simulcast", &c.simulcast);
  F(SetString, "simulcastRid", &c.simulcast_rid);
  F(SetBoolean, "dataChannelSignaling", &c.data_channel_signaling);
  F(SetInteger, "dataChannelSignalingTimeout", &c.data_channel_signaling_timeout);
  F(SetBoolean, "ignoreDisconnectWebsocket", &c.ignore_disconnect_websocket);
  F(SetInteger, "disconnectWaitTimeout", &c.disconnect_wait_timeout);

  // dataChannels
  {
    auto f = [](const boost::json::value& v, std::vector<sora::SoraSignalingConfig::DataChannel>& dcs, std::string& error) {
      boost::json::value a;
      if (!FindKey(v, "dataChannels", a, error)) {
        return false;
      }

      if (a.is_null()) {
        return false;
      }
      if (!a.is_array()) {
        error = "'dataChannels' type is not array";
        return false;
      }
      for (const auto& x : a.as_array()) {
        if (!x.is_object()) {
          error = "'dataChannels[n]' type is not object";
          return false;
        }
        sora::SoraSignalingConfig::DataChannel dc;
        if (!SetString(x, "label", &dc.label, error)) return false;
        if (!SetString(x, "direction", &dc.direction, error)) return false;
        if (!SetBoolean(x, "ordered", &dc.ordered, error)) return false;
        if (!SetInteger(x, "maxPacketLifeTime", &dc.max_packet_life_time, error)) return false;
        if (!SetInteger(x, "maxRetransmits", &dc.max_retransmits, error)) return false;
        if (!SetString(x, "protocol", &dc.protocol, error)) return false;
        if (!SetBoolean(x, "compress", &dc.compress, error)) return false;
        dcs.push_back(std::move(dc));
      }
      return true;
    };

    if (std::string error; !f(v, c.data_channels, error)) {
      errors.push_back(error);
    }
  }

  F(SetString, "clientCert", &c.client_cert);
  F(SetString, "clientKey", &c.client_key);

  F(SetInteger, "websocketCloseTimeout", &c.websocket_close_timeout);
  F(SetInteger, "websocketConnectionTimeout", &c.websocket_connection_timeout);

  F(SetString, "proxyUrl", &c.proxy_url);
  F(SetString, "proxyUsername", &c.proxy_username);
  F(SetString, "proxyPassword", &c.proxy_password);
  F(SetString, "proxyAgent", &c.proxy_agent);

  F(SetBoolean, "disableSignalingUrlRandomization", &c.disable_signaling_url_randomization);

#undef F
  for (const auto& e : errors) {
    RTC_LOG(LS_ERROR) << e;
  }

  return c;
}

SoraClientConfig JsonToClientConfig(const std::string& json) {
  boost::json::value v = boost::json::parse(json);
  SoraClientConfig c;
  std::vector<std::string> errors;
#define F(func, name, field) \
  if (std::string error; !func(v, name, field, error)) \
    errors.push_back(error)

  F(SetBoolean, "useAudioDeivce", &c.use_audio_device);
  F(SetBoolean, "useHardwareEncoder", &c.use_hardware_encoder);
  F(SetString, "videoDeviceName", &c.video_device_name);
  F(SetInteger, "videoDeviceWidth", &c.video_device_width);
  F(SetInteger, "videoDeviceHeight", &c.video_device_height);
  F(SetInteger, "videoDeviceFps", &c.video_device_fps);

#undef F
  for (const auto& e : errors) {
    RTC_LOG(LS_ERROR) << e;
  }

  return c;
}

sora::CameraDeviceCapturerConfig JsonToCameraDeviceCapturerConfig(const std::string& json) {
  boost::json::value v = boost::json::parse(json);
  sora::CameraDeviceCapturerConfig c;
  std::vector<std::string> errors;
#define F(func, name, field) \
  if (std::string error; !func(v, name, field, error)) \
    errors.push_back(error)

  F(SetString, "name", &c.device_name);
  F(SetInteger, "width", &c.width);
  F(SetInteger, "height", &c.height);
  F(SetInteger, "fps", &c.fps);

#undef F
  for (const auto& e : errors) {
    RTC_LOG(LS_ERROR) << e;
  }

  return c;
}

}
#endif