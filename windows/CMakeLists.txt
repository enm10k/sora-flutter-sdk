# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.18)

# Project-level configuration.
set(PROJECT_NAME "sora_flutter_sdk")
project(${PROJECT_NAME} LANGUAGES CXX)

set(WEBRTC_VERSION "m111.5563.4.4")
set(SORA_VERSION "2023.3.0")
set(BOOST_VERSION "1.81.0")
set(LYRA_VERSION "1.3.0")

message("CMAKE_VERRSION: ${CMAKE_VERSION}")
message("WEBRTC_VERSION: ${WEBRTC_VERSION}")
message("SORA_VERSION: ${SORA_VERSION}")
message("BOOST_VERSION: ${BOOST_VERSION}")
message("LYRA_VERSION: ${LYRA_VERSION}")

message("CMAKE_BINARY_DIR: ${CMAKE_BINARY_DIR}")

set(WEBRTC_INCLUDE_DIR ${CMAKE_BINARY_DIR}/webrtc/include)
set(WEBRTC_LIBRARY_NAME webrtc)
set(WEBRTC_LIBRARY_DIR ${CMAKE_BINARY_DIR}/webrtc/lib)
message("WEBRTC_INCLUDE_DIR: ${WEBRTC_INCLUDE_DIR}")
if (NOT EXISTS "${WEBRTC_LIBRARY_DIR}")
  message("Download and extracting webrtc.windows_x86_64.${WEBRTC_VERSION}.zip")
  file(DOWNLOAD https://github.com/shiguredo-webrtc-build/webrtc-build/releases/download/${WEBRTC_VERSION}/webrtc.windows_x86_64.zip ${CMAKE_BINARY_DIR}/webrtc.windows_x86_64.${WEBRTC_VERSION}.zip)
  file(ARCHIVE_EXTRACT INPUT ${CMAKE_BINARY_DIR}/webrtc.windows_x86_64.${WEBRTC_VERSION}.zip DESTINATION ${CMAKE_BINARY_DIR})

  # Dart はロングパスをサポートしていない (https://github.com/dart-lang/sdk/issues/27825) ため、
  # ディレクトリが奥深くまであるディレクトリは削除する。
  file(REMOVE_RECURSE ${CMAKE_BINARY_DIR}/webrtc/include/examples)
  file(REMOVE_RECURSE ${CMAKE_BINARY_DIR}/webrtc/include/buildtools)
endif()

set(BOOST_ROOT ${CMAKE_BINARY_DIR}/boost)
message("BOOST_ROOT: ${BOOST_ROOT}")
if (NOT EXISTS "${BOOST_ROOT}")
  message("Download and extracting boost-${BOOST_VERSION}_sora-cpp-sdk-${SORA_VERSION}_windows_x86_64.zip")
  file(DOWNLOAD https://github.com/shiguredo/sora-cpp-sdk/releases/download/${SORA_VERSION}/boost-${BOOST_VERSION}_sora-cpp-sdk-${SORA_VERSION}_windows_x86_64.zip ${CMAKE_BINARY_DIR}/boost-${BOOST_VERSION}_sora-cpp-sdk-${SORA_VERSION}_windows_x86_64.zip)
  file(ARCHIVE_EXTRACT INPUT ${CMAKE_BINARY_DIR}/boost-${BOOST_VERSION}_sora-cpp-sdk-${SORA_VERSION}_windows_x86_64.zip DESTINATION ${CMAKE_BINARY_DIR})
endif()

set(SORA_DIR ${CMAKE_BINARY_DIR}/sora)
message("SORA_DIR: ${SORA_DIR}")
if (NOT EXISTS "${SORA_DIR}")
  message("Download and extracting sora-cpp-sdk-${SORA_VERSION}_windows_x86_64.zip")
  file(DOWNLOAD https://github.com/shiguredo/sora-cpp-sdk/releases/download/${SORA_VERSION}/sora-cpp-sdk-${SORA_VERSION}_windows_x86_64.zip ${CMAKE_BINARY_DIR}/sora-cpp-sdk-${SORA_VERSION}_windows_x86_64.zip)
  file(ARCHIVE_EXTRACT INPUT ${CMAKE_BINARY_DIR}/sora-cpp-sdk-${SORA_VERSION}_windows_x86_64.zip DESTINATION ${CMAKE_BINARY_DIR})
endif()

set(LYRA_DIR ${CMAKE_BINARY_DIR}/lyra)
message("LYRA_DIR: ${LYRA_DIR}")
if (NOT EXISTS "${LYRA_DIR}")
  message("Download and extracting lyra-${LYRA_VERSION}_sora-cpp-sdk-${SORA_VERSION}_windows_x86_64.zip")
  file(DOWNLOAD https://github.com/shiguredo/sora-cpp-sdk/releases/download/${SORA_VERSION}/lyra-${LYRA_VERSION}_sora-cpp-sdk-${SORA_VERSION}_windows_x86_64.zip ${CMAKE_BINARY_DIR}/lyra-${LYRA_VERSION}_sora-cpp-sdk-${SORA_VERSION}_windows_x86_64.zip)
  file(ARCHIVE_EXTRACT INPUT ${CMAKE_BINARY_DIR}/lyra-${LYRA_VERSION}_sora-cpp-sdk-${SORA_VERSION}_windows_x86_64.zip DESTINATION ${CMAKE_BINARY_DIR})
endif()


file(STRINGS ${CMAKE_BINARY_DIR}/../../.dart_tool/package_config.json PKG_CONFIG)
string(STRIP "${PKG_CONFIG}" PKG_CONFIG_LINE)
string(REGEX MATCH "\"name\":[ ]*\"sora_flutter_sdk\",[ ]*;[ ]*\"rootUri\":[ ]*\"([^\"]+)\"" _ "${PKG_CONFIG_LINE}")
set(SDK_PATH ${CMAKE_MATCH_1})
message("Sora Flutter SDK path: ${SDK_PATH}")

if (IS_ABSOLUTE ${SDK_PATH})
  set(LYRA_MODEL_ASSET_DIR ${SDK_PATH}/assets/lyra/model_coeffs)
else()
  get_filename_component(SDK_REAL_PATH ${SDK_PATH} REALPATH)
  message("Sora Flutter SDK real path: ${SDK_REAL_PATH}")
  set(LYRA_MODEL_ASSET_DIR ${SDK_REAL_PATH}/sora_flutter_sdk/assets/lyra/model_coeffs)
endif()

set(LYRA_MODEL_SRC_DIR ${LYRA_DIR}/share/model_coeffs)
message("Copy Lyra model files to ${LYRA_MODEL_ASSET_DIR}")
file(COPY ${LYRA_MODEL_SRC_DIR}/lyra_config.binarypb DESTINATION ${LYRA_MODEL_ASSET_DIR})
file(COPY ${LYRA_MODEL_SRC_DIR}/lyragan.tflite DESTINATION ${LYRA_MODEL_ASSET_DIR})
file(COPY ${LYRA_MODEL_SRC_DIR}/quantizer.tflite DESTINATION ${LYRA_MODEL_ASSET_DIR})
file(COPY ${LYRA_MODEL_SRC_DIR}/soundstream_encoder.tflite DESTINATION ${LYRA_MODEL_ASSET_DIR})
file(COPY ${LYRA_MODEL_SRC_DIR}/test_playback.wav DESTINATION ${LYRA_MODEL_ASSET_DIR})

list(APPEND CMAKE_PREFIX_PATH ${SORA_DIR})
list(APPEND CMAKE_MODULE_PATH ${SORA_DIR}/share/cmake)

set(Boost_USE_STATIC_LIBS ON)
set(Boost_USE_STATIC_RUNTIME ON)

# ローカルマシンにインストールされた Boost を参照しないようにする以下の設定は
# Windows では set(Boost_NO_BOOST_CMAKE ON) を設定するとエラーになるため設定しない。
# なお、Windows は以下の設定がなくとも正常にダウンロードした Boost を参照する。
# set(Boost_NO_BOOST_CMAKE ON)
# set(Boost_NO_SYSTEM_PATHS ON)
# set(BOOST_LIBRARYDIR ${BOOST_ROOT}/lib)

find_package(Boost REQUIRED COMPONENTS json filesystem)
find_package(WebRTC REQUIRED)
find_package(Sora REQUIRED)
find_package(Lyra REQUIRED)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "sora_flutter_sdk_plugin")

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "sora_flutter_sdk_plugin.cpp"
  "sora_flutter_sdk_plugin.h"
  "../src/sora_client.cpp"
  "../src/sora_client.h"
  "../src/sora_renderer.cpp"
  "../src/sora_renderer.h"
  "../src/device_list.h"
  "../src/device_list.cpp"
)

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
add_library(${PLUGIN_NAME} SHARED
  "include/sora_flutter_sdk/sora_flutter_sdk_plugin_c_api.h"
  "sora_flutter_sdk_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

target_compile_options(${PLUGIN_NAME} PRIVATE /utf-8 /bigobj)
set_target_properties(${PLUGIN_NAME}
  PROPERTIES
    # CRTライブラリを静的リンクさせる
    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
)

target_compile_definitions(${PLUGIN_NAME}
  PRIVATE
    _CONSOLE
    _WIN32_WINNT=0x0A00
    NOMINMAX
    WIN32_LEAN_AND_MEAN
    UNICODE
    _UNICODE
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/../src")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin Sora::sora)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(sora_flutter_sdk_bundled_libraries
  ""
  PARENT_SCOPE
)
