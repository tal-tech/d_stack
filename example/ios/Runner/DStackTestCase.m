//
//  DStackTestCase.m
//  Runner
//
//  Created by Caven on 2020/12/4.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//
#import <DStack.h>
#import "DStackTestCase.h"
#import "SecondViewController.h"
#import "FiveViewController.h"
#import "DStackViewController.h"
#import "DemoFlutterViewController.h"
#import "ThirdViewController.h"
#import "CustomViewController.h"

@implementation DStackTestCase
{
    NSArray *_homeDataSource;
    NSArray *_secondVCSource;
    NSArray *_thirdVCSource;
    NSArray *_fourVCSource;
    NSArray *_fiveVCSource;
    NSArray *_sixVCSource;
}

- (instancetype)init
{
    if ([super init]) {
        [self initData];
    }
    return self;
}

- (void)initData
{
    _homeDataSource = @[
        @{
            @"text": @"打开SecondViewController",
            @"clicked": ^(UIViewController *controller) {
                SecondViewController *secondVC = [[SecondViewController alloc] init];
                secondVC.hidesBottomBarWhenPushed = YES;
                [controller.navigationController pushViewController:secondVC animated:YES];
            }
        },
        @{
            @"text": @"打开Flutter page4",
            @"clicked": ^(UIViewController *controller) {
                [[DStack sharedInstance] pushFlutterPageWithFlutterClass:DemoFlutterViewController.class
                                                                   route:@"page4"];
            }
        },
        @{
            @"text": @"打开Flutter page1 有参数",
            @"clicked": ^(UIViewController *controller) {
                [[DStack sharedInstance] pushFlutterPageWithFlutterClass:DemoFlutterViewController.class
                                                                   route:@"page1"
                                                                  params:@{@"fromNative": @"来自原生"}];
            }
        },
    ];
    
    _secondVCSource = @[
        @{
            @"text": @"返回",
            @"clicked": ^(UIViewController *controller) {
                [controller.navigationController popViewControllerAnimated:YES];
            }
        },
        @{
            @"text": @"打开Flutter page5",
            @"clicked": ^(UIViewController *controller) {
                [[DStack sharedInstance] pushFlutterPageWithFlutterClass:DemoFlutterViewController.class
                                                                   route:@"page5"];
            }
        },
        @{
            @"text": @"弹窗",
            @"clicked": ^(UIViewController *controller) {
                CustomViewController *alert = [CustomViewController alertControllerWithTitle:@"弹窗"
                                                                               message:@"弹出来了" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *action = [UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:nil];
                [alert addAction:action];
                [controller presentViewController:alert animated:YES completion:nil];
            }
        },
    ];
    
    _thirdVCSource = @[
        @{
            @"text": @"返回",
            @"clicked": ^(UIViewController *controller) {
                [controller.navigationController popViewControllerAnimated:YES];
            }
        },
        @{
            @"text": @"打开Flutter page6",
            @"clicked": ^(UIViewController *controller) {
                [[DStack sharedInstance] pushFlutterPageWithFlutterClass:DemoFlutterViewController.class
                                                                   route:@"page6"];
            }
        },
        @{
            @"text": @"popTo Flutter page2",
            @"clicked": ^(UIViewController *controller) {
                [[DStack sharedInstance] popToPageWithFlutterRoute:@"page2" params:@{@"test": @"携带参数"} animated:YES];
            }
        },
    ];
    
    _fourVCSource = @[
        @{
            @"text": @"返回",
            @"clicked": ^(UIViewController *controller) {
                [controller dismissViewControllerAnimated:YES completion:nil];
            }
        },
        @{
            @"text": @"弹窗",
            @"clicked": ^(UIViewController *controller) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"弹窗"
                                                                               message:@"弹出来了" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *action = [UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:nil];
                [alert addAction:action];
                [controller presentViewController:alert animated:YES completion:nil];
            }
        },
        @{
            @"text": @"present 无navigation的FiveVC",
            @"clicked": ^(UIViewController *controller) {
                FiveViewController *five = [[FiveViewController alloc] init];
                [controller presentViewController:five animated:YES completion:nil];
            }
        },
        @{
            @"text": @"present 有navigation的FiveVC",
            @"clicked": ^(UIViewController *controller) {
                FiveViewController *five = [[FiveViewController alloc] init];
                DStackViewController *navi = [[DStackViewController alloc] initWithRootViewController:five];
                [controller presentViewController:navi animated:YES completion:nil];
            }
        },
    ];
    
    _fiveVCSource = @[
        @{
            @"text": @"返回",
            @"clicked": ^(UIViewController *controller) {
                if (controller.navigationController.viewControllers.count > 1) {
                    [controller.navigationController popViewControllerAnimated:YES];
                } else {
                    [controller dismissViewControllerAnimated:YES completion:nil];
                }
            }
        },
        @{
            @"text": @"打开Flutter page6",
            @"clicked": ^(UIViewController *controller) {
                [[DStack sharedInstance] pushFlutterPageWithFlutterClass:DemoFlutterViewController.class
                                                                   route:@"page6"];
            }
        },
        @{
            @"text": @"打开FiveViewController",
            @"clicked": ^(UIViewController *controller) {
                FiveViewController *five = [[FiveViewController alloc] init];
                [controller.navigationController pushViewController:five animated:YES];
            }
        },
        @{
            @"text": @"弹窗",
            @"clicked": ^(UIViewController *controller) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"弹窗"
                                                                               message:@"弹出来了" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *action = [UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:nil];
                [alert addAction:action];
                [controller presentViewController:alert animated:YES completion:nil];
            }
        },
        @{
            @"text": @"调取相册",
            @"clicked": ^(UIViewController *controller) {
                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                
                [controller presentViewController:picker animated:YES completion:nil];
            }
        },
        @{
            @"text": @"present 有navigation的FiveVC",
            @"clicked": ^(UIViewController *controller) {
                FiveViewController *five = [[FiveViewController alloc] init];
                DStackViewController *navi = [[DStackViewController alloc] initWithRootViewController:five];
                [controller presentViewController:navi animated:YES completion:nil];
            }
        },
    ];
    
    _sixVCSource = @[
        @{
            @"text": @"返回",
            @"clicked": ^(UIViewController *controller) {
                [controller.navigationController popViewControllerAnimated:YES];
            }
        },
        @{
            @"text": @"popTo flutter page2 有动画",
            @"clicked": ^(UIViewController *controller) {
                [[DStack sharedInstance] popToPageWithFlutterRoute:@"page2" animated:YES];
            }
        },
        @{
            @"text": @"popTo flutter page3 无动画",
            @"clicked": ^(UIViewController *controller) {
                [[DStack sharedInstance] popToPageWithFlutterRoute:@"page3" animated:NO];
            }
        },
        @{
            @"text": @"popTo flutter page4 有动画",
            @"clicked": ^(UIViewController *controller) {
                [[DStack sharedInstance] popToPageWithFlutterRoute:@"page4" animated:YES];
            }
        },
        @{
            @"text": @"popToRoot 有动画",
            @"clicked": ^(UIViewController *controller) {
                [controller.navigationController popToRootViewControllerAnimated:YES];
            }
        },
        @{
            @"text": @"popToRoot 无动画",
            @"clicked": ^(UIViewController *controller) {
                [controller.navigationController popToRootViewControllerAnimated:NO];
            }
        },
        @{
            @"text": @"popTo ThirdViewController",
            @"clicked": ^(UIViewController *controller) {
                UIViewController *target = nil;
                for (UIViewController *x in controller.navigationController.viewControllers) {
                    if ([x isKindOfClass:ThirdViewController.class]) {
                        target = x;
                        break;
                    }
                }
                [controller.navigationController popToViewController:target animated:YES];
            }
        },
        @{
            @"text": @"push flutter page7",
            @"clicked": ^(UIViewController *controller) {
                [[DStack sharedInstance] pushFlutterPageWithFlutterClass:DemoFlutterViewController.class
                                                                   route:@"page7"];
            }
        },
    ];
    
}



- (NSArray<NSDictionary *> *)homeTestCases
{
    return _homeDataSource;
}

- (NSArray<NSDictionary *> *)secondVCTestCases
{
    return _secondVCSource;
}

- (NSArray<NSDictionary *> *)thirdVCTestCases
{
    return _thirdVCSource;
}

- (NSArray<NSDictionary *> *)fourVCTestCases
{
    return _fourVCSource;
}

- (NSArray<NSDictionary *> *)fiveVCTestCases
{
    return _fiveVCSource;
}

- (NSArray<NSDictionary *> *)sixVCTestCases
{
    return _sixVCSource;
}

@end
