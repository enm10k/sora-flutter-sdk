#import "SoraBase.h"

NS_ASSUME_NONNULL_BEGIN

@interface SoraFlutterMessageHandler : NSObject

- (instancetype)initWithMessenger:(id<FlutterBinaryMessenger>)messenger
                  textureRegistry:(id<FlutterTextureRegistry>)textureRegistry;
- (void)handle:(FlutterMethodCall*)call result:(FlutterResult)result;

@end

NS_ASSUME_NONNULL_END
