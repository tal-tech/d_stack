//
//  DStackPlugin.h
//  plugin channel
//
//  Created by TAL on 2020/1/19.
//

#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString *DStackMethodChannelName;
UIKIT_EXTERN DStackMethodChannelName const DStackMethodChannelPlatformVersion;      // 获取版本号
UIKIT_EXTERN DStackMethodChannelName const DStackMethodChannelSendNodeToNative;     // flutter发送节点至native
UIKIT_EXTERN DStackMethodChannelName const DStackMethodChannelSendActionToFlutter;  // native发送跳转指令至flutter
UIKIT_EXTERN DStackMethodChannelName const DStackMethodChannelSendRemoveFlutterPageNode;  // flutter发送移除节点的指令到native
UIKIT_EXTERN DStackMethodChannelName const DStackMethodChannelSendLifeCircle; // 生命周期通道
UIKIT_EXTERN DStackMethodChannelName const DStackMethodChannelSendNodeList; // 节点列表
UIKIT_EXTERN DStackMethodChannelName const DStackMethodChannelSendFlutterRootNode; // 设置flutter根节点
UIKIT_EXTERN DStackMethodChannelName const DStackMethodChannelSendOperationNodeToFlutter; // Operation节点
UIKIT_EXTERN DStackMethodChannelName const DStackMethodChannelSendSendHomePageRoute; // 发送homePageRoute

@interface DStackPlugin : NSObject<FlutterPlugin>

+ (instancetype)sharedInstance;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (void)invokeMethod:(NSString *_Nullable)method
           arguments:(id _Nullable)arguments
              result:(FlutterResult _Nullable)callback;
@end

NS_ASSUME_NONNULL_END
