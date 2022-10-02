#import "SoraFlutterMessageHandler.h"
#import "SoraClientWrapper.h"
#import "SoraUtils.h"

#include <memory>
#include <sstream>
#include <vector>

#include "../sora_client.h"

using namespace sora_flutter_sdk;

NSString *errorCodeBadArguments = @"BadArguments";

FlutterError *nullArgumentsError() {
    return [FlutterError errorWithCode: errorCodeBadArguments
                               message: @"Bad Arguments: Null constraints arguments received"
                               details: nil];
}

FlutterError *invalidArgumentsError() {
    return [FlutterError errorWithCode: errorCodeBadArguments
                               message: @"Bad Arguments: Arguments must be map"
                               details: nil];
}

FlutterError *badArgumentsError(NSString *message) {
    return [FlutterError errorWithCode: errorCodeBadArguments
                               message: message
                               details: nil];
}


@interface SoraFlutterMessageHandler ()

@property (nonatomic) id<FlutterBinaryMessenger> messenger;
@property (nonatomic) id<FlutterTextureRegistry> textureRegistry;
@property (nonatomic) int clientId;
@property (nonatomic) NSMutableDictionary<NSNumber *, SoraClientWrapper *> *clients;

@end

@implementation SoraFlutterMessageHandler

- (instancetype)initWithMessenger:(id<FlutterBinaryMessenger>)messenger
                  textureRegistry:(id<FlutterTextureRegistry>)textureRegistry
{
    if (self = [super init]) {
        self.messenger = messenger;
        self.textureRegistry = textureRegistry;
        self.clientId = 1;
        self.clients = [[NSMutableDictionary alloc] init];
    }

    //rtc::LogMessage::LogToDebug(rtc::LS_INFO);
    NSLog(@"set log level");
    rtc::LogMessage::LogToDebug(rtc::LS_VERBOSE);
    rtc::LogMessage::LogTimestamps();
    rtc::LogMessage::LogThreads();

    return self;
}

- (void)handle:(FlutterMethodCall *)call result:(FlutterResult)result
{
    if ([call.method isEqualToString: @"createSoraClient"]) {
        if (call.arguments == NULL) {
            result(nullArgumentsError());
            return;
        } else if (![call.arguments isKindOfClass: [NSDictionary class]]) {
            result(invalidArgumentsError());
            return;
        }

        NSDictionary *arguments = (NSDictionary *)call.arguments;
        SoraClientConfig config;
        config.signaling_urls = [SoraUtils stdStrings: arguments forKey: @"signaling_urls"];
        config.channel_id = [SoraUtils stdString: arguments forKey: @"channel_id"];
        config.role = [SoraUtils stdString: arguments forKey: @"role"];
        config.device_width = (int)[SoraUtils intValue: arguments forKey: @"device_width"];
        config.device_height = (int)[SoraUtils intValue: arguments forKey: @"device_height"];
        config.video_codec_type = [SoraUtils stdString: arguments forKey: @"video_codec_type"];
        config.event_channel = "SoraFlutterSdk/SoraClient/Event/" + std::to_string(self.clientId);
        config.messenger = (id)self.messenger;
        config.texture_registrar = (id)self.textureRegistry;

        SoraClientWrapper *wrapper = [[SoraClientWrapper alloc] initWithConfig: config
                                                                     clientId: self.clientId];
        self.clients[@(self.clientId)] = wrapper;
        self.clientId++;

        NSDictionary *response = @{
            @"client_id" : @(wrapper.clientId),
            @"event_channel" : wrapper.eventChannelName,
        };
        NSLog(@"response = %@", response);
        result(response);

    } else if ([call.method isEqualToString: @"connectSoraClient"]) {
        if (call.arguments == NULL) {
            result(nullArgumentsError());
            return;
        } else if (![call.arguments isKindOfClass: [NSDictionary class]]) {
            result(invalidArgumentsError());
            return;
        }

        NSDictionary *arguments = (NSDictionary *)call.arguments;
        int64_t clientId = [SoraUtils intValue: arguments forKey: @"client_id"];
        SoraClientWrapper *client = self.clients[@(clientId)];
        if (client == nil) {
            result(badArgumentsError(@"Client Not Found"));
            return;
        }

        // TODO: 何を返す？
        client.client->Connect();
        result(nil);

    } else if ([call.method isEqualToString: @"disposeSoraClient"]) {
        if (call.arguments == NULL) {
            result(nullArgumentsError());
            return;
        } else if (![call.arguments isKindOfClass: [NSDictionary class]]) {
            result(invalidArgumentsError());
            return;
        }

        // TODO
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
