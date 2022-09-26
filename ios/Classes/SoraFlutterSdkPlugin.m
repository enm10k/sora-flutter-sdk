#import "SoraFlutterSdkPlugin.h"
#if __has_include(<sora_flutter_sdk/sora_flutter_sdk-Swift.h>)
#import <sora_flutter_sdk/sora_flutter_sdk-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "sora_flutter_sdk-Swift.h"
#endif

@implementation SoraFlutterSdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSoraFlutterSdkPlugin registerWithRegistrar:registrar];
}
@end
