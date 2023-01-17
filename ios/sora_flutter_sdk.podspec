sdk_dir = "_install"

Pod::Spec.new do |s|
  s.name = 'sora_flutter_sdk'
  s.version  = '2022.1.0-canary.10'
  s.summary  = 'Sora Flutter SDK.'
  s.description  = <<-DESC
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
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.public_header_files = [
    "Classes/SoraBase.h",
    "Classes/SoraFlutterMessageHandler.h",
    "Classes/SoraFlutterSdkPlugin.h",
  ]

  s.vendored_libraries = [
    "#{sdk_dir}/sora/lib/libsora.a",
    "#{sdk_dir}/webrtc/lib/libwebrtc.a",
    "#{sdk_dir}/boost/lib/libboost_container.a",
    "#{sdk_dir}/boost/lib/libboost_json.a",
  ]

  s.pod_target_xcconfig = {
    "DEFINES_MODULE" => "YES",

    # Flutter.framework does not contain a i386 slice.
    "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "i386",

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
    "GCC_PREPROCESSOR_DEFINITIONS" => "WEBRTC_MAC=1 WEBRTC_IOS=1 WEBRTC_POSIX=1 OPENSSL_IS_BORINGSSL=1 NDEBUG",
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
    "Metal",
    "MetalKit",
    "IOSurface",
    "GLKit",
    "Network",
  ]

  s.prepare_command = <<-CMD
    ../scripts/apple/setup_ios.sh
  CMD
end
