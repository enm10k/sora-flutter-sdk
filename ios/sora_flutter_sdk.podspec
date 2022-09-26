sdk_dir = "_setup"

Pod::Spec.new do |s|
  s.name             = 'sora_flutter_sdk'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = ["Classes/**/*", "src/**/*"]
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.swift_version = '5.0'
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
                             "\"$(PODS_TARGET_SRCROOT)/#{sdk_dir}/boost/include\" ",
    "CLANG_CXX_LANGUAGE_STANDARD" => "gnu++17",
    "GCC_PREPROCESSOR_DEFINITIONS" => "WEBRTC_MAC=1 WEBRTC_IOS=1 WEBRTC_POSIX=1 OPENSSL_IS_BORINGSSL=1",
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
