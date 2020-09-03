//
//  DFlutterViewController.m
//
//
//  Created by TAL on 2020/1/16.
//

#import "DFlutterViewController.h"
#import "DNodeManager.h"
#import <objc/runtime.h>
#import "DNavigator.h"
#import "DStack.h"

@implementation DFlutterViewController

- (instancetype)init
{
    if(self = [super initWithEngine:[DStack sharedInstance].engine
                            nibName:nil
                             bundle:nil]) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if(self = [super initWithEngine:[DStack sharedInstance].engine
                            nibName:nil
                             bundle:nil]) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    // 必须在页面显示之前判断engine是否存在FlutterViewController
    // 否则会因为FlutterViewController不存在而崩溃
    if ([DStack sharedInstance].engine.viewController != self) {
        [DStack sharedInstance].engine.viewController = self;
    }
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    // 刷新一下FlutterViewController的页面，保证当前显示的view是最新的
    [self _surfaceUpdated:YES];
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self removeGesturePopNode];
    [[DNodeManager sharedInstance] resetHomePage];
    [super viewDidDisappear:animated];
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

@end
