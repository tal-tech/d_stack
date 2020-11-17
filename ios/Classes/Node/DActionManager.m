//
//  DActionManager.m
//  
//
//  Created by TAL on 2020/1/16.
//

#import "DStack.h"
#import "DActionManager.h"
#import "DNodeManager.h"
#import "DStackPlugin.h"

@implementation DActionManager

+ (void)handlerActionWithNodeList:(NSArray<DNode *> *)nodeList node:(nonnull DNode *)node
{
    // didPop 不处理跳转，只需要删节点
    switch (node.action) {
        case DNodeActionTypePush:
        {
            [self push:node];
            break;
        }
        case DNodeActionTypePresent:
        {
            [self present:node];
            break;
        }
        case DNodeActionTypePop:
        {
            [self pop:node willRemovedList:nodeList];
            break;
        }
        case DNodeActionTypeDismiss:
        {
            [self dismiss:node willRemovedList:nodeList];
            break;
        }
        case DNodeActionTypeGesture:
        {
            [self gesture:node willRemovedList:nodeList];
            break;
        }
        case DNodeActionTypePopTo:
        {
             [self popTo:node willRemovedList:nodeList];
            break;
        }
        case DNodeActionTypePopToRoot:
        {
            [self popToRoot:node willRemovedList:nodeList];
            break;
        }
        case DNodeActionTypePopSkip:
        {
            [self popSkip:node willRemovedList:nodeList];
            break;
        }
        default:break;
    }
}

+ (void)push:(DNode *)node
{
    [self enterPageWithNode:node];
}

+ (void)present:(DNode *)node
{
    [self enterPageWithNode:node];
}

+ (void)pop:(DNode *)node willRemovedList:(NSArray<DNode *> *)nodeList
{
    [self closePageWithNode:node willRemovedList:nodeList];
}

+ (void)dismiss:(DNode *)node willRemovedList:(NSArray<DNode *> *)nodeList
{
    [self closePageWithNode:node willRemovedList:nodeList];
}

+ (void)popTo:(DNode *)node willRemovedList:(NSArray<DNode *> *)nodeList
{
    [self closePageListWithNode:node willRemovedList:nodeList];
}

+ (void)popToRoot:(DNode *)node willRemovedList:(NSArray<DNode *> *)nodeList
{
    [self closePageListWithNode:node willRemovedList:nodeList];
}

+ (void)popSkip:(DNode *)node willRemovedList:(NSArray<DNode *> *)nodeList
{
    [self closePageListWithNode:node willRemovedList:nodeList];
}

+ (void)gesture:(DNode *)node willRemovedList:(NSArray<DNode *> *)nodeList
{
    DNode *preNode = [DNodeManager sharedInstance].preNode;
    DNode *currentNode = [DNodeManager sharedInstance].currentNode;
    if (preNode && currentNode) {
        if (currentNode.pageType == DNodePageTypeFlutter &&
            preNode.pageType == DNodePageTypeNative) {
            // 当前是flutter页面，上一个页面时native页面，要通知flutter pop回一个页面
            DNode *popNode = [[DNode alloc] init];
            popNode.params = node.params;
            popNode.action = DNodeActionTypeGesture;
            
            NSDictionary *pageType = [self getPageTypeNodeList:nodeList];
            [self sendMessageToFlutterWithFlutterNodes:@[nodeList.firstObject.target] node:popNode pageType:pageType];
        }
    }
}

+ (NSDictionary *)getPageTypeNodeList:(NSArray<DNode *> *)nodeList
{
    NSString *pageTypeKey = [NSString stringWithFormat:@"%@", nodeList.firstObject.target];
    NSString *pageType = nodeList.firstObject.pageTypeString;
    return  @{pageTypeKey : pageType};
}

/// 进入一个页面
/// @param node 目标页面指令
+ (void)enterPageWithNode:(DNode *)node
{
    if (node.fromFlutter) {
       // 只处理来自Flutter消息通道的Node，并且是打开Native页面
       if (node.pageType == DNodePageTypeNative) {
           // flutter打开naive页面
           DStackNode *stackNode = [self stackNodeFromNode:node];
           if (node.action == DNodeActionTypePush) {
               [self dStackSafe:@selector(dStack:pushWithNode:) exe:^(DStack *stack) {
                   [stack.delegate dStack:stack pushWithNode:stackNode];
               }];
           } else if (node.action == DNodeActionTypePresent) {
               [self dStackSafe:@selector(dStack:presentWithNode:) exe:^(DStack *stack) {
                   [stack.delegate dStack:stack presentWithNode:stackNode];
               }];
           }
       }
    } else {
        // 来自Native的Node，并且是需要打开Flutter页面的，发消息至flutter，打开页面
        // 如果是DNodePageTypeNative 的话直接就打开了
       if (node.pageType == DNodePageTypeFlutter) {
           [self sendMessageToFlutterWithFlutterNodes:@[node.target] node:node pageType:@{node.target : node.pageTypeString}];
       }
    }
}

/// 关闭一个页面
/// @param node 关闭指令
/// @param nodeList 待关闭node列表
+ (void)closePageWithNode:(DNode *)node willRemovedList:(nullable NSArray<DNode *> *)nodeList
{
    if (node.action == DNodeActionTypeUnknow) {return;}
    DNode *targetNode = nodeList.firstObject;
    if (!targetNode) {
        return;
    }
    DNode *preNode = [DNodeManager sharedInstance].preNode;
    // 看当前节点的前一个节点是什么
    if (!preNode) {
        // 前一个节点是空的，说明前一个节点是根节点了
        if ([self rootControllerIsFlutterController]) {
            // 前面一页是Flutter页面
            DNode *currentNode = [DNodeManager sharedInstance].currentNode;
            if (currentNode.pageType == DNodePageTypeFlutter) {
                // 当前页面还是Flutter，则发消息返回到上一页
                NSDictionary *pageType = [self getPageTypeNodeList:nodeList];
                [self sendMessageToFlutterWithFlutterNodes:@[targetNode.target] node:node pageType:pageType];
            }
        } else {
            // 前面一页不是Flutter页面，如果消息是来自Flutter的则把当前controller关闭掉，
            // 如果消息是来自native的，则说明是native popViewControllerAnimated触发的操作进入到这里的，所以要去重
            if (node.fromFlutter) {
                [self closeViewControllerWithNode:node];
                [self sendMessageToFlutterWithFlutterNodes:@[targetNode.target] node:node pageType:@{node.target : node.pageTypeString}];
            }
        }
    } else {
        DNode *currentNode = [DNodeManager sharedInstance].currentNode;
        if (!currentNode) { return;}
        if (currentNode.pageType == DNodePageTypeFlutter) {
            // 当前页面是Flutter
            if (preNode.pageType == DNodePageTypeFlutter) {
                // 前一个页面是Flutter
                if (node.action == DNodeActionTypeDismiss) {
                    // 当前的flutter页面是被单独的flutterViewController 承载的，要dismiss
                    [self dismissViewController];
                }
                [self sendMessageToFlutterWithFlutterNodes:@[targetNode.target] node:node pageType:@{node.target : node.pageTypeString}];
            } else if (preNode.pageType == DNodePageTypeNative) {
                // 前一个页面是Native, 关闭当前的FlutterViewController，并且发消息告诉flutter返回上一页
                [self closeViewControllerWithNode:node];
                [self sendMessageToFlutterWithFlutterNodes:@[targetNode.target] node:node pageType:@{node.target : node.pageTypeString}];
            }
        } else if (currentNode.pageType == DNodePageTypeNative) {
            // 当前页面是Native
            if (preNode.pageType == DNodePageTypeFlutter) {
                // 前一个页面是Flutter，直接返回上一个页面，不处理
                DStackLog(@"当前页面是Native,前一个页面是Flutter，直接返回上一个页面，不处理");
            } else {
                // 前一个页面是Native
                DStackLog(@"当前页面是Native,前一个页面是Native，直接返回上一个页面，不处理");
            }
        }
    }
}

/// 关闭一组页面
/// @param node 关闭指令
/// @param nodeList 待关闭node列表
+ (void)closePageListWithNode:(DNode *)node willRemovedList:(nullable NSArray<DNode *> *)nodeList
{
    // 拆分出native的节点和flutter的节点
    NSMutableArray <DNode *>*nativeNodes = [[NSMutableArray alloc] init];
    NSMutableArray <NSString *>*flutterNodes = [[NSMutableArray alloc] init];
    [nodeList enumerateObjectsUsingBlock:^(DNode *obj, NSUInteger idx, BOOL *stop) {
        if (obj.pageType == DNodePageTypeNative) {
            [nativeNodes addObject:obj];
        } else if (obj.pageType == DNodePageTypeFlutter) {
            [flutterNodes addObject:obj.target];
        }
    }];

    if (flutterNodes.count) {
        // flutter的节点信息直接发消息到flutter
        [self sendMessageToFlutterWithFlutterNodes:flutterNodes node:node pageType:@{node.target : node.pageTypeString}];
    }
    if (!node.fromFlutter) { return;}
    
    BOOL animation = NO;
    UINavigationController *navigation = [self currentNavigationControllerWithNode:node];
    if (node.action == DNodeActionTypePopTo ||
        node.action == DNodeActionTypePopSkip) {
        // 需要找出目的页面所在的controller
        NSArray *vcs = navigation.viewControllers;
        UIViewController *target = nil;
        if (nativeNodes.count) {
            NSInteger idx = 0;
            target = vcs.firstObject;
            for (NSInteger i = vcs.count - 1; i >= 0; i --) {
                UIViewController *x = vcs[i];
                if ([NSStringFromClass(x.class) isEqualToString:nativeNodes.firstObject.target]) {
                    target = vcs[i];
                    idx = i;
                    break;
                }
            }
            if (idx > 0) {
                target = vcs[idx - 1];
            }
        } else {
            // nativeNodes里面没有Native页面，需要判断目的页是不是临界点的页面
            DNode *targetNode = nil;
            if (node.action == DNodeActionTypePopSkip) {
                if (nodeList.count) {
                    NSInteger idx = [[[DNodeManager sharedInstance] currentNodeList] indexOfObject:nodeList.firstObject];
                    if (idx > 0 && idx < [DNodeManager sharedInstance].currentNodeList.count) {
                        targetNode = [[DNodeManager sharedInstance] currentNodeList][idx - 1];
                    }
                }
            } else {
                targetNode = [[DNodeManager sharedInstance] nodeWithTarget:node.target];
            }
            if (targetNode && targetNode.pageType == DNodePageTypeNative) {
                // 是属于临界点的页面
                for (NSInteger i = vcs.count - 1; i >= 0; i --) {
                    UIViewController *x = vcs[i];
                    if ([NSStringFromClass(x.class) isEqualToString:targetNode.target]) {
                        target = x;
                        animation = YES;
                        break;
                    }
                }
            }
        }
        if (target) {
            [navigation setValue:@(YES) forKey:@"dStackFlutterNodeMessage"];
            [navigation popToViewController:target animated:animation];
        } else {
            DStackError(@"%@", @"没有找到需要关闭的controller");
        }
    } else if (node.action == DNodeActionTypePopToRoot) {
        [navigation setValue:@(YES) forKey:@"dStackFlutterNodeMessage"];
        [navigation popToRootViewControllerAnimated:YES];
    }
}

/// 发消息至Flutter
/// @param flutterNodes 需要发送至flutter的节点信息
/// @param node 目标节点信息
+ (void)sendMessageToFlutterWithFlutterNodes:(NSArray <NSString *>*)flutterNodes
                                        node:(DNode *)node pageType:(NSDictionary *)pageType
{
    NSDictionary *dataToFlutter = @{
        @"action": node.actionTypeString,
        @"params": node.params ? node.params : @{},
        @"nodes": flutterNodes,
        @"pageType": pageType,
        @"homePage": @(node.isFlutterHomePage),
        @"animated": @(node.animated)
    };
    if (node.canRemoveNode) {return;}
    DStackLog(@"发送【sendActionToFlutter】消息至Flutter\n参数 == %@", dataToFlutter);
    [[DStackPlugin sharedInstance] invokeMethod:DStackMethodChannelSendActionToFlutter arguments:dataToFlutter result:^(id  _Nullable result) {
        
    }];
}

+ (void)closeViewControllerWithNode:(DNode *)node
{
    if (node.action == DNodeActionTypePop) {
        UINavigationController *controller = [self currentNavigationControllerWithNode:node];
        [controller setValue:@(YES) forKey:@"dStackFlutterNodeMessage"];
        [controller popViewControllerAnimated:YES];
    } else if (node.action == DNodeActionTypeDismiss) {
        [self dismissViewController];
    }
}

+ (void)dismissViewController
{
    UIViewController *currentVC = self.currentController;
    [currentVC setValue:@(YES) forKey:@"dStackFlutterNodeMessage"];
    [currentVC dismissViewControllerAnimated:YES completion:nil];
}

+ (DStackNode *)stackNodeFromNode:(DNode *)node
{
    if (!node) { return nil;}
    DStackNode *stackNode = [[DStackNode alloc] init];
    stackNode.route = node.target;
    stackNode.params = node.params;
    stackNode.pageType = node.pageType;
    stackNode.actionType = node.action;
    return stackNode;
}

#pragma mark ============== controller 操作 ===============

/// 前后台切换时，需要检查FlutterEngine里面的flutterViewController是否还存在
/// 如果不存在了而不处理的话会引发crash
+ (void)checkFlutterViewController
{
    __block FlutterViewController *flutterController = nil;
    UINavigationController *navigation = [self currentNavigationControllerWithNode:nil];
    [navigation.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^( UIViewController *obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:FlutterViewController.class]) {
            flutterController = (FlutterViewController *)obj;
            *stop = YES;
        }
    }];
    
    if (flutterController) {
        DStack *stack = [DStack sharedInstance];
        if (!stack.engine.viewController) {
            stack.engine.viewController = flutterController;
        } else {
            if (![navigation.viewControllers containsObject:stack.engine.viewController]) {
                stack.engine.viewController = flutterController;
            }
        }
    }
}

/// rootVC是不是FlutterController
+ (BOOL)rootControllerIsFlutterController
{
    UIViewController *rootVC = self.rootController;
    if ([rootVC isKindOfClass:FlutterViewController.class]) {
        return YES;
    } else {
        if ([rootVC isKindOfClass:UINavigationController.class]) {
            UIViewController *rootController = [[(UINavigationController *)rootVC viewControllers] firstObject];
            if ([rootController isKindOfClass:FlutterViewController.class]) {
                return YES;
            } else if ([rootController isKindOfClass:UITabBarController.class]) {
                return [self _isFlutterControllerWithController:rootVC];
            }
        } else if ([rootVC isKindOfClass:UITabBarController.class]) {
            return [self _isFlutterControllerWithController:rootVC];
        }
    }
    return NO;
}

+ (BOOL)_isFlutterControllerWithController:(UIViewController *)rootVC
{
    UITabBarController *tabVC = (UITabBarController *)rootVC;
    UIViewController *selectedVC = [tabVC selectedViewController];
    if ([selectedVC isKindOfClass:UINavigationController.class]) {
        UIViewController *rootController = [[(UINavigationController *)selectedVC viewControllers] firstObject];
        if ([rootController isKindOfClass:FlutterViewController.class]) {
            return YES;
        }
    } else if ([selectedVC isKindOfClass:FlutterViewController.class]) {
        return YES;
    }
    return NO;
}

+ (UINavigationController *)currentNavigationControllerWithNode:(DNode *)node
{
    __block UINavigationController *navigationController = nil;
    [self dStackSafe:@selector(dStack:navigationControllerForNode:) exe:^(DStack *stack) {
        DStackNode *stackNode = [self stackNodeFromNode:node];
        navigationController = [stack.delegate dStack:stack navigationControllerForNode:stackNode];
    }];
    if (!navigationController) {
        DStackError(@"当前的NavigationController为空");
    }
    return navigationController;
}

+ (UIViewController *)currentController
{
    return [self currentControllerFromController:self.rootController];
}

+ (UIViewController *)currentControllerFromController:(UIViewController *)controller
{
    if (!controller) { return nil;}
    UIViewController *presented = controller.presentedViewController;
    if (presented) { return [self currentControllerFromController:presented];}
    if ([controller isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navi = (UINavigationController *)controller;
        if (!navi.viewControllers.count) { return navi;}
        return [self currentControllerFromController:navi.topViewController];
    } else if ([controller isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tab = (UITabBarController *)controller;
        if (!tab.viewControllers.count) { return tab;}
        return [self currentControllerFromController:tab.selectedViewController];
    } else {
        return controller;
    }
}

+ (UIViewController *)rootController
{
    UIViewController *rootVC = [UIApplication sharedApplication].delegate.window.rootViewController;
    if (!rootVC) {
        rootVC = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    }
    return rootVC;
}

+ (void)dStackSafe:(SEL)sel exe:(void(^)(DStack *stack))exe
{
    DStack *stack = [DStack sharedInstance];
    if (stack.delegate && [stack.delegate respondsToSelector:sel]) {
        if (exe) {
            exe(stack);
        }
    } else {
        DStackError(@"请实现%@代理", NSStringFromSelector(sel));
    }
}

@end
