#import "SoraBase.h"

#include <memory>

#include <sora_client.h>

NS_ASSUME_NONNULL_BEGIN

using namespace sora_flutter_sdk;

@interface SoraClientWrapper : NSObject

@property(nonatomic) int clientId;
@property(nonatomic) std::shared_ptr<SoraClient> client;
@property(nonatomic, copy) NSString* eventChannelName;

- (instancetype)initWithConfig:(SoraClientConfig&)config clientId:(int)clientId;

@end

NS_ASSUME_NONNULL_END
