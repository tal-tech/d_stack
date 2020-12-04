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

@implementation DStackTestCase
{
    NSArray *_homeDatSource;
}

- (instancetype)init
{
    if ([super init]) {
        _homeDatSource = @[
            @{
                @"text": @"打开SecondViewController",
                @"clicked": ^(UIViewController *controller) {
                    SecondViewController *secondVC = [[SecondViewController alloc] init];
                    [controller.navigationController pushViewController:secondVC animated:YES];
                }
            },
            @{
                @"text": @"打开Flutter page1 无参数",
                @"clicked": ^(UIViewController *controller) {
                    [[DStack sharedInstance] pushFlutterPageWithFlutterClass:DFlutterViewController.class
                                                                       route:@"page1"];
                }
            },
            @{
                @"text": @"打开Flutter page1 有参数",
                @"clicked": ^(UIViewController *controller) {
                    [[DStack sharedInstance] pushFlutterPageWithFlutterClass:DFlutterViewController.class
                                                                       route:@"page1"
                                                                      params:@{@"fromNative": @"来自原生"}];
                }
            },
        ];
    }
    return self;
}

- (NSArray<NSDictionary *> *)homeTestCases
{
    return _homeDatSource;
}

@end
