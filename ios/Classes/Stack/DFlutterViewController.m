//
//  DFlutterViewController.m
//
//
//  Created by TAL on 2020/1/16.
//

#import "DFlutterViewController.h"
#import "DNodeManager.h"
#import "DActionManager.h"
#import <objc/runtime.h>
#import "DNavigator.h"
#import "DStack.h"

@interface DFlutterViewController ()

/// 当前正在被显示的Node
@property (nonatomic, strong) DNode *currentShowNode;

@end

@implementation DFlutterViewController

- (instancetype)init
{
    if (self.dStackFlutterEngine.viewController) {
        self.dStackFlutterEngine.viewController = nil;
    }
    if(self = [super initWithEngine:self.dStackFlutterEngine
                            nibName:nil
                             bundle:nil]) {
        [self config];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self.dStackFlutterEngine.viewController) {
        self.dStackFlutterEngine.viewController = nil;
    }
    if(self = [super initWithEngine:self.dStackFlutterEngine
                            nibName:nil
                             bundle:nil]) {
        [self config];
    }
    return self;
}

- (void)config
{
    self.view.backgroundColor = [UIColor whiteColor];
    [self addNotification];
}

- (void)viewWillAppear:(BOOL)animated
{
    // 必须在页面显示之前判断engine是否存在FlutterViewController
    // 否则会因为FlutterViewController不存在而崩溃
    if (self.dStackFlutterEngine.viewController != self) {
        self.dStackFlutterEngine.viewController = nil;
        self.dStackFlutterEngine.viewController = self;
    }
    [self checkSelfIsInTabBarController];
    NSString *identifier = [NSString stringWithFormat:@"%p", self];
    [DNodeManager sharedInstance].currentFlutterViewControllerID = identifier;
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    // 刷新一下FlutterViewController的页面，保证当前显示的view是最新的
    [self _surfaceUpdated:YES];
    DNode *topNode = [DNodeManager sharedInstance].currentNode;
    if (topNode.pageType == DNodePageTypeFlutter) {
        [self updateCurrentNode:topNode];
    }
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self removeGesturePopNode];
    [super viewDidDisappear:animated];
}

/// dismiss手势不会触发页面的viewWillAppear
/// viewDidDisappear里面，flutter会让Engine暂停，不会渲染flutter页面
/// 在dismiss的某些情况下，主动调用viewWillAppear，使Engine进入inactive状态
- (void)willUpdateView
{
    [self viewWillAppear:YES];
}

/// dismiss手势不会触发页面的viewDidAppear
/// viewDidDisappear里面，flutter会让Engine暂停，不会渲染flutter页面
/// 在dismiss的某些情况下，主动调用viewDidAppear，使Engine进入resumed状态
- (void)didUpdateView
{
    [self viewDidAppear:YES];
    /// 调用这个是为了重新计算页面的布局
    /// 因为在非全屏present页面时，该页面是没有状态栏的
    /// 所以在dismiss的时候，需要重新展示状态栏，就需要刷新flutter的页面
    [super viewDidLayoutSubviews];
}

- (void)updateCurrentNode:(DNode *)node
{
    _currentShowNode = [node copy];
}

- (id)currentNode
{
    return _currentShowNode;
}

- (void)checkSelfIsInTabBarController
{
    UITabBarController *tabBarController = self.tabBarController;
    if (tabBarController) {
        UIViewController *selectedViewController = tabBarController.selectedViewController;
        if (selectedViewController) {
            UIViewController *visibleVC = [self visibleSelectedViewController:selectedViewController];
            if (visibleVC != self) {return;}
            [DActionManager tabBarWillSelectViewController:selectedViewController
                                             homePageRoute:[DStack sharedInstance].flutterHomePageRoute];
        }
    } else {
        // 检查是不是flutter工程
        if ([DActionManager rootControllerIsFlutterController]) {
            DNode *node = [[DNode alloc] init];
            node.pageType = DNodePageTypeFlutter;
            node.action = DNodeActionTypeReplace;
            node.target = [DStack sharedInstance].flutterHomePageRoute;
            [[DNodeManager sharedInstance] updateRootNode:node];
        }
    }
}

- (UIViewController *)visibleSelectedViewController:(UIViewController *)selectedViewController
{
    if ([selectedViewController isKindOfClass:UINavigationController.class]) {
        return [[(UINavigationController *)selectedViewController viewControllers] firstObject];
    }
    return selectedViewController;
}

- (void)_surfaceUpdated:(BOOL)appeared
{
    SEL sel = NSSelectorFromString(@"surfaceUpdated:");
    if (class_respondsToSelector(self.class, sel)) {
        NSMethodSignature *signature = [self methodSignatureForSelector:sel];
        if (signature) {
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            invocation.selector = sel;
            invocation.target = self;
            [invocation setArgument:&appeared atIndex:2];
            [invocation invoke];
        }
    }
}

- (void)addNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeBottomBarVisible:)
                                                 name:DStackNotificationNameChangeBottomBarVisible
                                               object:nil];
}

- (void)changeBottomBarVisible:(NSNotification *)notification
{
    if (!self.tabBarController) {return;}
    NSDictionary *userInfo = notification.userInfo;
    if (!userInfo) {
        if (self.tabBarController.tabBar.hidden == NO) {
            [self.tabBarController.tabBar setHidden:YES];
        }
    } else {
        BOOL hidden = [userInfo[@"hidden"] boolValue];
        if (self.tabBarController.tabBar.hidden) {
            [self.tabBarController.tabBar setHidden:hidden];
        }
    }
}

- (FlutterEngine *)dStackFlutterEngine
{
    return [DStack sharedInstance].engine;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
