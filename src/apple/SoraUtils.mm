#import "SoraUtils.h"

@implementation SoraUtils

+ (std::string)stdStringForString:(NSString *)nsString {
    NSData *charData = [nsString dataUsingEncoding:NSUTF8StringEncoding];
    return std::string(reinterpret_cast<const char *>(charData.bytes),
                       charData.length);
}

+ (NSString *)stringForStdString:(const std::string&)stdString {
    // std::string may contain null termination character so we construct
    // using length.
    return [[NSString alloc] initWithBytes:stdString.data()
                                    length:stdString.length()
                                  encoding:NSUTF8StringEncoding];
}

+ (std::string)stdString:(NSDictionary<NSString *, id> *)dictionary forKey:(NSString *)key
{
    id value = dictionary[key];
    if ([value isKindOfClass: [NSString class]]) {
        return [SoraUtils stdStringForString: (NSString *)value];
    } else {
        return "";
    }
}

+ (std::vector<std::string>)stdStrings:(NSDictionary<NSString *, id> *)dictionary forKey:(NSString *)key
{
    std::vector<std::string> list;
    id value = dictionary[key];
    if ([value isKindOfClass: [NSArray class]]) {
        NSArray *array = (NSArray *)value;
        for (id element in array) {
            if ([element isKindOfClass: [NSString class]]) {
                list.push_back([SoraUtils stdStringForString: (NSString *)element]);
            }
        }
        return list;
    } else {
        return list;
    }
}

+ (int64_t)intValue:(NSDictionary<NSString *, id> *)dictionary forKey:(NSString *)key
{
    id value = dictionary[key];
    if ([value isKindOfClass: [NSString class]]) {
        NSString *string = (NSString *)value;
        // -[NSString integerValue] は解析できない場合に 0 を返すので、 0 が返る場合に元の文字列が 0 を表すのか解析に失敗したのか判別しにくい
        NSScanner *scanner = [[NSScanner alloc] initWithString: string];
        NSInteger integer;
        if ([scanner scanInteger: &integer]) {
            return (int64_t)integer;
        } else {
            return -1;
        }
    } else if ([value isKindOfClass: [NSNumber class]]) {
        NSLog(@"getInt: NSNumber: %@", value);
        return [value integerValue];
    } else {
        return -1;
    }
}

@end
