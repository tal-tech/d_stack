//
//  DNavigator.m
//  d_stack
//  
//  Created by TAL on 2020/2/3.
//

#import <objc/runtime.h>
#import "DNavigator.h"
#import "DNodeManager.h"
#import "DActionManager.h"

void dStackSelectorSwizzling(Class aClass, SEL originalSelector, SEL newSelector)
{
    Method originalMethod = class_getInstanceMethod(aClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(aClass, newSelector);
    BOOL didAddMethod = class_addMethod(aClass,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(aClass,
                            newSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

BOOL hasFDClass()
{
    Class _FDDelegate = NSClassFromString(@"_FDFullscreenPopGestureRecognizerDelegate");
    return _FDDelegate != NULL;
}

void checkNode(UIViewController *targetVC, DNodeActionType action)
{
    NSString *scheme = NSStringFromClass(targetVC.class);
    DNode *node = [[DNodeManager sharedInstance] nextPageScheme:scheme
                                                       pageType:DNodePageTypeNative
                                                         action:action
                                                         params:nil];
    [[DNodeManager sharedInstance] checkNode:node];
}



@interface NSObject (DStackDismissGestureCategory)

@property (nonatomic, copy) NSString *oldDismissDelegateName;

@end

@implementation NSObject (DStackDismissGestureCategory)

- (void)setOldDismissDelegateName:(NSString *)oldDismissDelegateName
{
    objc_setAssociatedObject(self, @selector(oldDismissDelegateName), oldDismissDelegateName, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)oldDismissDelegateName
{
    return objc_getAssociatedObject(self, @selector(oldDismissDelegateName));
}

@end


@interface DStackNavigator : NSObject <UIAdaptivePresentationControllerDelegate>

/// dismiss手势代理类列表
@property (nonatomic, strong) NSMutableDictionary <NSString *, id>*dismissDelegateClass;

+ (instancetype)instance;

@end

@implementation DStackNavigator

+ (instancetype)instance
{
    static DStackNavigator *navigator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        navigator = [[self alloc] init];
    });
    return navigator;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    NSString *name = controller.oldDismissDelegateName;
    if (name && [self.dismissDelegateClass.allKeys containsObject:name]) {
        id <UIAdaptivePresentationControllerDelegate> oldDelegate = self.dismissDelegateClass[name];
        if (oldDelegate && [oldDelegate respondsToSelector:@selector(adaptivePresentationStyleForPresentationController:)]) {
            return [oldDelegate adaptivePresentationStyleForPresentationController:controller];
        }
    }
    return controller.presentationStyle;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection API_AVAILABLE(ios(8.3))
{
    NSString *name = controller.oldDismissDelegateName;
    if (name && [self.dismissDelegateClass.allKeys containsObject:name]) {
        id <UIAdaptivePresentationControllerDelegate> oldDelegate = self.dismissDelegateClass[name];
        if (oldDelegate && [oldDelegate respondsToSelector:@selector(adaptivePresentationStyleForPresentationController:traitCollection:)]) {
            return [oldDelegate adaptivePresentationStyleForPresentationController:controller
                                                                   traitCollection:traitCollection];
        }
    }
    return controller.presentationStyle;
}

- (nullable UIViewController *)presentationController:(UIPresentationController *)controller viewControllerForAdaptivePresentationStyle:(UIModalPresentationStyle)style
{
    NSString *name = controller.oldDismissDelegateName;
    if (name && [self.dismissDelegateClass.allKeys containsObject:name]) {
        id <UIAdaptivePresentationControllerDelegate> oldDelegate = self.dismissDelegateClass[name];
        if (oldDelegate && [oldDelegate respondsToSelector:@selector(presentationController:viewControllerForAdaptivePresentationStyle:)]) {
            return [oldDelegate presentationController:controller
            viewControllerForAdaptivePresentationStyle:style];
        }
    }
    return nil;
}

- (void)presentationController:(UIPresentationController *)presentationController willPresentWithAdaptiveStyle:(UIModalPresentationStyle)style transitionCoordinator:(nullable id <UIViewControllerTransitionCoordinator>)transitionCoordinator API_AVAILABLE(ios(8.3))
{
    [self checkSelectorToDelegate:@selector(presentationController:willPresentWithAdaptiveStyle:transitionCoordinator:)
                       controller:presentationController
                          forward:^(id<UIAdaptivePresentationControllerDelegate> delegate) {
        [delegate presentationController:presentationController
            willPresentWithAdaptiveStyle:style
                   transitionCoordinator:transitionCoordinator];
    }];
}

- (BOOL)presentationControllerShouldDismiss:(UIPresentationController *)presentationController API_AVAILABLE(ios(13.0))
{
    NSString *name = presentationController.oldDismissDelegateName;
    if (name && [self.dismissDelegateClass.allKeys containsObject:name]) {
        id <UIAdaptivePresentationControllerDelegate> oldDelegate = self.dismissDelegateClass[name];
        if (oldDelegate && [oldDelegate respondsToSelector:@selector(presentationControllerShouldDismiss:)]) {
            return [oldDelegate presentationControllerShouldDismiss:presentationController];
        }
    }
    return YES;
}

- (void)presentationControllerWillDismiss:(UIPresentationController *)presentationController API_AVAILABLE(ios(13.0))
{
    [self checkSelectorToDelegate:@selector(presentationControllerWillDismiss:)
                       controller:presentationController
                          forward:^(id<UIAdaptivePresentationControllerDelegate> delegate) {
        [delegate presentationControllerWillDismiss:presentationController];
    }];
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController API_AVAILABLE(ios(13.0))
{
    UIViewController *presented = presentationController.presentedViewController;
    UIViewController *target = presented;
    if ([presented isKindOfClass:UINavigationController.class]) {
        target = [[(UINavigationController *)presented viewControllers] firstObject];
        checkNode(target, DNodeActionTypePopTo);
    }
    checkNode(target, DNodeActionTypeGesture);
    if ([target isKindOfClass:NSClassFromString(@"FlutterViewController")]) {
        [[DNodeManager sharedInstance] resetHomePage];
    }
    
    [self checkSelectorToDelegate:@selector(presentationControllerDidDismiss:)
                       controller:presentationController
                          forward:^(id<UIAdaptivePresentationControllerDelegate> delegate) {
        [delegate presentationControllerDidDismiss:presentationController];
    }];
    
    NSString *name = presentationController.oldDismissDelegateName;
    if (name && [self.dismissDelegateClass.allKeys containsObject:name]) {
        [self.dismissDelegateClass removeObjectForKey:name];
    }
}

- (void)presentationControllerDidAttemptToDismiss:(UIPresentationController *)presentationController API_AVAILABLE(ios(13.0))
{
    [self checkSelectorToDelegate:@selector(presentationControllerDidAttemptToDismiss:)
                       controller:presentationController
                          forward:^(id<UIAdaptivePresentationControllerDelegate> delegate) {
        [delegate presentationControllerDidAttemptToDismiss:presentationController];
    }];
}

- (void)checkSelectorToDelegate:(SEL)selector
                     controller:(UIPresentationController *)controller
                        forward:(void(^)(id <UIAdaptivePresentationControllerDelegate> delegate))forward
{
    NSString *name = controller.oldDismissDelegateName;
    if (name && [self.dismissDelegateClass.allKeys containsObject:name]) {
        id <UIAdaptivePresentationControllerDelegate> delegate = self.dismissDelegateClass[name];
        if (delegate && [delegate respondsToSelector:selector]) {
            if (forward) {
                forward(delegate);
            }
        }
    }
}

- (NSMutableDictionary<NSString *,id> *)dismissDelegateClass
{
    if (!_dismissDelegateClass) {
        _dismissDelegateClass = [[NSMutableDictionary alloc] init];
    }
    return _dismissDelegateClass;
}

@end


#pragma mark ########### DStackNavigationControllerCategory ###########

@interface UINavigationController (DStackNavigationControllerCategory)

@property (nonatomic, strong) UIViewController *dStackRootViewController;
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *dStack_fullscreenPopGestureRecognizer;
@property (nonatomic, assign) BOOL dStack_viewControllerBasedNavigationBarAppearanceEnabled;

@end


#pragma mark ########### DStackUIViewControllerCategory ###########

typedef void (^_DStackViewControllerWillAppearInjectBlock)(UIViewController *viewController, BOOL animated);

@interface UIViewController (DStackUIViewControllerCategory)

/// 开始pop
@property (nonatomic, assign) BOOL isBeginPoped;
/// 是否为手势出发的返回
@property (nonatomic, assign) BOOL isGesturePoped;
@property (nonatomic, strong) NSNumber *dStackFlutterNodeMessage;
@property (nonatomic, copy) _DStackViewControllerWillAppearInjectBlock dStack_willAppearInjectBlock;

/// 是否为FlutterViewController
- (BOOL)isFlutterViewController;

@end

@implementation UIViewController (DStackUIViewControllerCategory)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL present = @selector(presentViewController:animated:completion:);
        SEL newPresent = @selector(d_stackPresentViewController:animated:completion:);
        dStackSelectorSwizzling([self class], present, newPresent);
        
        SEL dismiss = @selector(dismissViewControllerAnimated:completion:);
        SEL newDismiss = @selector(d_stackDismissViewControllerAnimated:completion:);
        dStackSelectorSwizzling([self class], dismiss, newDismiss);
        
        SEL willAppear = @selector(viewWillAppear:);
        SEL newWillAppear = @selector(d_stackViewWillAppear:);
        dStackSelectorSwizzling([self class], willAppear, newWillAppear);
        
        SEL didDisappear = @selector(viewDidDisappear:);
        SEL newDidDisappear = @selector(d_stackViewDidDisappear:);
        dStackSelectorSwizzling([self class], didDisappear, newDidDisappear);
    });
}

- (BOOL)isCustomClass
{
    NSString *systemLibrary = @"System/Library";
    NSString *developerLibrary = @"Developer/Library";
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    if ([[bundle bundlePath] containsString:systemLibrary] ||
        [[bundle bundlePath] containsString:developerLibrary]) {
        return NO;
    }
    return YES;
}

- (void)d_stackPresentViewController:(UIViewController *)controller animated:(BOOL)flag completion:(void (^)(void))completion
{
    // 入栈管理，present时记录一下VC
    if ([controller isCustomClass]) {
        if (!controller.isFlutterViewController) {
            __block UIViewController *targetController = controller;
            // 如果是FlutterController，则不需要checkNode，因为FlutterViewController已经checkNode了，要去重
            BOOL (^checkBlock)(UIViewController *target) = ^BOOL(UIViewController *target) {
                if ([target isKindOfClass:UINavigationController.class]) {
                    UINavigationController *navi = (UINavigationController *)target;
                    targetController = navi.topViewController;
                    if (navi.dStackRootViewController.isFlutterViewController) {
                        return NO;
                    }
                }
                return YES;
            };
            
            BOOL canCheckNode = YES;
            if ([controller isKindOfClass:UINavigationController.class]) {
                canCheckNode = checkBlock(controller);
            } else if ([controller isKindOfClass:UITabBarController.class]) {
                canCheckNode = checkBlock([(UITabBarController *)controller selectedViewController]);
            }
            if (canCheckNode) {
                NSString *scheme = NSStringFromClass(targetController.class);
                DNode *node = [[DNodeManager sharedInstance] nextPageScheme:scheme
                                                                   pageType:DNodePageTypeNative
                                                                     action:DNodeActionTypePresent
                                                                     params:nil];
                [[DNodeManager sharedInstance] checkNode:node];
            }
        }
    }
    void (^block)(void) = ^(void) {
        if (completion) {
            completion();
        }
        if ([controller isCustomClass]) {
            if (@available(iOS 13.0, *)) {
                UIPresentationController *presentationController = controller.presentationController;
                if (presentationController) {
                    id <UIAdaptivePresentationControllerDelegate> delegate = presentationController.delegate;
                    if (!delegate) {
                        presentationController.delegate = [DStackNavigator instance];
                    } else {
                        NSString *name = NSStringFromClass([delegate class]);
                        presentationController.oldDismissDelegateName = name;
                        [[DStackNavigator instance].dismissDelegateClass setValue:delegate forKey:name];
                        presentationController.delegate = [DStackNavigator instance];
                    }
                }
            }
        }
    };
    [self d_stackPresentViewController:controller animated:flag completion:block];
}

- (void)d_stackDismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    // 出栈管理
    if ([self isCustomClass]) {
        if (![self.dStackFlutterNodeMessage boolValue]) {
            checkNode(self, DNodeActionTypeDismiss);
        }
    }
    self.dStackFlutterNodeMessage = @(NO);
    [self d_stackDismissViewControllerAnimated:flag completion:completion];
}

- (void)d_stackViewWillAppear:(BOOL)animated
{
    [self d_stackViewWillAppear:animated];
    self.isBeginPoped = NO;
    self.isGesturePoped = NO;
    if (hasFDClass()) {
        if (self.dStack_willAppearInjectBlock) {
            self.dStack_willAppearInjectBlock(self, animated);
        }
    }
}
 

- (void)d_stackViewDidDisappear:(BOOL)animated
{
    [self d_stackViewDidDisappear:animated];
    if (![self isFlutterViewController]) {
        [self removeGesturePopNode];
    }
}

- (void)setIsGesturePoped:(BOOL)isGesturePoped
{
    objc_setAssociatedObject(self, @selector(isGesturePoped), @(isGesturePoped), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isGesturePoped
{
    return [objc_getAssociatedObject(self, @selector(isGesturePoped)) boolValue];
}

- (void)setIsBeginPoped:(BOOL)isBeginPoped
{
    objc_setAssociatedObject(self, @selector(isBeginPoped), @(isBeginPoped), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isBeginPoped
{
    return [objc_getAssociatedObject(self, @selector(isBeginPoped)) boolValue];
}

- (void)setDStack_willAppearInjectBlock:(_DStackViewControllerWillAppearInjectBlock)dStack_willAppearInjectBlock
{
    objc_setAssociatedObject(self, @selector(dStack_willAppearInjectBlock), dStack_willAppearInjectBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (_DStackViewControllerWillAppearInjectBlock)dStack_willAppearInjectBlock
{
    return objc_getAssociatedObject(self, @selector(dStack_willAppearInjectBlock));
}

- (BOOL)isFlutterViewController
{
    Class cls = NSClassFromString(@"FlutterViewController");
    if (cls) {
        return [self isKindOfClass:cls];
    }
    return NO;
}

- (void)setDStackFlutterNodeMessage:(NSNumber *)dStackFlutterNodeMessage
{
    objc_setAssociatedObject(self,
                             @selector(dStackFlutterNodeMessage),
                             dStackFlutterNodeMessage,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)dStackFlutterNodeMessage
{
    return objc_getAssociatedObject(self, @selector(dStackFlutterNodeMessage));
}

@end


@implementation UIViewController (DStackFullscreenPopGestureCategory)

- (void)setDStack_interactivePopDisabled:(BOOL)disable
{
    objc_setAssociatedObject(self, @selector(dStack_interactivePopDisabled), @(disable), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)dStack_interactivePopDisabled
{
    return [objc_getAssociatedObject(self, @selector(dStack_interactivePopDisabled)) boolValue];
}

- (void)removeGesturePopNode
{
    if (self.isGesturePoped && self.isBeginPoped) {
        DNode *node = [[DNode alloc] init];
        node.action = DNodeActionTypeGesture;
        node.target = NSStringFromClass(self.class);
        [[DNodeManager sharedInstance] checkNode:node];
    }
}

@end


#pragma mark ########### _DStackFullscreenPopGestureRecognizerDelegate ###########

@interface _DStackFullscreenPopGestureRecognizerDelegate : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UINavigationController *navigationController;

@end

@implementation _DStackFullscreenPopGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    // 判断是否需要手势拦截
    UINavigationController *navigationContoller = self.navigationController;
    UIViewController *topViewController = navigationContoller.viewControllers.lastObject;
    CGPoint touchPoint = [gestureRecognizer locationInView:gestureRecognizer.view];
    if (touchPoint.x > gestureRecognizer.view.frame.size.width / 3.0) {
        // 默认不是全屏滑动返回，更接近原生体验
        return NO;
    }
    
    if (self.navigationController.viewControllers.count <= 1) {
        return NO;
    }

    if (topViewController.dStack_interactivePopDisabled) {
        return NO;
    }
    
    if ([[self.navigationController valueForKey:@"_isTransitioning"] boolValue]) {
        return NO;
    }
    CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view];
    if (translation.x <= 0) {
        return NO;
    }
    
    if (navigationContoller == [DActionManager rootController]) {
        UIViewController *rootViewController = navigationContoller.viewControllers.firstObject;
        if (topViewController == rootViewController) {
            if (topViewController.isFlutterViewController) {
                return NO;
            }
        }
    }
    BOOL shouldBegin = YES;
    if (topViewController.isFlutterViewController) {
        // 如果节点列表是空，说明已经在第一页了并且是Flutter的页面，则直接绕过
        shouldBegin = [[DNodeManager sharedInstance] nativePopGestureCanReponse];
    }
    if (shouldBegin) {
        topViewController.isGesturePoped = YES;
    }
    return shouldBegin;
}

@end


@implementation UINavigationController (DStackNavigationControllerCategory)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL initRootViewController = @selector(initWithRootViewController:);
        SEL newInitRootViewController = @selector(d_StackInitWithRootViewController:);
        dStackSelectorSwizzling([self class], initRootViewController, newInitRootViewController);
        
        SEL push = @selector(pushViewController:animated:);
        SEL newPush = @selector(d_stackPushViewController:animated:);
        dStackSelectorSwizzling([self class], push, newPush);
        
        SEL pop = @selector(popViewControllerAnimated:);
        SEL newPop = @selector(d_stackPopViewControllerAnimated:);
        dStackSelectorSwizzling([self class], pop, newPop);
        
        SEL popTo = @selector(popToViewController:animated:);
        SEL newPopTo = @selector(d_stackPopToViewController:animated:);
        dStackSelectorSwizzling([self class], popTo, newPopTo);
        
        SEL popRoot = @selector(popToRootViewControllerAnimated:);
        SEL newPopRoot = @selector(d_stackPopToRootViewControllerAnimated:);
        dStackSelectorSwizzling([self class], popRoot, newPopRoot);
        
        // 手势拦截处理
        // 兼容FDFullscreenPopGesture
        Class _FDDelegate = NSClassFromString(@"_FDFullscreenPopGestureRecognizerDelegate");
        SEL _FDDelegateSelector = NSSelectorFromString(@"gestureRecognizerShouldBegin:");
        if (_FDDelegate != NULL) {
            if (class_respondsToSelector(_FDDelegate, _FDDelegateSelector)) {
                SEL newFDDelegateSelector = @selector(d_stackGestureRecognizerShouldBegin:);
                Method originalMethod = class_getInstanceMethod(_FDDelegate, _FDDelegateSelector);
                Method swizzledMethod = class_getInstanceMethod([self class], newFDDelegateSelector);
                BOOL didAddMethod = class_addMethod(_FDDelegate,
                                                    newFDDelegateSelector,
                                                    method_getImplementation(originalMethod),
                                                    method_getTypeEncoding(originalMethod));
                if (didAddMethod) {
                    method_exchangeImplementations(originalMethod, swizzledMethod);
                }
            }
        }
    });
}

- (instancetype)d_StackInitWithRootViewController:(UIViewController *)rootViewController
{
    self.dStackRootViewController = rootViewController;
    return [self d_StackInitWithRootViewController:rootViewController];
}

- (void)d_stackPushViewController:(UIViewController *)controller animated:(BOOL)animated
{
    // 入栈管理
    if ([controller isCustomClass]) {
        if (!hasFDClass()) {
            // 没有FDClass，自己加入一份
            if (![self.interactivePopGestureRecognizer.view.gestureRecognizers containsObject:self.dStack_fullscreenPopGestureRecognizer]) {
                [self.interactivePopGestureRecognizer.view addGestureRecognizer:self.dStack_fullscreenPopGestureRecognizer];
                NSArray *internalTargets = [self.interactivePopGestureRecognizer valueForKey:@"targets"];
                id internalTarget = [internalTargets.firstObject valueForKey:@"target"];
                SEL internalAction = NSSelectorFromString(@"handleNavigationTransition:");
                self.dStack_fullscreenPopGestureRecognizer.delegate = self.dStack_popGestureRecognizerDelegate;
                [self.dStack_fullscreenPopGestureRecognizer addTarget:internalTarget action:internalAction];
                self.interactivePopGestureRecognizer.enabled = NO;
            }
            [self dStack_setupViewControllerBasedNavigationBarAppearanceIfNeeded:controller];
        }
        
        if ([controller isFlutterViewController]) {
            controller.hidesBottomBarWhenPushed = YES;
        }
        
        if (!controller.isFlutterViewController && self.dStackRootViewController != controller) {
            // 如果是FlutterController，则不需要checkNode，因为FlutterViewController已经checkNode了，要去重
            checkNode(controller, DNodeActionTypePush);
        }
    }
    [self d_stackPushViewController:controller animated:animated];
}

- (UIViewController *)d_stackPopViewControllerAnimated:(BOOL)animated
{
    // 出栈管理，触发pop动作
    // 手势返回也会触发这个函数注意手势返回的情况，手势一开始滑动就会触发，这时有可能手势滑动了一部分就停掉了
    // 这时该页面并没有被pop出去，要注意这种情况，这情况在d_stackViewDidDisappear处理
    UIViewController *controller = [self d_stackPopViewControllerAnimated:animated];
    if ([controller isCustomClass]) {
        if (![self.dStackFlutterNodeMessage boolValue]) {
            // 如果是FlutterController，则不需要checkNode，因为FlutterViewController已经checkNode了，要去重
            if (!controller.isGesturePoped) {
                // 手势返回的需要特殊处理，手势返回的在 viewDidDisappear 里面处理了
                DNode *node = [[DNode alloc] init];
                node.action = DNodeActionTypePop;
                node.target = NSStringFromClass(controller.class);
                [[DNodeManager sharedInstance] checkNode:node];
            }
        }
    }
    controller.isBeginPoped = YES;
    self.dStackFlutterNodeMessage = @(NO);
    return controller;
}

- (NSArray<UIViewController *> *)d_stackPopToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    // 出栈管理，要注意移除掉当前controller到viewController之间的controller
    if ([viewController isCustomClass]) {
        if (![self.dStackFlutterNodeMessage boolValue]) {
            // 如果是FlutterViewController，会在消息通道里面checkNode
            checkNode(viewController, DNodeActionTypePopTo);
        }
    }
    self.dStackFlutterNodeMessage = @(NO);
    return [self d_stackPopToViewController:viewController animated:animated];
}

- (NSArray<UIViewController *> *)d_stackPopToRootViewControllerAnimated:(BOOL)animated
{
    // 出栈管理，要注意移除掉当前controller到RootViewController之间的controller
    if (![self.dStackFlutterNodeMessage boolValue]) {
        // 如果是FlutterViewController，会在消息通道里面checkNode
        checkNode(self.viewControllers.firstObject, DNodeActionTypePopToRoot);
    }
    self.dStackFlutterNodeMessage = @(NO);
    return [self d_stackPopToRootViewControllerAnimated:animated];
}

- (BOOL)d_stackGestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    UINavigationController *navigationContoller = self.navigationController;
    UIViewController *topViewController = navigationContoller.viewControllers.lastObject;
    BOOL shouldBegin = [self d_stackGestureRecognizerShouldBegin:gestureRecognizer];
    if (shouldBegin) {
        if (navigationContoller == [DActionManager rootController]) {
            UIViewController *rootViewController = navigationContoller.viewControllers.firstObject;
            if (topViewController == rootViewController) {
                if (topViewController.isFlutterViewController) {
                    shouldBegin = NO;
                }
            }
        }
        if (topViewController.isFlutterViewController) {
            // 如果节点列表是空，说明已经在第一页了并且是Flutter的页面，则直接绕过
            if ([DNodeManager sharedInstance].currentNodeList.count) {
                shouldBegin = [[DNodeManager sharedInstance] nativePopGestureCanReponse];
            }
        }
    }
    if (shouldBegin) {
        topViewController.isGesturePoped = YES;
    }
    return shouldBegin;
}

- (void)dStack_setupViewControllerBasedNavigationBarAppearanceIfNeeded:(UIViewController *)appearingViewController
{
    if (!self.dStack_viewControllerBasedNavigationBarAppearanceEnabled) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    _DStackViewControllerWillAppearInjectBlock block = ^(UIViewController *viewController, BOOL animated) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf setNavigationBarHidden:NO animated:animated];
        }
    };
    appearingViewController.dStack_willAppearInjectBlock = block;
    UIViewController *disappearingViewController = self.viewControllers.lastObject;
    if (disappearingViewController && !disappearingViewController.dStack_willAppearInjectBlock) {
        disappearingViewController.dStack_willAppearInjectBlock = block;
    }
}

- (_DStackFullscreenPopGestureRecognizerDelegate *)dStack_popGestureRecognizerDelegate
{
    _DStackFullscreenPopGestureRecognizerDelegate *delegate = objc_getAssociatedObject(self, _cmd);
    if (!delegate) {
        delegate = [[_DStackFullscreenPopGestureRecognizerDelegate alloc] init];
        delegate.navigationController = self;
        objc_setAssociatedObject(self, _cmd, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return delegate;
}

- (UIPanGestureRecognizer *)dStack_fullscreenPopGestureRecognizer
{
    UIPanGestureRecognizer *panGestureRecognizer = objc_getAssociatedObject(self, _cmd);
    if (!panGestureRecognizer) {
        panGestureRecognizer = [[UIPanGestureRecognizer alloc] init];
        panGestureRecognizer.maximumNumberOfTouches = 1;
        objc_setAssociatedObject(self, _cmd, panGestureRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return panGestureRecognizer;
}

- (BOOL)dStack_viewControllerBasedNavigationBarAppearanceEnabled
{
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) {
        return number.boolValue;
    }
    self.dStack_viewControllerBasedNavigationBarAppearanceEnabled = YES;
    return YES;
}

- (void)setDStack_viewControllerBasedNavigationBarAppearanceEnabled:(BOOL)enabled
{
    SEL key = @selector(dStack_viewControllerBasedNavigationBarAppearanceEnabled);
    objc_setAssociatedObject(self, key, @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setDStackRootViewController:(UIViewController *)dStackRootViewController
{
    objc_setAssociatedObject(self, @selector(dStackRootViewController), dStackRootViewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIViewController *)dStackRootViewController
{
    return objc_getAssociatedObject(self, @selector(dStackRootViewController));
}

@end

 
