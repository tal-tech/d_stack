//
//  DNavigator.m
//  d_stack
//  
//  Created by TAL on 2020/2/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 该类主要用于拦截所有push、present、pop、dismiss等事件
/// 用于全链路全节点记录
@interface UIViewController (DStackFullscreenPopGestureCategory)

/// 是否开启手势返回
@property (nonatomic, assign) BOOL dStack_interactivePopDisabled;

- (void)removeGesturePopNode;

@end

NS_ASSUME_NONNULL_END
