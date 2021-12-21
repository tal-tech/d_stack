/*
 * Created with Android Studio.
 * User: whqfor
 * Date: 2020-02-03
 * Time: 14:20
 * email: wanghuaqiang@tal.com
 * tartget: plugin人口
 */

import 'package:d_stack/channel/dchannel.dart';
import 'package:d_stack/navigator/dnavigator_gesture_observer.dart';
import 'package:d_stack/navigator/dnavigator_manager.dart';
import 'package:d_stack/observer/d_node_observer.dart';
import 'package:d_stack/observer/life_cycle_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PageType { native, flutter }

/// The type of transition to use when pushing/popping a route.
///
/// [TransitionType.custom] must also provide a transition when used.
enum TransitionType {
  native,
  nativeModal,
  inFromLeft,
  inFromTop,
  inFromRight,
  inFromBottom,
  fadeIn, // 渐变
  custom, // 自定义，需要传transitionsBuilder
  material,
  materialFullScreenDialog,
  cupertino,
  cupertinoFullScreenDialog,
  fadeOpaque, // 透明
  fadeAndScale, // 透明缩放
  none, // 无动画
}

const Duration defaultPushDuration = Duration(milliseconds: 300);
const Duration defaultPopDuration = Duration(milliseconds: 250);

typedef DStackWidgetBuilder = WidgetBuilder Function(Map? params);
typedef AnimatedPageBuilder = AnimatedWidget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    WidgetBuilder widgetBuilder);

typedef PushAnimationPageBuilder = AnimatedWidget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child);

class DStack {
  static DChannel? _stackChannel;
  static final DStack _instance = DStack();

  static DStack get instance {
    final MethodChannel _methodChannel = MethodChannel("d_stack");
    _stackChannel = DChannel(_methodChannel);
    return _instance;
  }

  DChannel? get channel => _stackChannel;

  String? _homePageRoute;

  String? get homeRoute => _homePageRoute;

  set homePageRoute(String? route) {
    _homePageRoute = route;
    if (_homePageRoute != null) {
      channel!.sendHomePageRoute(_homePageRoute);
    }
  }

  /// navigatorKey
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// 路由observer
  final DStackNavigatorObserver dStackNavigatorObserver =
      DStackNavigatorObserver();

  /// 用来监听 应用生命周期
  DLifeCycleObserver? dLifeCycleObserver;

  /// 用来监听节点操作
  DNodeObserver? dNodeObserver;

  final Map<String, DStackWidgetBuilder> _pageBuilders =
      <String, DStackWidgetBuilder>{};

  /// 注册DStack
  /// builders 路由的builder
  /// observer 生命周期监听者
  void register(
      {Map<String, DStackWidgetBuilder>? builders,
      DLifeCycleObserver? observer,
      DNodeObserver? nodeObserver}) {
    if (builders?.isNotEmpty == true) {
      _pageBuilders.addAll(builders!);
    }
    dLifeCycleObserver = observer;
    dNodeObserver = nodeObserver;
  }

  /// 获取一个 DStackWidgetBuilder
  /// pageName 路由
  DStackWidgetBuilder pageBuilder(String? pageName) {
    DStackWidgetBuilder? builder = _pageBuilders[pageName!];
    if (builder != null) {
      return builder;
    } else {
      throw Exception('not in the PageRoute');
    }
  }

  /// 获取节点列表
  Future<List<DStackNode>> nodeList() => channel!.getNodeList();

  /// 推出一个页面
  /// routeName 路由名，
  /// pageType native或者flutter,
  /// params 参数
  /// animated 是否有进场动画
  static Future push(String routeName, PageType pageType,
      {Map? params, bool maintainState = true, bool animated = true}) {
    return DNavigatorManager.push(routeName, pageType,
        params: params, maintainState: maintainState, animated: animated);
  }

  /// 弹出一个页面
  /// animated 是否有进场动画
  static Future present(String routeName, PageType pageType,
      {Map? params, bool maintainState = true, bool animated = true}) {
    return DNavigatorManager.present(routeName, pageType,
        params: params, maintainState: maintainState, animated: animated);
  }

  static Future animatedFlutterPage(String routeName, {
    Map? params,
    TransitionType? transition,
    Duration transitionDuration = const Duration(milliseconds: 250),
    RouteTransitionsBuilder? transitionsBuilder,
    bool replace = false,
    bool clearStack = false
  }) {
    return DNavigatorManager.animatedFlutterPage(routeName,
        params: params,
        transition: transition, 
        transitionDuration: transitionDuration,
        transitionsBuilder: transitionsBuilder,
        replace: replace,
        clearStack: clearStack
    );
  }

  /// 自定义进场动画
  /// animationBuilder 进场动画的builder
  /// pushDuration 进场时间
  /// popDuration 退场时间
  /// popGesture 是否支持手势返回
  /// 只有是popGesture为true并且
  /// MaterialApp(ThemeData(platform: TargetPlatform.iOS);
  /// popGesture 才有效
  static Future pushWithAnimation(
    String routeName,
    PageType pageType,
    PushAnimationPageBuilder animationBuilder, {
    Map? params,
    bool replace = false,
    bool popGesture = false,
    Duration pushDuration = defaultPushDuration,
    Duration popDuration = defaultPopDuration,
  }) {
    return DNavigatorManager.pushWithAnimation(
        routeName, pageType, animationBuilder,
        params: params,
        replace: replace,
        pushDuration: pushDuration,
        popDuration: popDuration,
        popGesture: popGesture);
  }

  /// 等同push
  /// builder 页面builder
  /// animated 是否有进场动画
  static Future pushBuild(
      String routeName, PageType pageType, WidgetBuilder builder,
      {Map? params,
      bool maintainState = true,
      bool fullscreenDialog = false,
      bool animated = true}) {
    return DNavigatorManager.pushBuild(routeName, pageType, builder,
        params: params,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
        animated: animated);
  }

  /// 只支持flutter使用，替换flutter页面
  /// animated 是否有进场动画
  static Future replace(
    String routeName,
    PageType pageType, {
    Map? params,
    bool maintainState = true,
    bool fullscreenDialog = false,
    bool animated = true,
    bool homePage = false,
  }) {
    return DNavigatorManager.replace(routeName, pageType,
        params: params,
        maintainState: maintainState,
        homePage: homePage,
        animated: animated,
        fullscreenDialog: fullscreenDialog);
  }

  /// 跳转指定页面并清除剩余所有页面
  static pushAndRemoveUntil(
    String routeName,
    PageType pageType, {
    Map? params,
    bool maintainState = true,
    bool fullscreenDialog = false,
    bool animated = true,
    bool homePage = false,
  }) {
    return DNavigatorManager.pushAndRemoveUntil(routeName, pageType,
        params: params,
        maintainState: maintainState,
        homePage: homePage,
        animated: animated,
        fullscreenDialog: fullscreenDialog);
  }

  /// pop
  /// 可以不传路由信息
  /// result 返回值，可为空
  static void pop({Map? result, bool animated = true}) {
    DNavigatorManager.pop(result: result, animated: animated);
  }

  static Future<bool> maybePop({Map? result, bool animated = true}) {
    return DNavigatorManager.maybePop(result: result, animated: animated);
  }

  /// popTo指定页面
  /// 无法popTo到根页面
  /// 要popTo到根页面请调用popToRoot
  static void popTo(String routeName, PageType pageType,
      {Map? result, bool animated = true}) {
    DNavigatorManager.popTo(routeName, pageType,
        result: result, animated: animated);
  }

  /// pop同一组页面
  static void popSkip(String skipName, {Map? result, bool animated = true}) {
    DNavigatorManager.popSkip(skipName, result: result, animated: animated);
  }

  /// 关闭一个页面
  /// 如果是push进入的，等同pop
  /// 如果是present进入的，效果是从上往下缩回去
  static void dismiss({Map? result, bool animated = true}) {
    DNavigatorManager.dismiss(result: result, animated: animated);
  }

  /// 回到根页面
  static void popToRoot({bool animated = true}) {
    DNavigatorManager.popToRoot(animated: animated);
  }

  @Deprecated('已废弃，请调用popToRoot')
  static void popToNativeRoot() {
    DNavigatorManager.popToRoot();
  }

  /// 自定义转场动画进入页面
  /// flutter页面通过animatedBuilder自定义动画
  /// native页面会转发到native，由native自行接入实现
  /// replace：true flutter的pushReplacement实现
  /// replace：false flutter的push实现
  @Deprecated('已废弃，请使用pushWithAnimation')
  static Future animationPage(
    String routeName,
    PageType pageType,
    AnimatedPageBuilder animatedBuilder, {
    Map? params,
    Duration? transitionDuration,
    bool opaque = true,
    bool barrierDismissible = false,
    Color? barrierColor,
    String? barrierLabel,
    bool maintainState = true,
    bool fullscreenDialog = false,
    bool replace = false,
  }) {
    return DNavigatorManager.animationPage(
        routeName,
        pageType,
        animatedBuilder,
        params,
        transitionDuration,
        opaque,
        barrierDismissible,
        barrierColor,
        barrierLabel,
        maintainState,
        fullscreenDialog,
        replace);
  }
}

class DStackNode {
  final String? route;
  final String? pageType;

  DStackNode({this.route, this.pageType});
}
