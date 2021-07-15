//
//  DStack.m
//  对外Api，混合栈入口
//  
//  Created by TAL on 2020/1/19.
//

#import "DStack.h"
#import "DNodeManager.h"
#import "DStackPlugin.h"
#import "DActionManager.h"
#include <mach-o/getsect.h>
#include <mach-o/dyld.h>
#import <objc/runtime.h>
#import "DFlutterViewController.h"

@interface DStack ()

@property (nonatomic, assign) BOOL logEnable;
@property (nonatomic, copy) NSString *engineRealizeClass;
@property (nonatomic, copy) NSString *homePageRoute;
@property (nonatomic, strong, readwrite) FlutterEngine *engine;

@end

@implementation DStack

+ (instancetype)sharedInstance
{
    static DStack *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [self.class new];
        [_instance logEnable:NO];
        [_instance addNotification];
    });
    return _instance;
}

- (void)startWithDelegate:(id<DStackDelegate>)delegate
{
    _delegate = delegate;
}

- (void)logEnable:(BOOL)enable
{
    NSInteger systemVersion = UIDevice.currentDevice.systemVersion.integerValue;
    if (systemVersion == 10) { enable = NO;}
    self.logEnable = enable;
    [[DNodeManager sharedInstance] configLogFileWithDebugMode:enable];
}

- (NSArray<NSString *> *)logFiles
{
    return [[DNodeManager sharedInstance] logFiles];
}

- (BOOL)debugMode
{
    return self.logEnable;
}

- (void)cleanLogFiles
{
    [[DNodeManager sharedInstance] cleanLogFile];
}

- (void)pushFlutterPageWithFlutterClass:(Class)cls
                                  route:(NSString *)route
{
    [self pushFlutterPageWithFlutterClass:cls route:route params:nil animated:YES];
}

- (void)pushFlutterPageWithFlutterClass:(Class)cls
                                  route:(NSString *)route
                                 params:(nullable NSDictionary *)params
{
    [self pushFlutterPageWithFlutterClass:cls route:route params:params animated:YES];
}

- (void)pushFlutterPageWithFlutterClass:(Class)cls
                                  route:(NSString *)route
                                 params:(nullable NSDictionary *)params
                               animated:(BOOL)animated
{
    [self pushFlutterPageWithFlutterClass:cls route:route params:params controllerCallBack:nil animated:animated];
}

- (void)pushFlutterPageWithFlutterClass:(Class)cls
                                  route:(NSString *)route
                                 params:(NSDictionary *)params
                     controllerCallBack:(void (^)(DFlutterViewController * _Nonnull))callBack
                               animated:(BOOL)animated
{
    [self checkFlutterPageWithRoute:route params:params animated:animated block:^(DNode *currentNode) {
        if (!cls) { return;}
        UINavigationController *navi = [self.delegate dStack:self
                                 navigationControllerForNode:[DActionManager stackNodeFromNode:currentNode]];
        if (!navi) {
            DStackError(@"!!!!!!!!!!!!%@!!!!!!!!!!!!", @"当前的NavigationController为空，不能push打开Flutter页面");
            return;
        }
        DFlutterViewController *controller = [[cls alloc] init];
        if (![controller isKindOfClass:FlutterViewController.class]) { return;}
        [self openFlutterPageWithRoute:route params:params action:DNodeActionTypePush controller:controller];
        if (callBack) {
            callBack(controller);
        }
        [navi pushViewController:controller animated:animated];
    } callBack:callBack];
}

- (void)pushFlutterPageWithStoryboard:(NSString *)storyboard
                           identifier:(NSString *)identifier
                                route:(NSString *)route
                               params:(nullable NSDictionary *)params
                             animated:(BOOL)animated
{
    [self pushFlutterPageWithStoryboard:storyboard
                             identifier:identifier
                                  route:route
                                 params:params
                     controllerCallBack:nil
                               animated:animated];
}

- (void)pushFlutterPageWithStoryboard:(NSString *)storyboard
                           identifier:(NSString *)identifier
                                route:(NSString *)route
                               params:(NSDictionary *)params
                   controllerCallBack:(void (^)(DFlutterViewController * _Nonnull))callBack
                             animated:(BOOL)animated
{
    [self checkFlutterPageWithRoute:route params:params animated:animated block:^(DNode *currentNode) {
        if (!storyboard || !identifier) { return;}
        UIStoryboard *story = [UIStoryboard storyboardWithName:storyboard bundle:nil];
        if (story) {
            UINavigationController *navi = [self.delegate dStack:self
                                     navigationControllerForNode:[DActionManager stackNodeFromNode:currentNode]];
            if (!navi) {
                DStackError(@"!!!!!!!!!!!!%@!!!!!!!!!!!!", @"当前的NavigationController为空，不能push打开Flutter页面");
                return;
            }
            DFlutterViewController *controller = [story instantiateViewControllerWithIdentifier:identifier];
            if (!controller || ![controller isKindOfClass:FlutterViewController.class]) { return;}
            [self openFlutterPageWithRoute:route params:params action:DNodeActionTypePush controller:controller];
            if (callBack) {
                callBack(controller);
            }
            [navi pushViewController:controller animated:animated];
        }
    } callBack:callBack];
}

- (void)presentFlutterPageWithFlutterClass:(Class)cls
                                     route:(NSString *)route
                                      from:(UIViewController *)from
{
    [self presentFlutterPageWithFlutterClass:cls
                                       route:route
                                      params:nil
                                    animated:YES
                                        from:from
                              rootController:nil];
}

- (void)presentFlutterPageWithFlutterClass:(Class)cls
                                     route:(NSString *)route
                                    params:(nullable NSDictionary *)params
                                      from:(UIViewController *)from
{
    [self presentFlutterPageWithFlutterClass:cls
                                       route:route
                                      params:params
                                    animated:YES
                                        from:from
                              rootController:nil];
}

- (void)presentFlutterPageWithFlutterClass:(Class)cls
                                     route:(NSString *)route
                                    params:(nullable NSDictionary *)params
                                  animated:(BOOL)animated
                                      from:(UIViewController *)from
                            rootController:(nullable Class)root
{
    [self presentFlutterPageWithFlutterClass:cls
                                       route:route
                                      params:params
                                    animated:animated
                                        from:from
                          controllerCallBack:nil
                              rootController:root];
}

- (void)presentFlutterPageWithFlutterClass:(Class)cls
                                     route:(NSString *)route
                                    params:(NSDictionary *)params
                                  animated:(BOOL)animated
                                      from:(UIViewController *)from
                        controllerCallBack:(void (^)(DFlutterViewController * _Nonnull))callBack
                            rootController:(Class)root
{
    [self checkFlutterPageWithRoute:route params:params animated:animated block:^(DNode *currentNode) {
        if (!cls) { return;}
        UIViewController *rootVC = nil;
        DFlutterViewController *controller = [[cls alloc] init];
        if (![controller isKindOfClass:FlutterViewController.class]) { return;}
        if (root) {
            id x = [[root alloc] init];
            if ([x isKindOfClass:UINavigationController.class]) {
                rootVC = [[root alloc] initWithRootViewController:controller];
            } else if ([x isKindOfClass:UITabBarController.class]) {
                [x setViewControllers:@[controller]];
                rootVC = x;
            }
        }
        [self openFlutterPageWithRoute:route params:params action:DNodeActionTypePush controller:controller];
        if (callBack) {
            callBack(controller);
        }
        [from presentViewController:rootVC ? rootVC : controller animated:animated completion:nil];
    } callBack:callBack];
}

- (void)presentFlutterPageWithStoryboard:(NSString *)storyboard
                              identifier:(NSString *)identifier
                                   route:(NSString *)route
                                  params:(nullable NSDictionary *)params
                                animated:(BOOL)animated
                                    from:(UIViewController *)from
                          rootController:(nullable Class)root
{
    [self presentFlutterPageWithStoryboard:storyboard
                                identifier:identifier
                                     route:route
                                    params:params
                                  animated:animated
                                      from:from
                        controllerCallBack:nil
                            rootController:root];
}

- (void)presentFlutterPageWithStoryboard:(NSString *)storyboard
                              identifier:(NSString *)identifier
                                   route:(NSString *)route
                                  params:(NSDictionary *)params
                                animated:(BOOL)animated
                                    from:(UIViewController *)from
                      controllerCallBack:(void (^)(DFlutterViewController * _Nonnull))callBack
                          rootController:(Class)root
{
    [self checkFlutterPageWithRoute:route params:params animated:animated block:^(DNode *currentNode) {
        if (!storyboard || !identifier) { return;}
        UIStoryboard *story = [UIStoryboard storyboardWithName:storyboard bundle:nil];
        if (story) {
            UIViewController *rootVC = nil;
            DFlutterViewController *controller = [story instantiateViewControllerWithIdentifier:identifier];
            if (!controller || ![controller isKindOfClass:FlutterViewController.class]) { return;}
            if (root) {
                id x = [[root alloc] init];
                if ([x isKindOfClass:UINavigationController.class]) {
                    rootVC = [[root alloc] initWithRootViewController:controller];
                } else if ([x isKindOfClass:UITabBarController.class]) {
                    [x setViewControllers:@[controller]];
                    rootVC = x;
                }
            }
            [self openFlutterPageWithRoute:route params:params action:DNodeActionTypePush controller:controller];
            if (callBack) {
                callBack(controller);
            }
            [from presentViewController:rootVC ? rootVC : controller animated:animated completion:nil];
        }
    } callBack:callBack];
}

- (void)popToPageWithFlutterRoute:(NSString *)route animated:(BOOL)animated
{
    [self popToPageWithFlutterRoute:route params:nil animated:animated];
}

- (void)popToPageWithFlutterRoute:(NSString *)route params:(NSDictionary *)params animated:(BOOL)animated
{
    DNode *node = [[DNode alloc] init];
    node.target = route;
    node.params = params;
    node.fromFlutter = YES;
    node.animated = animated;
    node.action = DNodeActionTypePopTo;
    [[DNodeManager sharedInstance] checkNode:node];
}

- (void)openFlutterPageWithRoute:(NSString *)route
                          params:(NSDictionary *)params
                          action:(DNodeActionType)action
                      controller:(DFlutterViewController *)controller
{
    [self openFlutterPageWithRoute:route
                            params:params
                            action:action
                          animated:NO
                        controller:controller];
}

- (void)openFlutterPageWithRoute:(NSString *)route
                          params:(NSDictionary *)params
                          action:(DNodeActionType)action
                        animated:(BOOL)animated
                      controller:(DFlutterViewController *)controller
{
    DNode *node = [[DNodeManager sharedInstance] nextPageScheme:route
                                                       pageType:DNodePageTypeFlutter
                                                         action:action
                                                         params:params];
    NSString *identifier = [NSString stringWithFormat:@"%@_%p",
                            NSStringFromClass(controller.class), controller];
    node.identifier = identifier;
    node.boundary = YES;
    node.animated = animated;
    [[DNodeManager sharedInstance] checkNode:node];
}

- (void)checkFlutterPageWithRoute:(NSString *)route
                           params:(nullable NSDictionary *)params
                         animated:(BOOL)animated
                            block:(void(^)(DNode *currentNode))block
                         callBack:(nullable void (^)(DFlutterViewController *))callBack
{
    UIViewController *controller = [DActionManager currentController];
    if ([controller isKindOfClass:DFlutterViewController.class]) {
        if (callBack) {
            callBack((DFlutterViewController *)controller);
        }
        [self openFlutterPageWithRoute:route
                                params:params
                                action:DNodeActionTypePush
                              animated:animated
                            controller:(DFlutterViewController *)controller];
    } else if ([controller isKindOfClass:UIViewController.class]) {
        DNode *currentNode = [[DNodeManager sharedInstance] currentNode];
        block(currentNode);
    }
}

- (void)tabBarController:(UITabBarController *)tabBarController
 willSelectViewController:(UIViewController *)viewController
{
    NSInteger oldSelectedIndex = tabBarController.selectedIndex;
    NSInteger willSelectIndex = [tabBarController.viewControllers indexOfObject:viewController];
    if (oldSelectedIndex != willSelectIndex) {
        [DActionManager tabBarWillSelectViewController:viewController homePageRoute:self.homePageRoute];
    }
}


#pragma mark -- DStackPluginProtocol

/// 处理Flutter发送至native的消息
/// @param call call
/// @param result result
- (void)handleSendNodeToNativeMessage:(FlutterMethodCall*)call result:(FlutterResult)result
{
    DNodePageType pageType = [DNode pageTypeWithString:call.arguments[@"pageType"]];
    DNodeActionType actionType = [DNode actionTypeWithString:call.arguments[@"actionType"]];
    DNode *node = [[DNodeManager sharedInstance] nextPageScheme:call.arguments[@"target"]
                                                       pageType:pageType
                                                         action:actionType
                                                         params:call.arguments[@"params"]];
    node.fromFlutter = YES;
    id homePage = call.arguments[@"homePage"];
    if (homePage && [homePage isKindOfClass:NSNumber.class]) {
        node.isFlutterHomePage = [homePage boolValue];
    }
    id animated = call.arguments[@"animated"];
    if (animated && [animated isKindOfClass:NSNumber.class]) {
        node.animated = [call.arguments[@"animated"] boolValue];
    }
    node.identifier = call.arguments[@"identifier"];
    [[DNodeManager sharedInstance] checkNode:node];
    result(@"节点操作完成");
}

/// 处理flutter发送的节点移除 didPop消息
/// @param call call
/// @param result result
- (void)handleRemoveFlutterPageNode:(FlutterMethodCall *)call result:(FlutterResult)result
{
    DNode *node = [[DNode alloc] init];
    node.fromFlutter = YES;
    node.target = call.arguments[@"target"];
    DNodePageType pageType = [DNode pageTypeWithString:call.arguments[@"pageType"]];
    DNodeActionType actionType = [DNode actionTypeWithString:call.arguments[@"actionType"]];
    node.pageType = pageType;
    node.action = actionType;
    node.canRemoveNode = YES;
    node.identifier = call.arguments[@"identifier"];
    [[DNodeManager sharedInstance] checkNode:node];
    result(@"节点移除完成");
}

/// 发送当前节点列表至flutter
/// @param result 回调
- (void)sendNodeListToFlutter:(FlutterResult)result
{
    NSMutableArray<NSDictionary *> *list = [[NSMutableArray alloc] init];
    [[[DNodeManager sharedInstance] currentNodeList] enumerateObjectsUsingBlock:^(DNode *obj, NSUInteger idx, BOOL *stop) {
        NSString *route = obj.target;
        NSString *pageType = obj.pageTypeString;
        NSDictionary *node = @{
            @"route": route ? route : @"",
            @"pageType": pageType ? pageType : @""
        };
        [list addObject:node];
    }];
    if (result) {
        result(list);
    }
}

- (void)sendHomePageRoute:(FlutterMethodCall *)call
{
    self.homePageRoute = call.arguments[@"homePageRoute"];
}

- (void)updateBoundaryNode:(FlutterMethodCall *)call
{
    [[DNodeManager sharedInstance] updateBoundaryNode:call.arguments];
}

- (FlutterEngine *)engine
{
    if (!_engine) {
        _engine = [self engineFromProtocol];
    }
    return _engine;
}

- (NSString *)flutterHomePageRoute
{
    if (self.homePageRoute) {
        return self.homePageRoute;
    }
    return @"/";
}

- (FlutterEngine *)engineFromProtocol
{
    FlutterEngine *engine = nil;
    FlutterEngine *(^engineBlock)(Class cls) = ^FlutterEngine *(Class cls) {
        FlutterEngine *_engine = nil;
        if (cls != NULL) {
            Class metaClass = object_getClass(cls);
            if (class_conformsToProtocol(metaClass, @protocol(DStackDelegate)) &&
                class_respondsToSelector(metaClass, @selector(dStackForFlutterEngine))) {
                _engine = [cls dStackForFlutterEngine];
            }
        }
        return _engine;
    };

    if (self.engineRealizeClass) {
        Class cls = NSClassFromString(self.engineRealizeClass);
        engine = engineBlock(cls);
    }
    
    if (!engine) {
        int numClasses;
        Class *classes = NULL;
        numClasses = objc_getClassList(NULL, 0);
        if (numClasses > 0 ) {
            classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
            numClasses = objc_getClassList(classes, numClasses);
            for (int i = 0; i < numClasses; i++) {
                Class class = classes[i];
                const char *className = class_getName(class);
                NSString *nameString = [[NSString alloc] initWithCString:className encoding:NSUTF8StringEncoding];
                Class cls = NSClassFromString(nameString);
                engine = engineBlock(cls);
                if (engine) {
                    break;
                }
            }
            free(classes);
        }
    }
    
    return engine;
}

#pragma mark -- private

- (void)addNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackgroundNotification)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForegroundNotification)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActiveNotification)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidFinishLaunchingNotification)
                                                 name:UIApplicationDidFinishLaunchingNotification
                                               object:nil];
}

- (void)applicationDidFinishLaunchingNotification
{
    [[DNodeManager sharedInstance] sendAppliccationLifeCicleToFlutter:DStackApplicationStateStart];
}

- (void)applicationWillResignActiveNotification
{
    [DActionManager checkFlutterViewController];
}

- (void)applicationDidEnterBackgroundNotification
{
    [DActionManager checkFlutterViewController];
    [[DNodeManager sharedInstance] sendAppliccationLifeCicleToFlutter:DStackApplicationStateBackground];
}

- (void)applicationWillEnterForegroundNotification
{
    [DActionManager checkFlutterViewController];
    [[DNodeManager sharedInstance] sendAppliccationLifeCicleToFlutter:DStackApplicationStateForeground];
}


@end

@implementation DStackNode
@end


void _dStackLog(NSString *msg, NSString *format, ...)
{
    if ([DStack sharedInstance].logEnable) {
        @try {
            va_list args;
            va_start(args, format);
            NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
            NSLog(@"%@%@", msg, message);
            va_end(args);
        } @catch(NSException *e) {
           NSLog(@"exception:%@", e.reason);
        }
    }
}

static void _dstack_engine_dyld_callback(const struct mach_header * mhp, intptr_t slide)
{
    unsigned long size = 0;
#ifndef __LP64__
    uintptr_t *data = (uintptr_t*)getsectiondata(mhp, SEG_DATA, "__DStackEInject", &size);
#else
    const struct mach_header_64 *mhp64 = (const struct mach_header_64 *)mhp;
    uintptr_t *data = (uintptr_t*)getsectiondata(mhp64, SEG_DATA, "__DStackEInject", &size);
#endif
    
    if (data && size > 0) {
        unsigned long count = size / sizeof(void*);
        for (int index = 0; index < count; index ++) {
            const char *nameChar = (const char *)data[index];
            NSString *className = [NSString stringWithUTF8String:nameChar];
            if (!className) { continue; }
            Class cls = NSClassFromString(className);
            if (cls != NULL) {
                Class metaClass = object_getClass(cls);
                if (class_conformsToProtocol(metaClass, @protocol(DStackDelegate)) &&
                    class_respondsToSelector(metaClass, @selector(dStackForFlutterEngine))) {
                    [DStack sharedInstance].engineRealizeClass = className;
                    break;
                }
            }
        }
    }
}

__attribute__((constructor)) void _dstack_registerDyldCallback() {
    _dyld_register_func_for_add_image(_dstack_engine_dyld_callback);
}



#pragma mark -DStackNotificationName

DStackNotificationName const DStackNotificationNameChangeBottomBarVisible = @"__DStackNotificationNameChangeBottomBarVisible";
