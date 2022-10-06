# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.18)

# Project-level configuration.
set(PROJECT_NAME "sora_flutter_sdk")
project(${PROJECT_NAME} LANGUAGES CXX)

set(WEBRTC_INCLUDE_DIR ${CMAKE_BINARY_DIR}/webrtc/include)
set(WEBRTC_LIBRARY_NAME webrtc)
set(WEBRTC_LIBRARY_DIR ${CMAKE_BINARY_DIR}/webrtc/lib)
if (NOT EXISTS "${WEBRTC_LIBRARY_DIR}")
  message("Download and extracting webrtc.windows_x86_64.m105.5195.0.0.zip")
  file(DOWNLOAD https://github.com/shiguredo-webrtc-build/webrtc-build/releases/download/m105.5195.0.0/webrtc.windows_x86_64.zip ${CMAKE_BINARY_DIR}/webrtc.windows_x86_64.m105.5195.0.0.zip)
  file(ARCHIVE_EXTRACT INPUT ${CMAKE_BINARY_DIR}/webrtc.windows_x86_64.m105.5195.0.0.zip DESTINATION ${CMAKE_BINARY_DIR})

  # Dart はロングパスをサポートしていない (https://github.com/dart-lang/sdk/issues/27825) ため、
  # ディレクトリが奥深くまであるディレクトリは削除する。
  file(REMOVE_RECURSE ${CMAKE_BINARY_DIR}/webrtc/include/examples)
  file(REMOVE_RECURSE ${CMAKE_BINARY_DIR}/webrtc/include/buildtools)
endif()

set(BOOST_ROOT ${CMAKE_BINARY_DIR}/boost)
if (NOT EXISTS "${BOOST_ROOT}")
  message("Download and extracting boost-1.80.0_sora-cpp-sdk-2022.11.0_windows_x86_64.zip")
  file(DOWNLOAD https://github.com/shiguredo/sora-cpp-sdk/releases/download/2022.11.0/boost-1.80.0_sora-cpp-sdk-2022.11.0_windows_x86_64.zip ${CMAKE_BINARY_DIR}/boost-1.80.0_sora-cpp-sdk-2022.11.0_windows_x86_64.zip)
  file(ARCHIVE_EXTRACT INPUT ${CMAKE_BINARY_DIR}/boost-1.80.0_sora-cpp-sdk-2022.11.0_windows_x86_64.zip DESTINATION ${CMAKE_BINARY_DIR})
endif()

set(SORA_DIR ${CMAKE_BINARY_DIR}/sora)
if (NOT EXISTS "${SORA_DIR}")
  message("Download and extracting sora-cpp-sdk-2022.11.0_windows_x86_64.zip")
  file(DOWNLOAD https://github.com/shiguredo/sora-cpp-sdk/releases/download/2022.11.0/sora-cpp-sdk-2022.11.0_windows_x86_64.zip ${CMAKE_BINARY_DIR}/sora-cpp-sdk-2022.11.0_windows_x86_64.zip)
  file(ARCHIVE_EXTRACT INPUT ${CMAKE_BINARY_DIR}/sora-cpp-sdk-2022.11.0_windows_x86_64.zip DESTINATION ${CMAKE_BINARY_DIR})
endif()

list(APPEND CMAKE_PREFIX_PATH ${SORA_DIR})
list(APPEND CMAKE_MODULE_PATH ${SORA_DIR}/share/cmake)

set(Boost_USE_STATIC_LIBS ON)
set(Boost_USE_STATIC_RUNTIME ON)
set(Boost_NO_BOOST_CMAKE ON)
set(Boost_NO_SYSTEM_PATHS ON)
set(BOOST_LIBRARYDIR ${BOOST_ROOT}/lib)
find_package(Boost REQUIRED COMPONENTS json)
find_package(WebRTC REQUIRED)
find_package(Sora REQUIRED)

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
