//
//  DStackProvider.h
//  定义
//
//  Created by TAL on 2020/1/16.
//

#ifndef DStackProvider_h
#define DStackProvider_h

#import <Flutter/Flutter.h>

FOUNDATION_EXPORT void _dStackLog(NSString *msg, NSString *format, ...);
#define DStackLog(format, ...) (_dStackLog(@"", format, ## __VA_ARGS__))
#define DStackError(format, ...) (_dStackLog(@"!!!!!!!!! DstackError !!!!!!!!! ==> ", format, ## __VA_ARGS__))

#define DStackInject(_className_) \
class DStackInjectClass; \
char * __DStackInject##_className_##Char \
__attribute__ ((used, section("__DATA, __DStackEInject "))) = ""#_className_""


#define DStackDeprecated(msg) __attribute__((deprecated(msg)))


// 页面类型
typedef NS_ENUM(NSInteger, DNodePageType) {
    DNodePageTypeUnknow,
    DNodePageTypeNative,    // 原生页面
    DNodePageTypeFlutter,   // Flutter页面
};

// 跳转类型
typedef NS_ENUM(NSInteger, DNodeActionType) {
    DNodeActionTypeUnknow,
    DNodeActionTypePush,        // push跳转
    DNodeActionTypePresent,     // present跳转
    DNodeActionTypePop,         // pop返回
    DNodeActionTypePopTo,       // popTo 返回
    DNodeActionTypePopToRoot,   // PopToRoot
    DNodeActionTypePopToNativeRoot,   // PopToRoot
    DNodeActionTypePopSkip,     // PopSkip
    DNodeActionTypeGesture,     // 手势
    DNodeActionTypeDismiss,     // Dismiss返回
    DNodeActionTypeReplace,     // replace返回
    DNodeActionTypeDidPop,      // didpop 确认
};

// 应用的生命周期
typedef NS_ENUM(NSInteger, DStackApplicationState) {
    DStackApplicationStateStart,        // 应用启动
    DStackApplicationStateForeground,   // 进入前台
    DStackApplicationStateBackground,   // 进入后台
};


@protocol DStackPluginProtocol <NSObject>

@required
/// 处理Flutter发送至nnative的消息
/// @param call call
/// @param result result
- (void)handleSendNodeToNativeMessage:(FlutterMethodCall*)call
                               result:(FlutterResult)result;

/// 处理flutter发送过来的移除节点信息
/// @param call call
/// @param result result
- (void)handleRemoveFlutterPageNode:(FlutterMethodCall*)call
                             result:(FlutterResult)result;

/// 发送节点列表到flutter
/// @param result result
- (void)sendNodeListToFlutter:(FlutterResult)result;


@end

#endif /* DStackProvider_h */
