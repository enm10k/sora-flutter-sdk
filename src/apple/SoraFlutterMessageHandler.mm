#import "SoraFlutterMessageHandler.h"
#import "SoraClientWrapper.h"
#import "SoraUtils.h"

#include <memory>
#include <sstream>
#include <vector>

#include "sora_client.h"
#include "config_reader.h"
#include "device_list.h"

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
        std::string json = [SoraUtils stdString: arguments forKey: @"config"];
        config = sora_flutter_sdk::JsonToClientConfig(json);
        config.signaling_config = sora_flutter_sdk::JsonToSignalingConfig(json);
        config.event_channel = "SoraFlutterSdk/SoraClient/Event/" + std::to_string(self.clientId);
        config.messenger = self.messenger;
        config.texture_registrar = self.textureRegistry;

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

        NSDictionary *arguments = (NSDictionary *)call.arguments;
        int64_t clientId = [SoraUtils intValue: arguments forKey: @"client_id"];
        SoraClientWrapper *client = self.clients[@(clientId)];
        if (client == nil) {
            result(badArgumentsError(@"Client Not Found"));
            return;
        }

        client.client->Disconnect();
        result(nil);

    } else if ([call.method isEqualToString: @"destroySoraClient"]) {
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
        
        client.client->Destroy();
        [self.clients removeObjectForKey: @(clientId)];
        result(nil);

    } else if ([call.method isEqualToString: @"sendDataChannel"]) {
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

        std::string label = [SoraUtils stdString: arguments forKey: @"label"];

        FlutterStandardTypedData *flData = (FlutterStandardTypedData *)arguments[@"data"];
        std::string data;
        const uint8_t *bytes = (const uint8_t *)flData.data.bytes;
        for (int i = 0; i < flData.data.length; i++) {
            data.push_back(bytes[i]);
        }

        bool resp = client.client->SendDataChannel(label, data);
        result(@(resp));

    } else if ([call.method isEqualToString: @"enumVideoCapturers"]) {
        NSMutableArray *resp = [[NSMutableArray alloc] init];
        DeviceList::EnumVideoCapturer(
                          [resp](std::string device_name, std::string unique_name) {
                            NSDictionary *info = @{
                            @"device": [SoraUtils stringForStdString: device_name],
                            @"unique": [SoraUtils stringForStdString: unique_name],
                            };
                            [resp addObject: info];
                          });

        result(resp);

    } else if ([call.method isEqualToString: @"switchVideoDevice"]) {
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

        std::string json = [SoraUtils stdString: arguments forKey: @"config"];
        sora::CameraDeviceCapturerConfig config = sora_flutter_sdk::JsonToCameraDeviceCapturerConfig(json);
        client.client->SwitchVideoDevice(config);
        result(nil);

    } else if ([call.method isEqualToString: @"setVideoEnabled"]) {
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

      bool flag = [(NSNumber *)arguments[@"flag"] boolValue];
      client.client->SetVideoEnabled(flag);
       result(nil);

     } else if ([call.method isEqualToString: @"setAudioEnabled"]) {
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

       bool flag = [(NSNumber *)arguments[@"flag"] boolValue];
       client.client->SetAudioEnabled(flag);
       result(nil);

    } else if ([call.method isEqualToString: @"setLyraModelPath"]) {
        if (call.arguments == NULL) {
            result(nullArgumentsError());
            return;
        } else if (![call.arguments isKindOfClass: [NSDictionary class]]) {
            result(invalidArgumentsError());
            return;
        }

       NSDictionary *arguments = (NSDictionary *)call.arguments;
        NSString *path = (NSString *)arguments[@"path"];
        int status = setenv("SORA_LYRA_MODEL_COEFFS_PATH", path.UTF8String, 1);
        result(@(status));

    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
