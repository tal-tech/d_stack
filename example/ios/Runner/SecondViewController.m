//
//  SecondViewController.m
//  Runner
//
//  Created by TAL on 2020/2/11.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

#import "SecondViewController.h"
#import "ThirdViewController.h"

@interface SecondViewController ()

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (NSArray *)dataSource
{
    return self.testCase.secondVCTestCases;
}



@end
