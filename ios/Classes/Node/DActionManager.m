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
#import "DFlutterViewController.h"

@implementation DActionManager

+ (void)handlerActionWithNodeList:(NSArray<DNode *> *)nodeList node:(nonnull DNode *)node
{
    // didPop 不处理跳转，只需要删节点
    switch (node.action) {
        case DNodeActionTypePush:
        case DNodeActionTypePresent:
        {
            [self enterPageWithNode:node];
            [self bingdingNodeToFlutterViewController:nodeList.lastObject];
            break;
        }
        case DNodeActionTypePop:
        case DNodeActionTypeDismiss:
        {
            [self closePageWithNode:node willRemovedList:nodeList];
            break;
        }
        case DNodeActionTypeGesture:
        {
            [self gesture:node willRemovedList:nodeList];
            break;
        }
        case DNodeActionTypePopTo:
        case DNodeActionTypePopToRoot:
        case DNodeActionTypePopSkip:
        case DNodeActionTypePushAndRemoveUntil:
        {
            [self closePageListWithNode:node willRemovedList:nodeList];
            [self bingdingNodeToFlutterViewController:node];
            break;
        }
        case DNodeActionTypeReplace:
        {
            [self bingdingNodeToFlutterViewController:node];
            break;
        }
        default:break;
    }
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
            [self sendMessageToFlutterWithFlutterNodes:nodeList
                                                  node:popNode];
        }
        [self _checkTabBarWithNode:node popNodeList:nodeList];
    }
}

+ (NSDictionary *)getPageTypeNodeList:(NSArray<DNode *> *)nodeList
{
    NSString *pageTypeKey = [NSString stringWithFormat:@"%@", nodeList.firstObject.target];
    NSString *pageType = nodeList.firstObject.pageTypeString;
    return @{pageTypeKey : pageType};
}

/// 进入一个页面
/// @param node 目标页面指令
+ (void)enterPageWithNode:(DNode *)node
{
    if (node.fromFlutter) {
       if (node.pageType == DNodePageTypeNative) {
           // 处理来自Flutter消息通道的Node，并且是打开Native页面
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
       } else if (node.pageType == DNodePageTypeFlutter) {
           // flutter打开flutter页面，检查tabBar是否隐藏
           [[NSNotificationCenter defaultCenter] postNotificationName:DStackNotificationNameChangeBottomBarVisible
                                                               object:nil];
       }
    } else {
        // 来自Native的Node，并且是需要打开Flutter页面的，发消息至flutter，打开页面
        // 如果是DNodePageTypeNative 的话直接就打开了
       if (node.pageType == DNodePageTypeFlutter) {
           [self sendMessageToFlutterWithFlutterNodes:@[node]
                                                 node:node];
       }
    }
}

/// 关闭一个页面
/// @param node 关闭指令
/// @param nodeList 待关闭node列表
+ (void)closePageWithNode:(DNode *)node willRemovedList:(nullable NSArray<DNode *> *)nodeList
{
    if (node.action == DNodeActionTypeUnknow || !nodeList.count) {return;}
    DNode *preNode = [DNodeManager sharedInstance].preNode;
    DNode *currentNode = [DNodeManager sharedInstance].currentNode;
    
    if (!currentNode || currentNode.isRootPage) { return;}
    if (currentNode.pageType == DNodePageTypeFlutter) {
        switch (preNode.pageType) {
            case DNodePageTypeFlutter:
            {
                // 前一个页面是Flutter
                if (node.action == DNodeActionTypeDismiss) {
                    // 当前的flutter页面是被单独的flutterViewController 承载的，要dismiss
                    [self dismissViewControllerWithAnimated:node.animated];
                }
                [self sendMessageToFlutterWithFlutterNodes:nodeList
                                                      node:node];
                break;
            }
            case DNodePageTypeNative:
            {
                // 前一个页面是Native, 关闭当前的FlutterViewController，并且发消息告诉flutter返回上一页
                [self closeViewControllerWithNode:node];
                [self sendMessageToFlutterWithFlutterNodes:nodeList
                                                      node:node];
                break;
            }
            case DNodePageTypeUnknow:
            {
                // 前一个节点根节点，并且是Flutter页面
                if ([self rootControllerIsFlutterController]) {
                    // 当前页面还是Flutter，则发消息返回到上一页
                    [self sendMessageToFlutterWithFlutterNodes:nodeList
                                                          node:node];
                } else {
                    // 前面一页不是Flutter页面，如果消息是来自Flutter的则把当前controller关闭掉，
                    // 如果消息是来自native的，则说明是native popViewControllerAnimated触发的操作进入到这里的，所以要去重
                    if (node.fromFlutter) {
                        [self closeViewControllerWithNode:node];
                        [self sendMessageToFlutterWithFlutterNodes:nodeList
                                                              node:node];
                    }
                }
                break;
            }
            default:break;
        }
    } else if (currentNode.pageType == DNodePageTypeNative) {
        DStackLog(@"当前页面是Native，直接返回上一个页面，不需要处理");
    }
    [self _checkTabBarWithNode:node popNodeList:nodeList];
}

/// 关闭一组页面
/// @param node 关闭指令
/// @param nodeList 待关闭node列表
+ (void)closePageListWithNode:(DNode *)node willRemovedList:(nullable NSArray<DNode *> *)nodeList
{
    if (!nodeList.count) { return; }
    // 临界节点 DFlutterViewController
    int boundaryCount = 0;
    // 拆分出native的节点和flutter的节点
    NSMutableArray <DNode *>*nativeNodes = [[NSMutableArray alloc] init];
    NSMutableArray <DNode *>*flutterNodes = [[NSMutableArray alloc] init];
    for (DNode *obj in nodeList) {
        if (obj.pageType == DNodePageTypeNative) {
            [nativeNodes addObject:obj];
        } else if (obj.pageType == DNodePageTypeFlutter) {
            [flutterNodes addObject:obj];
            if (obj.boundary) {
                boundaryCount += 1;
            }
        }
    }
    
    if (flutterNodes.count) {
        // flutter的节点信息直接发消息到flutter
        if (node.action == DNodeActionTypePopToRoot) {
            node.animated = nativeNodes.count == 0;
        }
        [self sendMessageToFlutterWithFlutterNodes:flutterNodes node:node];
    }
    if (!node.fromFlutter) { return;}
    UINavigationController *navigation = [self currentNavigationControllerWithNode:node];
    if (node.action == DNodeActionTypePopToRoot) {
        [navigation setValue:@(YES) forKey:@"dStackFlutterNodeMessage"];
        [navigation popToRootViewControllerAnimated:YES];
        [navigation setValue:@(NO) forKey:@"dStackFlutterNodeMessage"];
        [self _checkTabBarWithNode:node popNodeList:nodeList];
        return;
    }

    NSInteger index = navigation.viewControllers.count - boundaryCount - nativeNodes.count - 1;
    index = index < 0 ? 0 : index;
    UIViewController *target = navigation.viewControllers[index];
    if (target) {
        if (target == navigation.topViewController) {
            [self _checkTabBarWithNode:node popNodeList:nodeList];
            return;
        }
        [navigation setValue:@(YES) forKey:@"dStackFlutterNodeMessage"];
        [navigation popToViewController:target animated:node.animated];
        [navigation setValue:@(NO) forKey:@"dStackFlutterNodeMessage"];
        [self _checkTabBarWithNode:node popNodeList:nodeList];
    } else {
        DStackError(@"%@", @"没有找到需要关闭的controller");
    }
}

/// 检查tabBar 的显示状态
/// @param node node消息
/// @param nodeList 节点列表
+ (void)_checkTabBarWithNode:(DNode *)node popNodeList:(NSArray <DNode *>*)nodeList
{
    if (!node.fromFlutter) {return;}
    if (!nodeList || nodeList.count < 1) {return;}
    NSArray *currentNodeList = [DNodeManager sharedInstance].currentNodeList;
    if (!currentNodeList || currentNodeList.count < 1) {return;}
    DNode *preNode = nil;
    DNode *target = nodeList.firstObject;
    if (!target) {return;}
    NSInteger index = [currentNodeList indexOfObject:target];
    if (index >= 1 && index < currentNodeList.count) {
        preNode = [currentNodeList objectAtIndex:index - 1];
    }
    if (preNode && preNode.isRootPage) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DStackNotificationNameChangeBottomBarVisible
                                                            object:nil
                                                          userInfo:@{@"hidden": @(NO)}];
    }
}

/// 发消息至Flutter
/// @param flutterNodes 需要发送至flutter的节点信息
/// @param node 目标节点信息
+ (void)sendMessageToFlutterWithFlutterNodes:(NSArray <DNode *>*)flutterNodes
                                        node:(DNode *)node
{
    if (node.canRemoveNode) {return;}
    NSDictionary *(^wrap)(DNode *) = ^NSDictionary *(DNode *one) {
        return @{
            @"target": one.target,
            @"action": one.actionTypeString,
            @"params": one.params ? one.params : @{},
            @"pageType": one.pageString,
            @"homePage": @(one.isFlutterHomePage),
            @"animated": @(one.animated),
            @"boundary": @(one.boundary),
        };
    };
    NSMutableArray <NSDictionary *>*nodeList = [[NSMutableArray alloc] init];
    NSMutableDictionary <NSString *, id>*params = [[NSMutableDictionary alloc] init];
    if ((node.action == DNodeActionTypePush ||
         node.action == DNodeActionTypePresent ||
         node.action == DNodeActionTypeReplace)) {
        [nodeList addObject:wrap(flutterNodes.firstObject)];
    } else {
        for (DNode *x in flutterNodes) {
            // homePage 页面不能pop，不然会黑屏
            if (!(x.isFlutterHomePage && x.boundary)) {
                x.params = node.params;
                [nodeList addObject:wrap(x)];
            }
        }
    }
    [params setValue:nodeList forKey:@"nodes"];
    [params setValue:node.actionTypeString forKey:@"action"];
    [params setValue:@(node.animated) forKey:@"animated"];
    DStackLog(@"发送【sendActionToFlutter】消息至Flutter\n参数 == %@", params);
    [[DStackPlugin sharedInstance] invokeMethod:DStackMethodChannelSendActionToFlutter
                                      arguments:params
                                         result:nil];
}

+ (void)closeViewControllerWithNode:(DNode *)node
{
    if (node.action == DNodeActionTypePop) {
        UINavigationController *controller = [self currentNavigationControllerWithNode:node];
        [controller setValue:@(YES) forKey:@"dStackFlutterNodeMessage"];
        [controller popViewControllerAnimated:node.animated];
        [controller setValue:@(NO) forKey:@"dStackFlutterNodeMessage"];
    } else if (node.action == DNodeActionTypeDismiss) {
        [self dismissViewControllerWithAnimated:node.animated];
    }
}

+ (void)dismissViewControllerWithAnimated:(BOOL)animated
{
    UIViewController *currentVC = self.currentController;
    [currentVC setValue:@(YES) forKey:@"dStackFlutterNodeMessage"];
    [currentVC dismissViewControllerAnimated:animated completion:nil];
    [currentVC setValue:@(NO) forKey:@"dStackFlutterNodeMessage"];
}

+ (DStackNode *)stackNodeFromNode:(DNode *)node
{
    if (!node) { return nil;}
    DStackNode *stackNode = [[DStackNode alloc] init];
    stackNode.route = node.target;
    stackNode.params = node.params;
    stackNode.pageType = node.pageType;
    stackNode.actionType = node.action;
    stackNode.animated = node.animated;
    return stackNode;
}

/// 把最新的Node绑定到FlutterViewController
+ (void)bingdingNodeToFlutterViewController:(DNode *)node
{
    UIViewController *controller = [self currentController];
    if ([controller isKindOfClass:DFlutterViewController.class] &&
        node.pageType == DNodePageTypeFlutter) {
        DFlutterViewController *flutter = (DFlutterViewController *)controller;
        NSString *identifier = [NSString stringWithFormat:@"%p", flutter];
        if ([[DNodeManager sharedInstance].currentFlutterViewControllerID isEqualToString:identifier]) {
            [flutter updateCurrentNode:node];
        }
    }
}


#pragma mark ============== controller 操作 ===============

+ (void)tabBarWillSelectViewController:(UIViewController *)viewController
                         homePageRoute:(NSString *)route
{
    DNode *node = [[DNode alloc] init];
    node.action = DNodeActionTypeReplace;
    if ([self _checkIsFlutterControllerWithController:viewController]) {
        node.target = route ? route : @"/";
        node.pageType = DNodePageTypeFlutter;
    } else {
        node.target = @"/";
        node.pageType = DNodePageTypeNative;
    }
    BOOL updated = [[DNodeManager sharedInstance] updateRootNode:node];
    if (node.pageType == DNodePageTypeFlutter && updated) {
        [self sendMessageToFlutterWithFlutterNodes:@[node] node:node];
    }
}

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
    return [self _checkIsFlutterControllerWithController:selectedVC];
}

+ (BOOL)_checkIsFlutterControllerWithController:(UIViewController *)selectedVC
{
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
    UIViewController *controller = nil;
    DStack *stack = [DStack sharedInstance];
    if (stack.delegate && [stack.delegate respondsToSelector:@selector(visibleControllerForCurrentWindow)]) {
        controller = [stack.delegate visibleControllerForCurrentWindow];
    };
    NSAssert(controller, @"visibleControllerForCurrentWindow返回了空的controller");
    return controller;
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
