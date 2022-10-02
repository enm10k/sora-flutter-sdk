#include "sora_event_channel.h"

#import "../SoraBase.h"
#import "../Sorautils.h"

@interface SoraClientStreamHandler : NSObject <FlutterStreamHandler>

@property (nonatomic) std::function<void (const sora_flutter_sdk::SoraEventSink&)> onListen;

- (instancetype)initWithOnListen:(const std::function<void (const sora_flutter_sdk::SoraEventSink&)>&)onListen;

@end

@implementation SoraClientStreamHandler

- (instancetype)initWithOnListen:(const std::function<void (const sora_flutter_sdk::SoraEventSink&)>&)onListen
{
    if (self = [super init]) {
        self.onListen = onListen;
    }
    return self;
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:
                                           (nonnull FlutterEventSink)events
{
  NSLog(@"EventSink: onListenWithArguments");
  auto f = [events](const std::string& json) {
    // TODO(melpon): JSON 文字列を NSDictionary にしてから渡す
    events(@{});
  };

  self.onListen(f);
  return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments
{
    return nil;
}

@end

namespace sora_flutter_sdk {

class SoraEventChannelImpl : public SoraEventChannel {
public:
  SoraEventChannelImpl(const std::string& name, FlutterBinaryMessenger* messenger, FlutterStandardMethodCodec* codec);
  void SetStreamHandler(const std::function<void (const SoraEventSink&)>& f) override;

private:
  FlutterEventChannel* event_channel_;
};

SoraEventChannelImpl::SoraEventChannelImpl(const std::string& name, FlutterBinaryMessenger* messenger, FlutterStandardMethodCodec* codec) {
  event_channel_ = [[FlutterEventChannel alloc] initWithName:[SoraUtils stringForStdString:name]
                                             binaryMessenger:(id)messenger
                                                       codec:codec];
}

void SoraEventChannelImpl::SetStreamHandler(const std::function<void (const SoraEventSink&)>& f) {
  auto handler = [[SoraClientStreamHandler alloc] initWithOnListen:f];
  [event_channel_ setStreamHandler:handler];
};

std::shared_ptr<SoraEventChannel> SoraEventChannel::Create(const std::string& name, void* messenger, void* codec) {
  return std::make_shared<SoraEventChannelImpl>(name, (__bridge FlutterBinaryMessenger*)messenger, (__bridge FlutterStandardMethodCodec*)codec);
}

}
