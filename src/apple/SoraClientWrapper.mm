#import "SoraClientWrapper.h"
#import "SoraUtils.h"

@implementation SoraClientWrapper

- (instancetype)initWithConfig:(SoraClientConfig &)config
                      clientId:(int)clientId
{
    if (self = [super init]) {
        self.clientId = clientId;
        self.client = std::make_shared<SoraClient>(config);
        self.eventChannelName = [SoraUtils stringForStdString: config.event_channel];
    }
    return self;
}

@end
