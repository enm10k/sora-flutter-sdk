#import <Foundation/Foundation.h>

#include <string>
#include <vector>

NS_ASSUME_NONNULL_BEGIN

@interface SoraUtils : NSObject

// libwebrtc の以下のコードを使用
// https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/sdk/objc/helpers/NSString+StdString.mm
// ObjC 拡張を直接使おうとすると -ObjC オプションをつけても
// ビルドでエラーになるのでコピーした

+ (std::string)stdStringForString:(NSString *)nsString;
+ (NSString *)stringForStdString:(const std::string &)stdString;

+ (std::string)stdString:(NSDictionary<NSString *, id> *)dictionary forKey:(NSString *)key;
+ (std::vector<std::string>)stdStrings:(NSDictionary<NSString *, id> *)dictionary forKey:(NSString *)key;
+ (int64_t)intValue:(NSDictionary<NSString *, id> *)dictionary forKey:(NSString *)key;

@end


NS_ASSUME_NONNULL_END
