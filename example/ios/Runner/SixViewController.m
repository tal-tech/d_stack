//
//  SixViewController.m
//  Runner
//
//  Created by Caven on 2020/12/9.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

#import "SixViewController.h"

@interface SixViewController ()

@end

@implementation SixViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (NSArray *)dataSource
{
    return self.testCase.sixVCTestCases;
}

@end
