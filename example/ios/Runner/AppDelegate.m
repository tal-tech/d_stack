#import "AppDelegate.h"
#import <DStack.h>
#import "GeneratedPluginRegistrant.h"
#import "ThirdViewController.h"
#import "FourViewController.h"
#import "DStackViewController.h"
#import "HomeViewController.h"
#import "DemoFlutterViewController.h"
#import "SixViewController.h"

@DStackInject(AppDelegate);

@interface AppDelegate () <DStackDelegate, UITabBarControllerDelegate>

@end

static BOOL isFlutterProject = YES;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [[DStack sharedInstance] startWithDelegate:self];
    [GeneratedPluginRegistrant registerWithRegistry:[DStack sharedInstance].engine];
    [[DStack sharedInstance] logEnable:YES];
    
    UIViewController *rootVC = nil;
    if (isFlutterProject) {
        DemoFlutterViewController *home = [[DemoFlutterViewController alloc] init];
        DStackViewController *navi = [[DStackViewController alloc] initWithRootViewController:home];
        rootVC = navi;
    } else {
        HomeViewController *home = [[HomeViewController alloc] init];
        UITabBarController *tab = [[UITabBarController alloc] init];
        DStackViewController *navi0 = [[DStackViewController alloc] initWithRootViewController:home];
        navi0.tabBarItem.title = @"home";
        
        DemoFlutterViewController *flutter = [[DemoFlutterViewController alloc] init];
        DStackViewController *navi1 = [[DStackViewController alloc] initWithRootViewController:flutter];
        navi1.tabBarItem.title = @"flutter";
        
//        [tab setViewControllers:@[navi1, navi0]];
        [tab setViewControllers:@[navi0, navi1]];
        tab.delegate = self;
        
        rootVC = tab;
    }
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = rootVC;
    [self.window makeKeyAndVisible];
    return YES;
}

/// 当项目中tabBarController的viewControllers里面有DFlutterViewController
/// 或者NavigationViewController的rootViewController是DFlutterViewController作为入口时
/// 项目中必须实现tabBarController的delegate的，
/// - (BOOL)tabBarController:shouldSelectViewController:并且调用DStack的
/// [[DStack sharedInstance] tabBarController:tabBarController willSelectViewController:viewController];
- (BOOL)tabBarController:(UITabBarController *)tabBarController
shouldSelectViewController:(UIViewController *)viewController
{
    [[DStack sharedInstance] tabBarController:tabBarController willSelectViewController:viewController];
    return YES;
}



+ (FlutterEngine *)dStackForFlutterEngine
{
    FlutterEngine *engine = [[FlutterEngine alloc] initWithName:@"io.flutter" project:nil];
    [engine run];
    return engine;
}

- (nonnull UINavigationController *)dStack:(nonnull DStack *)stack navigationControllerForNode:(nonnull DStackNode *)node
{
    return [[self currentController] navigationController];
}

- (void)dStack:(nonnull DStack *)stack presentWithNode:(nonnull DStackNode *)node
{
    UIViewController *didPushController = nil;
//    UINavigationController *navi = [self dStack:stack navigationControllerForNode:node];
    if ([node.route isEqualToString:@"NativePage2"]) {
        didPushController = [[FourViewController alloc] init];
        [[self currentController] presentViewController:didPushController animated:node.animated completion:nil];
    }
}

- (void)dStack:(nonnull DStack *)stack pushWithNode:(nonnull DStackNode *)node
{
    UIViewController *didPushController = nil;
    UINavigationController *navi = [self dStack:stack navigationControllerForNode:node];
    if ([node.route isEqualToString:@"NativePage"]) {
        didPushController = [[ThirdViewController alloc] init];
    } else if ([node.route isEqualToString:@"SixViewController"]) {
        didPushController = [[SixViewController alloc] init];
        didPushController.hidesBottomBarWhenPushed = YES;
    }
    [navi pushViewController:didPushController animated:node.animated];
}

- (nonnull UIViewController *)visibleControllerForCurrentWindow
{
    return [self currentController];
}

-(UIViewController *)currentController
{
    return [self currentControllerFromController:self.rootController];
}

- (UIViewController *)currentControllerFromController:(UIViewController *)controller
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

- (UIViewController *)rootController
{
    UIViewController *rootVC = [UIApplication sharedApplication].delegate.window.rootViewController;
    if (!rootVC) {
        rootVC = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    }
    return rootVC;
}


@end


