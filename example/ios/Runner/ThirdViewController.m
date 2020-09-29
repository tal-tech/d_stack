//
//  ThirdViewController.m
//  Runner
//
//  Created by Caven on 2020/8/27.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

#import "ThirdViewController.h"
#import <DStack.h>

@interface ThirdViewController ()<UIAdaptivePresentationControllerDelegate>

@end

@implementation ThirdViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor cyanColor];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 100, 60, 35);
    [button setTitle:@"返回" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeCustom];
    button1.frame = CGRectMake(100, 200, 240, 35);
    [button1 setTitle:@"打开新的Flutter页面" forState:UIControlStateNormal];
    [button1 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [button1 addTarget:self action:@selector(open:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];
    self.presentationController.delegate = self;
}

- (void)back:(UIButton *)button
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)open:(UIButton *)button
{
    [[DStack sharedInstance] pushFlutterPageWithFlutterClass:DFlutterViewController.class
                                                       route:@"page4"];
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController
{
    NSLog(@"self == %@", self);
}

@end
