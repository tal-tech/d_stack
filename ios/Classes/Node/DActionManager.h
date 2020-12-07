//
//  DActionManager.h
//  管理跳转事件
//
//  Created by TAL on 2020/1/16.
//

#import <Foundation/Foundation.h>
#import "DNode.h"

@class DStackNode;

NS_ASSUME_NONNULL_BEGIN

/// 页面跳转检测器
/// DNodeManager传递待跳转的节点过来
/// Flutter 进入 Native，发送Node节点至Native
/// Native 进入 Flutter,  发送消息至Flutter
@interface DActionManager : NSObject

+ (void)handlerActionWithNodeList:(NSArray <DNode *>*)nodeList
                             node:(DNode *)node;
/// rootVC是不是FlutterController
+ (BOOL)rootControllerIsFlutterController;

/// 当前的rootViewController
+ (UIViewController *)rootController;

/// 检查flutter Engine的FlutterViewController是否存在
+ (void)checkFlutterViewController;

/// 当前控制前
+ (UIViewController *)currentController;

/// DNode创建DStackNode
/// @param node DStackNode
+ (DStackNode *)stackNodeFromNode:(DNode *)node;

/// tabBar切换事件
/// @param viewController 将要切换的viewController
/// @param route homePageRoute
+ (void)tabBarWillSelectViewController:(UIViewController *)viewController
                         homePageRoute:(NSString *)route;

@end

NS_ASSUME_NONNULL_END
