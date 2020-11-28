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
import 'package:d_stack/observer/life_cycle_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PageType { native, flutter }

typedef DStackWidgetBuilder = WidgetBuilder Function(Map params);
typedef AnimatedPageBuilder = AnimatedWidget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    WidgetBuilder widgetBuilder);

class DStack {
  static DChannel _stackChannel;
  static final DStack _instance = DStack();

  static DStack get instance {
    final MethodChannel _methodChannel = MethodChannel("d_stack");
    _stackChannel = DChannel(_methodChannel);
    return _instance;
  }

  DChannel get channel => _stackChannel;

  /// navigatorKey
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// 路由observer
  final DStackNavigatorObserver dStackNavigatorObserver =
      DStackNavigatorObserver();

  /// 用来监听 应用生命周期
  DLifeCycleObserver dLifeCycleObserver;

  final Map<String, DStackWidgetBuilder> _pageBuilders =
      <String, DStackWidgetBuilder>{};

  /// 注册DStack
  /// builders 路由的builder
  /// observer 生命周期监听者
  void register(
      {Map<String, DStackWidgetBuilder> builders,
      DLifeCycleObserver observer}) {
    if (builders?.isNotEmpty == true) {
      _pageBuilders.addAll(builders);
    }
    dLifeCycleObserver = observer;
  }

  /// 获取一个 DStackWidgetBuilder
  /// pageName 路由
  DStackWidgetBuilder pageBuilder(String pageName) {
    DStackWidgetBuilder builder = _pageBuilders[pageName];
    if (builder != null) {
      return builder;
    } else {
      throw Exception('not in the PageRoute');
    }
  }

  /// 获取节点列表
  Future<List<DStackNode>> nodeList() {
    return channel.getNodeList();
  }

  /// 推出一个页面
  /// routeName 路由名，
  /// pageType native或者flutter,
  /// params 参数
  /// animated 是否有进场动画
  static Future push(String routeName, PageType pageType,
      {Map params, bool maintainState = true, bool animated = true}) {
    return DNavigatorManager.push(
        routeName, pageType, params, maintainState, animated);
  }

  /// 弹出一个页面
  /// animated 是否有进场动画
  static Future present(String routeName, PageType pageType,
      {Map params, bool maintainState = true, bool animated = true}) {
    return DNavigatorManager.present(
        routeName, pageType, params, maintainState, animated);
  }

  /// 自定义转场动画进入页面
  /// flutter页面通过animatedBuilder自定义动画
  /// native页面会转发到native，由native自行接入实现
  /// replace：true flutter的pushReplacement实现
  /// replace：false flutter的push实现
  static Future animationPage(
    String routeName,
    PageType pageType,
    AnimatedPageBuilder animatedBuilder, {
    Map params,
    Duration transitionDuration,
    bool opaque = true,
    bool barrierDismissible = false,
    Color barrierColor,
    String barrierLabel,
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

  /// 等同push
  /// builder 页面builder
  /// animated 是否有进场动画
  static Future pushBuild(
      String routeName, PageType pageType, WidgetBuilder builder,
      {Map params,
      bool maintainState = true,
      bool fullscreenDialog = false,
      bool animated = true}) {
    return DNavigatorManager.pushBuild(routeName, pageType, builder, params,
        maintainState, fullscreenDialog, animated);
  }

  /// 只支持flutter使用，替换flutter页面
  /// animated 是否有进场动画
  static Future replace(String routeName, PageType pageType,
      {Map params,
      bool maintainState = true,
      bool fullscreenDialog = false,
      bool animated = true}) {
    return DNavigatorManager.replace(
        routeName, pageType, params, maintainState, animated);
  }

  /// pop
  /// 可以不传路由信息
  /// result 返回值，可为空
  static void pop({Map result}) {
    DNavigatorManager.pop(result);
  }

  /// popTo指定页面
  /// 无法popTo到根页面
  /// 要popTo到根页面请调用popToRoot
  static void popTo(String routeName, PageType pageType, {Map result}) {
    DNavigatorManager.popTo(routeName, pageType, result);
  }

  /// 回到根页面
  static void popToRoot() {
    DNavigatorManager.popToNativeRoot();
  }

  /// pop同一组页面
  static void popSkip(String skipName, {Map result}) {
    DNavigatorManager.popSkip(skipName, result);
  }

  /// 关闭一个页面
  /// 如果是push进入的，等同pop
  /// 如果是present进入的，效果是从上往下缩回去
  static void dismiss([Map result]) {
    DNavigatorManager.dismiss(result);
  }

  @Deprecated('已废弃，请调用popToRoot')
  static void popToNativeRoot() {
    DNavigatorManager.popToNativeRoot();
  }
}

class DStackNode {
  final String route;
  final String pageType;
  DStackNode({this.route, this.pageType});
}
