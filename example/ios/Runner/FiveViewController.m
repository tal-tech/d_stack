//
//  FiveViewController.m
//  Runner
//
//  Created by Caven on 2020/12/8.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

#import "FiveViewController.h"

@interface FiveViewController ()

@end

@implementation FiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (NSArray *)dataSource
{
    return self.testCase.fiveVCTestCases;
}

@end
