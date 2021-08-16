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
#import "DStack.h"
#import "DFlutterViewController.h"

typedef void (^_DStackViewControllerWillAppearInjectBlock)(UIViewController *viewController, BOOL animated);

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

void _checkNodeParams(UIViewController *targetVC, DNodeActionType action, BOOL isFlutter)
{
    if (!targetVC) {return;}
    NSString *scheme = NSStringFromClass(targetVC.class);
    DNode *node = [[DNodeManager sharedInstance] nextPageScheme:scheme
                                                       pageType:DNodePageTypeNative
                                                         action:action
                                                         params:nil];
    NSString *identifier = [NSString stringWithFormat:@"%@_%p",
                            NSStringFromClass(targetVC.class), targetVC];
    node.identifier = identifier;
    if (isFlutter) {
        node.boundary = YES;
        node.fromFlutter = YES;
        node.pageType = DNodePageTypeFlutter;
    }
    [[DNodeManager sharedInstance] checkNode:node];
}

void checkNode(UIViewController *targetVC, DNodeActionType action)
{
    if (action == DNodeActionTypePop ||
        action == DNodeActionTypePopTo ||
        action == DNodeActionTypePopToRoot) {
        if ([targetVC isKindOfClass:DFlutterViewController.class]) {
            DNode *node = [(DFlutterViewController *)targetVC currentNode];
            node.action = action;
            [[DNodeManager sharedInstance] checkNode:node];
        } else {
            _checkNodeParams(targetVC, action, NO);
        }
    } else {
        _checkNodeParams(targetVC, action, NO);
    }
}

UIViewController *_DStackCurrentController(UIViewController *controller)
{
    if (!controller) { return nil;}
    UIViewController *presented = controller.presentedViewController;
    if (presented) { return _DStackCurrentController(presented);}
    if ([controller isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navi = (UINavigationController *)controller;
        if (!navi.viewControllers.count) { return navi;}
        return _DStackCurrentController(navi.topViewController);
    } else if ([controller isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tab = (UITabBarController *)controller;
        if (!tab.viewControllers.count) { return tab;}
        return _DStackCurrentController(tab.selectedViewController);
    } else {
        return controller;
    }
}


#pragma mark ########### 声明 ###########
#pragma mark ########### DStackNavigator ###########

@interface DStackNavigator : NSObject <UIAdaptivePresentationControllerDelegate>

/// dismiss手势代理类列表
@property (nonatomic, strong) NSMapTable <NSString *, id>*dismissDelegateClass;

+ (instancetype)instance;

@end


#pragma mark ########### (DStackDismissGestureCategory) ###########

@interface NSObject (DStackDismissGestureCategory)

@property (nonatomic, copy) NSString *oldDismissDelegateName;

@end


#pragma mark ########### DStackUIViewControllerCategory ###########

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



#pragma mark ########### DStackNavigationControllerCategory ###########

@interface UINavigationController (DStackNavigationControllerCategory)

@property (nonatomic, strong) UIViewController *dStackRootViewController;
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *dStack_fullscreenPopGestureRecognizer;
@property (nonatomic, assign) BOOL dStack_viewControllerBasedNavigationBarAppearanceEnabled;

@end


#pragma mark ########### _DStackFullscreenPopGestureRecognizerDelegate ###########

@interface _DStackFullscreenPopGestureRecognizerDelegate : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UINavigationController *navigationController;

@end



#pragma mark ########### 实现 ###########

@implementation NSObject (DStackDismissGestureCategory)

- (void)setOldDismissDelegateName:(NSString *)oldDismissDelegateName
{
    objc_setAssociatedObject(self, @selector(oldDismissDelegateName), oldDismissDelegateName, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)oldDismissDelegateName
{
    return objc_getAssociatedObject(self, @selector(oldDismissDelegateName));
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
    if (name) {
        id <UIAdaptivePresentationControllerDelegate> oldDelegate = [self.dismissDelegateClass objectForKey:name];
        if (oldDelegate && [oldDelegate respondsToSelector:@selector(adaptivePresentationStyleForPresentationController:)]) {
            return [oldDelegate adaptivePresentationStyleForPresentationController:controller];
        }
    }
    return controller.presentationStyle;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection API_AVAILABLE(ios(8.3))
{
    NSString *name = controller.oldDismissDelegateName;
    if (name) {
        id <UIAdaptivePresentationControllerDelegate> oldDelegate = [self.dismissDelegateClass objectForKey:name];
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
    if (name) {
        id <UIAdaptivePresentationControllerDelegate> oldDelegate = [self.dismissDelegateClass objectForKey:name];
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
    UIViewController *presented = presentationController.presentedViewController;
    presented.isGesturePoped = YES;
    if ([presented isKindOfClass:UINavigationController.class]) {
        presented = [(UINavigationController *)presented topViewController];
    }
    presented.isGesturePoped = YES;
    if (name) {
        id <UIAdaptivePresentationControllerDelegate> oldDelegate = [self.dismissDelegateClass objectForKey:name];
        if (oldDelegate && [oldDelegate respondsToSelector:@selector(presentationControllerShouldDismiss:)]) {
            return [oldDelegate presentationControllerShouldDismiss:presentationController];
        }
    }
    return YES;
}

- (void)presentationControllerWillDismiss:(UIPresentationController *)presentationController API_AVAILABLE(ios(13.0))
{
    UIViewController *presented = presentationController.presentedViewController;
    if ([presented isKindOfClass:UINavigationController.class]) {
        presented = [(UINavigationController *)presented topViewController];
    }
    [self willAppearViewController:presented.presentingViewController];
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
    [self didAppearViewControllerWithGestureDismiss:YES];
    checkNode(target, DNodeActionTypeGesture);
    [self checkSelectorToDelegate:@selector(presentationControllerDidDismiss:)
                       controller:presentationController
                          forward:^(id<UIAdaptivePresentationControllerDelegate> delegate) {
        [delegate presentationControllerDidDismiss:presentationController];
    }];
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
    if (name) {
        id <UIAdaptivePresentationControllerDelegate> delegate = [self.dismissDelegateClass objectForKey:name];
        if (delegate && [delegate respondsToSelector:selector]) {
            if (forward) {
                forward(delegate);
            }
        }
    }
}

- (BOOL)gestureRecognizerShouldBeginWithNavigationController:(UINavigationController *)navigationContoller
{
    UIViewController *topViewController = navigationContoller.viewControllers.lastObject;
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
        shouldBegin = [[DNodeManager sharedInstance] nativePopGestureCanReponse];
    }
    if (shouldBegin) {
        topViewController.isGesturePoped = YES;
    }
    return shouldBegin;
}

- (void)willAppearViewController:(UIViewController *)willAppear
{
    if ([willAppear isKindOfClass:UITabBarController.class]) {
        willAppear = [(UITabBarController *)willAppear selectedViewController];
        if ([willAppear isKindOfClass:UINavigationController.class]) {
            willAppear = [(UINavigationController *)willAppear topViewController];
        }
    } else if ([willAppear isKindOfClass:UINavigationController.class]) {
        willAppear = [(UINavigationController *)willAppear topViewController];
    }
    if ([willAppear isKindOfClass:DFlutterViewController.class]) {
        DStack *stack = [DStack sharedInstance];
        if (!stack.engine.viewController) {
            DFlutterViewController *flutterVC = (DFlutterViewController *)willAppear;
            [flutterVC willUpdateView];
        }
    }
}

- (void)didAppearViewControllerWithGestureDismiss:(BOOL)gesture
{
    DNodeManager *manager = [DNodeManager sharedInstance];
    DNode *didAppearNode = gesture ? [manager preNode] : [manager currentNode];
    if (didAppearNode.pageType == DNodePageTypeFlutter) {
        DStack *stack = [DStack sharedInstance];
        if (stack.engine.viewController) {
            DFlutterViewController *flutterVC = (DFlutterViewController *)stack.engine.viewController;
            [flutterVC didUpdateView];
        }
    }
}

- (NSMapTable<NSString *,id> *)dismissDelegateClass
{
    if (!_dismissDelegateClass) {
        _dismissDelegateClass = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory
                                                          valueOptions:NSPointerFunctionsWeakMemory
                                                              capacity:0];
    }
    return _dismissDelegateClass;
}

@end


#pragma mark ########### DStackUIViewControllerCategory ###########

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

- (void)d_stackPresentViewController:(UIViewController *)controller animated:(BOOL)flag completion:(void (^)(void))completion
{
    void (^block)(void) = ^(void) {
        if (completion) { completion(); }
        if ([controller isCustomClass]) {
            BOOL canPushInStack = YES; // 是否能入栈
            UIPresentationController *presentationController = controller.presentationController;
            if (presentationController) {
                id <UIAdaptivePresentationControllerDelegate> delegate = presentationController.delegate;
                if (!delegate) {
                    presentationController.delegate = [DStackNavigator instance];
                } else {
                    canPushInStack = [(NSObject *)delegate isCustomClass];
                    if (canPushInStack) {
                        NSString *name = NSStringFromClass([delegate class]);
                        presentationController.oldDismissDelegateName = name;
                        [[DStackNavigator instance].dismissDelegateClass setObject:delegate forKey:name];
                        presentationController.delegate = [DStackNavigator instance];
                    }
                }
            }
            if (!controller.isFlutterViewController && canPushInStack) {
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
                    checkNode(targetController, DNodeActionTypePresent);
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
            UIViewController *dismiss = _DStackCurrentController(self);
            if (!dismiss.isGesturePoped && [dismiss isCustomClass] && dismiss.presentingViewController != nil) {
                // 不是手势触发的dismiss
                [[DStackNavigator instance] willAppearViewController:dismiss.presentingViewController];
                checkNode(dismiss, DNodeActionTypeDismiss);
            }
        }
    }
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
    if (self.beingDismissed && !self.isGesturePoped) {
        [[DStackNavigator instance] didAppearViewControllerWithGestureDismiss:NO];
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
        _checkNodeParams(self, DNodeActionTypeGesture, [self isKindOfClass:DFlutterViewController.class]);
    }
}

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
    return [[DStackNavigator instance] gestureRecognizerShouldBeginWithNavigationController:navigationContoller];
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
        
        SEL setViewControllers = @selector(setViewControllers:animated:);
        SEL newSetViewControllers = @selector(d_stackSetViewControllers:animated:);
        dStackSelectorSwizzling([self class], setViewControllers, newSetViewControllers);
        
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

- (void)d_stackSetViewControllers:(NSArray<UIViewController *> *)viewControllers
                         animated:(BOOL)animated
{
    DNode *(^_targetNode)(UIViewController *x) = ^DNode *(UIViewController *x) {
        NSString *identifier = [NSString stringWithFormat:@"%@_%p",
                            NSStringFromClass(x.class), x];
        return [[DNodeManager sharedInstance] nodeWithIdentifier:identifier];
    };
    
    NSArray<UIViewController *> *oldViewControllers = self.viewControllers;
    for (UIViewController *controller in oldViewControllers) {
        // 检查一下是不是有出栈的节点
        if (![viewControllers containsObject:controller]) {
            if (_targetNode(controller)) {
                // 有需要移除的节点
                [self d_stackCheckPopViewControler:controller];
            }
        }
    }
    for (UIViewController *controller in viewControllers) {
        if (!_targetNode(controller)) {
            // 检查不在栈里的controller，需要入栈
            [self d_stackCheckPushViewControler:controller];
        }
    }
    [self d_stackSetViewControllers:viewControllers animated:animated];
}

- (void)d_stackPushViewController:(UIViewController *)controller animated:(BOOL)animated
{
    [self d_stackCheckPushViewControler:controller];
    [self d_stackPushViewController:controller animated:animated];
}

- (UIViewController *)d_stackPopViewControllerAnimated:(BOOL)animated
{
    // 出栈管理，触发pop动作
    // 手势返回也会触发这个函数注意手势返回的情况，手势一开始滑动就会触发，这时有可能手势滑动了一部分就停掉了
    // 这时该页面并没有被pop出去，要注意这种情况，这情况在d_stackViewDidDisappear处理
    UIViewController *controller = [self d_stackPopViewControllerAnimated:animated];
    [self d_stackCheckPopViewControler:controller];
    return controller;
}

- (NSArray<UIViewController *> *)d_stackPopToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    // 出栈管理，要注意移除掉当前controller到viewController之间的controller
    if ([viewController isCustomClass]) {
        if (![self.dStackFlutterNodeMessage boolValue]) {
            checkNode(viewController, DNodeActionTypePopTo);
        }
    }
    if (viewController) {
        return [self d_stackPopToViewController:viewController animated:animated];
    }
    DStackError(@"PopTo的controller为空");
    return @[];
}

- (NSArray<UIViewController *> *)d_stackPopToRootViewControllerAnimated:(BOOL)animated
{
    // 出栈管理，要注意移除掉当前controller到RootViewController之间的controller
    if (![self.dStackFlutterNodeMessage boolValue]) {
        checkNode(self.viewControllers.firstObject, DNodeActionTypePopToRoot);
    }
    return [self d_stackPopToRootViewControllerAnimated:animated];
}

- (void)d_stackCheckPopViewControler:(UIViewController *)controller
{
    if ([controller isCustomClass]) {
        if (![self.dStackFlutterNodeMessage boolValue]) {
            // 如果是FlutterController，则不需要checkNode，因为FlutterViewController已经checkNode了，要去重
            if (!controller.isGesturePoped) {
                // 手势返回的需要特殊处理，手势返回的在 viewDidDisappear 里面处理了
                checkNode(controller, DNodeActionTypePop);
            }
        }
    }
    controller.isBeginPoped = YES;
}

- (void)d_stackCheckPushViewControler:(UIViewController *)controller
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
            if (self.dStackRootViewController != controller && self.viewControllers.count == 1) {
                controller.hidesBottomBarWhenPushed = YES;
            }
        }
        
        if (!controller.isFlutterViewController && self.dStackRootViewController != controller) {
            // 如果是FlutterController，则不需要checkNode，因为FlutterViewController已经checkNode了，要去重
            checkNode(controller, DNodeActionTypePush);
        }
    }
}

- (BOOL)d_stackGestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    UINavigationController *navigationContoller = self.navigationController;
    UIViewController *topViewController = navigationContoller.viewControllers.lastObject;
    BOOL shouldBegin = [self d_stackGestureRecognizerShouldBegin:gestureRecognizer];
    if (shouldBegin) {
        shouldBegin = [[DStackNavigator instance] gestureRecognizerShouldBeginWithNavigationController:navigationContoller];
    }
    if (shouldBegin) {
        topViewController.isGesturePoped = YES;
    }
    return shouldBegin;
}

- (void)dStack_setupViewControllerBasedNavigationBarAppearanceIfNeeded:(UIViewController *)appearingViewController
{
    if (!self.dStack_viewControllerBasedNavigationBarAppearanceEnabled) {return;}
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

 
