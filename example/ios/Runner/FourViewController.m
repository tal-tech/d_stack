//
//  FourViewController.m
//  Runner
//
//  Created by Caven on 2020/8/27.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

#import "FourViewController.h"

@interface FourViewController ()<UIAdaptivePresentationControllerDelegate>

@end

@implementation FourViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.presentationController.delegate = self;
}

- (NSArray *)dataSource
{
    return self.testCase.fourVCTestCases;
}

@end
