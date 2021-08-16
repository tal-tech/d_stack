//
//  DNodeManager.h
//  管理节点信息
//
//  Created by TAL on 2020/1/16.
//

#import <Foundation/Foundation.h>
#import "DNode.h"

NS_ASSUME_NONNULL_BEGIN

/// Node节点管理器
/// 全链路全节点记录
/// Flutter页面打开、关闭都会发消息至Native侧进行节点管理
/// Native页面打开、关闭都会发消息至Native侧进行节点管理
@interface DNodeManager : NSObject

/// 当前的节点列表
@property (nonatomic, strong, readonly) NSArray <DNode *>*currentNodeList;

/// 当前显示的节点
@property (nonatomic, strong, readonly, nullable) DNode *currentNode;

/// 当前显示的节点的前一个节点
@property (nonatomic, strong, readonly, nullable) DNode *preNode;

/// 每次被移除的节点列表
@property (nonatomic, strong, nullable) NSArray <DNode *>*removedNodes;

/// 当前被显示的FlutterViewControllerID
@property (nonatomic, copy, nullable) NSString *currentFlutterViewControllerID;

+ (instancetype)sharedInstance;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/// 配置日志信息
- (void)configLogFileWithDebugMode:(BOOL)debugMode;

/// 清除本地日志
- (void)cleanLogFile;

/// 检查节点
/// @param node 节点信息
- (NSArray <DNode *>*)checkNode:(DNode *)node;

/// 根据target从nodeLlist获取，倒序查找
/// @param target target
- (nullable DNode *)nodeWithTarget:(NSString *)target;

/// 根据identifier从nodeLlist获取，倒序查找
/// @param identifier identifier
- (nullable DNode *)nodeWithIdentifier:(NSString *)identifier;

/// 原生页面的pop返回手势能否响应
/// 判断逻辑
/// NodeList的最后一个节点就是当前页面正在显示的页面
/// 取出最后一个节点，判断该节点的前面一个节点
/// 如果前一个节点是Flutter页面，则原生页面的pop返回手势不能响应，否则可以响应
- (BOOL)nativePopGestureCanReponse;

/// 创建节点
/// @param scheme 节点标识
/// @param pageType 下一页面类型
/// @param actionType 跳转类型
/// @param params 附带参数
- (DNode *)nextPageScheme:(NSString *)scheme
                 pageType:(DNodePageType)pageType
                   action:(DNodeActionType)actionType
                   params:(nullable NSDictionary *)params;

/// 应用生命周期消息
/// @param state 应用的生命周期
- (void)sendAppliccationLifeCicleToFlutter:(DStackApplicationState)state;

/// 更新临界节点
/// @param nodeInfo nodeInfo
- (void)updateBoundaryNode:(NSDictionary *)nodeInfo;

/// 更新根节点信息
/// @param node node
- (BOOL)updateRootNode:(DNode *)node;

/// 获取日志文件内容
- (nullable NSArray<NSString *> *)logFiles;

@end

NS_ASSUME_NONNULL_END
