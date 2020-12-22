//
//  HomeViewController.h
//  Runner
//
//  Created by TAL on 2020/2/11.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DStackTestCase.h"

NS_ASSUME_NONNULL_BEGIN

@interface HomeViewController : UIViewController

@property (nonatomic, strong) DStackTestCase *testCase;


- (NSArray *)dataSource;

@end

NS_ASSUME_NONNULL_END
