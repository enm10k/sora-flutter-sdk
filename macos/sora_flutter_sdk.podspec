#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint sora_flutter_sdk.podspec` to validate before publishing.
#

sdk_dir = "_install"

Pod::Spec.new do |s|
  s.name = "sora_flutter_sdk"
  s.version  = '2022.1.0-canary.10'
  s.summary  = 'Sora Flutter SDK.'
  s.description = <<-DESC
  A library to develop Web RTC SFU Sora(https://sora.shiguredo.jp/) client applications.
                       DESC
  s.homepage = 'https://github.com/shiguredo/sora-flutter-sdk'
  s.license  = { :type => "Apache License, Version 2.0" }
  s.authors  = { "Shiguredo Inc." => "https://shiguredo.jp/" }
  s.source   = {
      :git => "https://github.com/shiguredo/sora-flutter-sdk.git",
      :tag => s.version
  }
  s.source_files = ["Classes/**/*", "src/**/*"]
  s.public_header_files = [
    "Classes/SoraBase.h",
    "Classes/SoraFlutterMessageHandler.h",
  ]

  s.vendored_libraries = [
    "#{sdk_dir}/sora/lib/libsora.a",
    "#{sdk_dir}/webrtc/lib/libwebrtc.a",
    "#{sdk_dir}/boost/lib/libboost_container.a",
    "#{sdk_dir}/boost/lib/libboost_json.a",
  ]

  s.user_target_xcconfig = {
    "EXCLUDED_ARCHS[sdk=macosx*]" => "x86_64",
  }

  s.pod_target_xcconfig = {
    "DEFINES_MODULE" => "YES",
    "EXCLUDED_ARCHS[sdk=macosx*]" => "x86_64",
    "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES" => "YES",
    "HEADER_SEARCH_PATHS" => '"$(inherited)" ' +
                             "\"$(PODS_TARGET_SRCROOT)/#{sdk_dir}/sora/include\" " +
                             "\"$(PODS_TARGET_SRCROOT)/#{sdk_dir}/webrtc/include\" " +
                             "\"$(PODS_TARGET_SRCROOT)/#{sdk_dir}/webrtc/include/third_party/abseil-cpp\" " +
                             "\"$(PODS_TARGET_SRCROOT)/#{sdk_dir}/webrtc/include/third_party/boringssl/src/include\" " +
                             "\"$(PODS_TARGET_SRCROOT)/#{sdk_dir}/webrtc/include/third_party/libyuv/include\" " +
                             "\"$(PODS_TARGET_SRCROOT)/#{sdk_dir}/webrtc/include/sdk/objc\" " +
                             "\"$(PODS_TARGET_SRCROOT)/#{sdk_dir}/webrtc/include/sdk/objc/base\" " +
                             "\"$(PODS_TARGET_SRCROOT)/#{sdk_dir}/boost/include\" ",
    "CLANG_CXX_LANGUAGE_STANDARD" => "gnu++17",
    "GCC_PREPROCESSOR_DEFINITIONS" => "WEBRTC_MAC=1 WEBRTC_POSIX=1 OPENSSL_IS_BORINGSSL=1 NDEBUG",
    "OTHER_LDFLAGS" => "-ObjC",
    "OTHER_CPLUSPLUSFLAGS" => "-x objective-c++",
  }

  s.framework = [
    "AVFoundation",
    "AudioToolbox",
    "CoreAudio",
    "QuartzCore",
    "CoreMedia",
    "VideoToolbox",
    "AppKit",
    "Metal",
    "MetalKit",
    "OpenGL",
    "IOSurface",
  ]

  s.dependency "FlutterMacOS"

  s.platform = :osx, "10.12"
  s.osx.deployment_target = "10.12"

  s.prepare_command = <<-CMD
    ../scripts/apple/setup_macos.sh
  CMD
end
