//
//  DStackPlugin.m
//  plugin channel
//
//  Created by TAL on 2020/1/19.
//

#import "DStackPlugin.h"
#import "DStack.h"

DStackMethodChannelName const DStackMethodChannelPlatformVersion = @"getPlatformVersion";
DStackMethodChannelName const DStackMethodChannelSendNodeToNative = @"sendNodeToNative";
DStackMethodChannelName const DStackMethodChannelSendActionToFlutter = @"sendActionToFlutter";
DStackMethodChannelName const DStackMethodChannelSendRemoveFlutterPageNode = @"sendRemoveFlutterPageNode";
DStackMethodChannelName const DStackMethodChannelSendLifeCircle = @"sendLifeCycle";
DStackMethodChannelName const DStackMethodChannelSendNodeList = @"sendNodeList";
DStackMethodChannelName const DStackMethodChannelSendFlutterRootNode = @"sendFlutterRootNode";
DStackMethodChannelName const DStackMethodChannelSendOperationNodeToFlutter = @"sendOperationNodeToFlutter";


@interface DStackPlugin ()

@property (nonatomic, strong) FlutterMethodChannel *methodChannel;

@end

@implementation DStackPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {

    FlutterMethodChannel* channel = [FlutterMethodChannel
        methodChannelWithName:@"d_stack"
              binaryMessenger:registrar.messenger];
      
    DStackPlugin* instance = [DStackPlugin sharedInstance];
    instance.methodChannel = channel;
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  DStackLog(@"收到Flutter【%@】的消息\n参数：%@", call.method, call.arguments);
    if ([DStackMethodChannelPlatformVersion isEqualToString:call.method]) {
      NSString *platform = [@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]];
      result(platform);
  } else if ([DStackMethodChannelSendNodeToNative isEqualToString:call.method]) {
      [self handleSendNodeToNativeMessage:call result:result];
  } else if ([DStackMethodChannelSendRemoveFlutterPageNode isEqualToString:call.method]) {
      DStack *stack = [DStack sharedInstance];
      if ([stack respondsToSelector:@selector(handleRemoveFlutterPageNode:result:)]) {
          [stack handleRemoveFlutterPageNode:call result:result];
      }
  } else if ([DStackMethodChannelSendNodeList isEqualToString:call.method]) {
      DStack *stack = [DStack sharedInstance];
      if ([stack respondsToSelector:@selector(sendNodeListToFlutter:)]) {
          [stack sendNodeListToFlutter:result];
      }
  } else if ([DStackMethodChannelSendFlutterRootNode isEqualToString:call.method]) {
      DStack *stack = [DStack sharedInstance];
      if ([stack respondsToSelector:@selector(setFlutterRootNode)]) {
          [stack setFlutterRootNode];
      }
  } else {
      result(FlutterMethodNotImplemented);
  }
}

- (void)handleSendNodeToNativeMessage:(FlutterMethodCall*)call result:(FlutterResult)result
{
    DStack *stack = [DStack sharedInstance];
    if ([stack conformsToProtocol:@protocol(DStackPluginProtocol)]) {
        if ([stack respondsToSelector:@selector(handleSendNodeToNativeMessage:result:)]) {
            [stack handleSendNodeToNativeMessage:call result:result];
        }
    }
}

- (void)invokeMethod:(NSString*)method
           arguments:(id _Nullable)arguments
              result:(FlutterResult _Nullable)callback
{
    DStackPlugin *instance = [DStackPlugin sharedInstance];
    [instance.methodChannel invokeMethod:method arguments:arguments result:callback];
}

+ (instancetype)sharedInstance
{
    static id _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [self.class new];
    });
    return _instance;
}

@end
