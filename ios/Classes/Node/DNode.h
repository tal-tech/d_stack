//
//  DNode.h
//  节点类
//  记录节点信息，把每个page映射成DNode
//
//  Created by TAL on 2020/1/16.
//

#import <Foundation/Foundation.h>
#import "DStackProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// 节点类
@interface DNode : NSObject

/// 页面跳转类型
@property (nonatomic, assign) DNodeActionType action;

/// 页面类型
@property (nonatomic, assign) DNodePageType pageType;

/// 页面唯一标识
/// Flutter页面时是route
/// Native页面时是类名
@property (nonatomic, copy) NSString *target;

/// 附带参数
@property (nonatomic, strong) NSDictionary *params;

/// 是否来自Flutter消息通道的Node
@property (nonatomic, assign) BOOL fromFlutter;

/// 是否可以移除节点
/// 收到didPop消息时才是YES，只有flutter页面会有didDop消息
@property (nonatomic, assign) BOOL canRemoveNode;

/// 是否是flutter的第一个页面
@property (nonatomic, assign) BOOL isFlutterHomePage;

/// 是否开启进场动画
@property (nonatomic, assign) BOOL animated;

/// 是否是临界节点
@property (nonatomic, assign) BOOL boundary;

/// 唯一id
/// 生成规则 controller类名+contorller的内存地址
/// DFlutterViewController_0x28268d1d0
@property (nonatomic, copy) NSString *identifier;

/// 是否是根页面
@property (nonatomic, assign) BOOL isRootPage;

- (NSString *)actionTypeString;
- (NSString *)pageTypeString;
- (NSString *)pageString;
- (void)copyWithNode:(DNode *)node;

+ (DNodePageType)pageTypeWithString:(NSString *)string;
+ (DNodeActionType)actionTypeWithString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
