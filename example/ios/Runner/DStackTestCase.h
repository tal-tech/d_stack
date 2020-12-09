//
//  DStackTestCase.h
//  Runner
//
//  Created by Caven on 2020/12/4.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DStackTestCase : NSObject

@property (nonatomic, readonly) NSArray <NSDictionary *>*homeTestCases;
@property (nonatomic, readonly) NSArray <NSDictionary *>*secondVCTestCases;
@property (nonatomic, readonly) NSArray <NSDictionary *>*thirdVCTestCases;
@property (nonatomic, readonly) NSArray <NSDictionary *>*fourVCTestCases;
@property (nonatomic, readonly) NSArray <NSDictionary *>*fiveVCTestCases;
@property (nonatomic, readonly) NSArray <NSDictionary *>*sixVCTestCases;

@end

NS_ASSUME_NONNULL_END
