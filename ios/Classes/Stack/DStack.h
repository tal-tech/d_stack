//
//  DStack.h
//  对外Api，混合栈入口
//
//  Created by TAL on 2020/1/19.
//

#import "DStackProvider.h"

@protocol DStackDelegate;
@class DFlutterViewController;

NS_ASSUME_NONNULL_BEGIN

@interface DStack : NSObject <DStackPluginProtocol>

/// 当前Flutter的Engine
@property (nonatomic, strong, readonly) FlutterEngine *engine;
@property (nonatomic, readonly, nonnull) id<DStackDelegate>delegate;

+ (instancetype)sharedInstance;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/// 启动混合栈
/// @param delegate 混合栈的代理
- (void)startWithDelegate:(id<DStackDelegate>)delegate;

/// 清除本地日志
- (void)cleanLogFiles;

/// 是否为debug模式
- (BOOL)debugMode;

/// 是否开启log打印
/// @param enable enable
- (void)logEnable:(BOOL)enable;

/// push打开一个flutter页面
/// @param cls 当前DFlutterViewController的class或它的子类
/// @param route flutter页面的route
- (void)pushFlutterPageWithFlutterClass:(Class)cls
                                  route:(NSString *)route;

/// push打开一个flutter页面
/// @param cls 当前DFlutterViewController的class或它的子类
/// @param route  flutter页面的route
/// @param params 传递给flutter页面的参数
- (void)pushFlutterPageWithFlutterClass:(Class)cls
                                  route:(NSString *)route
                                 params:(nullable NSDictionary *)params;

/// push打开一个flutter页面
/// @param cls 当前DFlutterViewController的class或它的子类
/// @param route  flutter页面的route
/// @param params 传递给flutter页面的参数
/// @param animated 是否开启转场动画
- (void)pushFlutterPageWithFlutterClass:(Class)cls
                                  route:(NSString *)route
                                 params:(nullable NSDictionary *)params
                               animated:(BOOL)animated;

/// push打开一个flutter页面
/// @param cls 当前DFlutterViewController的class或它的子类
/// @param route  flutter页面的route
/// @param params 传递给flutter页面的参数
/// @param callBack 回调出当前的DFlutterViewController
/// @param animated 是否开启转场动画
- (void)pushFlutterPageWithFlutterClass:(Class)cls
                                  route:(NSString *)route
                                 params:(nullable NSDictionary *)params
                     controllerCallBack:(nullable void (^)(DFlutterViewController *))callBack
                               animated:(BOOL)animated;

/// push打开一个flutter页面
/// 当前的FlutterViewController是从storyboard加载时调用
/// @param storyboard storyboardName
/// @param identifier identifier
/// @param route flutter页面的route
/// @param params 传递给flutter页面的参数
/// @param animated 是否开启转场动画
- (void)pushFlutterPageWithStoryboard:(NSString *)storyboard
                           identifier:(NSString *)identifier
                                route:(NSString *)route
                               params:(nullable NSDictionary *)params
                             animated:(BOOL)animated;

/// push打开一个flutter页面
/// 当前的FlutterViewController是从storyboard加载时调用
/// @param storyboard storyboardName
/// @param identifier identifier
/// @param route flutter页面的route
/// @param params 传递给flutter页面的参数
/// @param callBack 回调出当前的DFlutterViewController
/// @param animated 是否开启转场动画
- (void)pushFlutterPageWithStoryboard:(NSString *)storyboard
                           identifier:(NSString *)identifier
                                route:(NSString *)route
                               params:(nullable NSDictionary *)params
                   controllerCallBack:(nullable void (^)(DFlutterViewController *))callBack
                             animated:(BOOL)animated;

/// present打开一个flutter页面
/// @param cls 当前DFlutterViewController的class或它的子类
/// @param route  flutter页面的route
/// @param from 起点controller
- (void)presentFlutterPageWithFlutterClass:(Class)cls
                                     route:(NSString *)route
                                      from:(UIViewController *)from;

/// present打开一个flutter页面
/// @param cls 当前DFlutterViewController的class或它的子类
/// @param route flutter页面的route
/// @param params 传递给flutter页面的参数
/// @param from 起点controller
- (void)presentFlutterPageWithFlutterClass:(Class)cls
                                     route:(NSString *)route
                                    params:(nullable NSDictionary *)params
                                      from:(UIViewController *)from;

/// present打开一个flutter页面
/// @param cls 当前DFlutterViewController的class或它的子类
/// @param route flutter页面的route
/// @param params 传递给flutter页面的参数
/// @param animated 是否开启转场动画
/// @param from 起点controller
/// @param root cls对应的controller所属的rootViewController
/// root有两种情况：root：UINavigationController、UITabBarController
- (void)presentFlutterPageWithFlutterClass:(Class)cls
                                     route:(NSString *)route
                                    params:(nullable NSDictionary *)params
                                  animated:(BOOL)animated
                                      from:(UIViewController *)from
                            rootController:(nullable Class)root;

/// present打开一个flutter页面
/// @param cls 当前DFlutterViewController的class或它的子类
/// @param route flutter页面的route
/// @param params 传递给flutter页面的参数
/// @param animated 是否开启转场动画
/// @param from 起点controller
/// @param callBack 回调出当前的DFlutterViewController
/// @param root cls对应的controller所属的rootViewController
/// root有两种情况：root：UINavigationController、UITabBarController
- (void)presentFlutterPageWithFlutterClass:(Class)cls
                                     route:(NSString *)route
                                    params:(nullable NSDictionary *)params
                                  animated:(BOOL)animated
                                      from:(UIViewController *)from
                        controllerCallBack:(nullable void (^)(DFlutterViewController *))callBack
                            rootController:(nullable Class)root;

/// present打开一个flutter页面
/// 当前的FlutterViewController是从storyboard加载时调用
/// @param storyboard storyboardName
/// @param identifier identifier
/// @param route flutter页面的route
/// @param params 传递给flutter页面的参数
/// @param animated 是否开启转场动画
/// @param from 起点controller
/// @param root cls对应的controller所属的rootViewController
/// root有两种情况：root：UINavigationController、UITabBarController
- (void)presentFlutterPageWithStoryboard:(NSString *)storyboard
                              identifier:(NSString *)identifier
                                   route:(NSString *)route
                                  params:(nullable NSDictionary *)params
                                animated:(BOOL)animated
                                    from:(UIViewController *)from
                          rootController:(nullable Class)root;


/// present打开一个flutter页面
/// 当前的FlutterViewController是从storyboard加载时调用
/// @param storyboard storyboardName
/// @param identifier identifier
/// @param route flutter页面的route
/// @param params 传递给flutter页面的参数
/// @param animated 是否开启转场动画
/// @param from 起点controller
/// @param callBack 回调出当前的DFlutterViewController
/// @param root cls对应的controller所属的rootViewController
/// root有两种情况：root：UINavigationController、UITabBarController
- (void)presentFlutterPageWithStoryboard:(NSString *)storyboard
                              identifier:(NSString *)identifier
                                   route:(NSString *)route
                                  params:(nullable NSDictionary *)params
                                animated:(BOOL)animated
                                    from:(UIViewController *)from
                      controllerCallBack:(nullable void (^)(DFlutterViewController *))callBack
                          rootController:(nullable Class)root;


/// 返回到指定的Flutter page
/// 方法调用时机：如果需要popTo的页面是Flutter页面时，必须调用该方法实现
/// 如果popTo的页面是Native页面，则使用navigationController的  popToViewController:animated:
/// @param route page的路由
/// @param animated 返回动画  只对Native页面有效
- (void)popToPageWithFlutterRoute:(NSString *)route
                         animated:(BOOL)animated;

/// 返回到指定的Flutter page
/// 方法调用时机：如果需要popTo的页面是Flutter页面时，必须调用该方法实现
/// 如果popTo的页面是Native页面，则使用navigationController的  popToViewController:animated:
/// @param route route page的路由
/// @param params 携带参数
/// @param animated 返回动画
- (void)popToPageWithFlutterRoute:(NSString *)route
                           params:(nullable NSDictionary *)params
                         animated:(BOOL)animated;

@end


@interface DStackNode : NSObject

/// 页面类型
@property (nonatomic, assign) DNodePageType pageType;
/// 跳转类型
@property (nonatomic, assign) DNodeActionType actionType;
/// 页面路由
@property (nonatomic, copy, nullable) NSString *route;
/// 携带参数
@property (nonatomic, strong, nullable) NSDictionary *params;

@end


@protocol DStackDelegate <NSObject>

@required

/// 用户需要创建FlutterEngine返回
+ (FlutterEngine *)dStackForFlutterEngine;

/// 当前正在显示的controller
/// DStack 1.3.0版本以上必须实现
- (UIViewController *)visibleControllerForCurrentWindow;

/// 用户实现返回目标route的navigationController
/// @param stack stack
/// @param node node
- (UINavigationController *)dStack:(DStack *)stack navigationControllerForNode:(DStackNode *)node;

/// 用户实现push跳转
/// @param stack stack
/// @param node 节点信息
- (void)dStack:(DStack *)stack pushWithNode:(DStackNode *)node;

/// 用户实现present跳转
/// @param stack stack
/// @param node 节点信息
- (void)dStack:(DStack *)stack presentWithNode:(DStackNode *)node;


@optional

/// 入栈成功的回调
/// @param stack stack
/// @param nodes 入栈节点列表
- (void)dStack:(DStack *)stack inStack:(NSArray <DStackNode *>*)nodes;

/// 出栈成功的回调
/// @param stack stack
/// @param nodes 出栈节点列表
- (void)dStack:(DStack *)stack outStack:(NSArray <DStackNode *>*)nodes;

/// 节点显示与消失
/// @param stack stack
/// @param appear 正在显示的node
/// @param disappear 消失的node
- (void)dStack:(DStack *)stack
        appear:(nullable DStackNode *)appear
     disappear:(nullable DStackNode *)disappear;

/// 应用生命周期回调
/// @param stack stack
/// @param state 应用状态
/// @param visibleNode 屏幕正在显示的node
- (void)dStack:(DStack *)stack
applicationState:(DStackApplicationState)state
   visibleNode:(nullable DStackNode *)visibleNode;

@end

NS_ASSUME_NONNULL_END

