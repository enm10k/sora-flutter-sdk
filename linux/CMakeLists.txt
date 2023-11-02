# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

message("CMAKE_VERRSION: ${CMAKE_VERSION}")
message("CMAKE_BINARY_DIR: ${CMAKE_BINARY_DIR}")

set(INSTALL_DIR ${CMAKE_SOURCE_DIR}/_install)
set(WEBRTC_INCLUDE_DIR ${INSTALL_DIR}/webrtc/include)
set(WEBRTC_LIBRARY_NAME webrtc)
set(WEBRTC_LIBRARY_DIR ${INSTALL_DIR}/webrtc/lib)
set(BOOST_ROOT ${INSTALL_DIR}/boost)
set(SORA_DIR ${INSTALL_DIR}/sora)
set(LYRA_DIR ${INSTALL_DIR}/lyra)
set(LIBCXX_DIR ${INSTALL_DIR}/llvm/libcxx)

#set(CMAKE_C_COMPILER ${LLVM_DIR}/clang/bin/clang)
#set(CMAKE_CXX_COMPILER ${LLVM_DIR}/clang/bin/clang++)
#set(CMAKE_CXX_FLAGS "-nostdinc++ -isystem ${LLVM_DIR}/libcxx/include -std=gnu++17")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated-declarations")

# Project-level configuration.
set(PROJECT_NAME "sora_flutter_sdk")
project(${PROJECT_NAME} LANGUAGES CXX)

list(APPEND CMAKE_PREFIX_PATH ${SORA_DIR})
list(APPEND CMAKE_MODULE_PATH ${SORA_DIR}/share/cmake)

set(Boost_USE_STATIC_LIBS ON)

# ローカルマシンにインストールされた Boost を参照しない設定
# 以下リンクの stack overflow の内容を参考にしている
# https://stackoverflow.com/questions/3016448/how-can-i-get-cmake-to-find-my-alternative-boost-installation
set(Boost_NO_BOOST_CMAKE ON)
set(Boost_NO_SYSTEM_PATHS ON)
set(BOOST_LIBRARYDIR ${BOOST_ROOT}/lib)

find_package(Boost REQUIRED COMPONENTS json filesystem)
find_package(WebRTC REQUIRED)
find_package(Sora REQUIRED)
find_package(Lyra REQUIRED)
find_package(Threads REQUIRED)
find_package(Libdrm REQUIRED)
find_package(Libva REQUIRED)

# This value is used when generating builds using this plugin, so it must
# not be changed.
set(PLUGIN_NAME "sora_flutter_sdk_plugin")

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
#
# Any new source files that you add to the plugin should be added here.
add_library(${PLUGIN_NAME} SHARED
  "sora_flutter_sdk_plugin.cc"
  "../src/sora_client.cpp"
  "../src/sora_client.h"
  "../src/sora_renderer.cpp"
  "../src/sora_renderer.h"
  "../src/device_list.h"
  "../src/device_list.cpp"
  "../src/config_reader.h"
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
target_compile_definitions(${PLUGIN_NAME}
  PRIVATE
    WEBRTC_POSIX
    _LIBCPP_ABI_NAMESPACE=Cr
    _LIBCPP_ABI_VERSION=2
    _LIBCPP_DISABLE_AVAILABILITY
    OPENSSL_IS_BORINGSSL
)
target_compile_options(${PLUGIN_NAME}
  PRIVATE
    -nostdinc++
    -isystem${LIBCXX_DIR}/include
    -std=gnu++17
)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/../src")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter Sora::sora)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)


# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(sora_flutter_sdk_bundled_libraries
  ""
  PARENT_SCOPE
)


# Lyra モデルファイルをアセットにコピー
file(STRINGS ${CMAKE_BINARY_DIR}/../../../../.dart_tool/package_config.json PKG_CONFIG)
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
