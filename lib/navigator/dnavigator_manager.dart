/*
 * Created with Android Studio.
 * User: whqfor
 * Date: 2020-02-03
 * Time: 14:20
 * email: wanghuaqiang@tal.com
 * tartget: flutter侧用户调用入口
 */

import 'dart:io';

import 'package:d_stack/constant/constant_config.dart';
import 'package:d_stack/d_stack.dart';
import 'package:d_stack/navigator/dnavigator_gesture_observer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 主要两个部分：
/// 1.发送节点信息到Native，Native记录完整的路由信息
/// 2.处理Native发过来的指令，Native侧节点管理处理完节点信息，如果有指令过来，则flutter根据节点信息做相应的跳转事件

class DNavigatorManager {
  /// 1.发送节点信息到Native
  /// routeName 路由名，pageType native或者flutter, params 参数

  /// 获取navigator
  static NavigatorState get _navigator =>
      DStack.instance.navigatorKey.currentState;

  static Future push(String routeName, PageType pageType,
      {Map params, bool maintainState, bool animated = true}) {
    if (pageType == PageType.flutter) {
      DNavigatorManager.nodeHandle(routeName, pageType, DStackConstant.push,
          result: {}, animated: animated);
      var route = DNavigatorManager.materialRoute(
          routeName: routeName,
          params: params,
          maintainState: maintainState,
          pushAnimated: animated);
      return _navigator.push(route);
    } else {
      DNavigatorManager.nodeHandle(routeName, pageType, DStackConstant.push,
          result: params, animated: animated);
      return Future.value(true);
    }
  }

  /// 弹出页面
  static Future present(String routeName, PageType pageType,
      {Map params, bool maintainState, bool animated = true}) {
    if (pageType == PageType.flutter) {
      DNavigatorManager.nodeHandle(routeName, pageType, DStackConstant.present,
          result: {}, animated: animated);
      var route = DNavigatorManager.materialRoute(
          routeName: routeName,
          params: params,
          maintainState: maintainState,
          pushAnimated: animated,
          fullscreenDialog: true);
      return _navigator.push(route);
    } else {
      DNavigatorManager.nodeHandle(routeName, pageType, DStackConstant.present,
          result: params, animated: animated);
      return Future.value(true);
    }
  }

  static Future pushWithAnimation(
    String routeName,
    PageType pageType,
    PushAnimationPageBuilder animationBuilder, {
    Map params,
    bool replace,
    Duration pushDuration,
    Duration popDuration,
  }) {
    RouteSettings userSettings =
        RouteSettings(name: routeName, arguments: params);
    DStackWidgetBuilder stackWidgetBuilder =
        DStack.instance.pageBuilder(routeName);
    WidgetBuilder builder = stackWidgetBuilder(params);

    _DStackPageRouteBuilder route = _DStackPageRouteBuilder(
      pageBuilder: builder,
      settings: userSettings,
      pushTransition: pushDuration,
      popTransition: popDuration,
    );

    return Future.value(false);
  }

  /// 自定义进场方式
  static Future animationPage(
    String routeName,
    PageType pageType,
    AnimatedPageBuilder animatedBuilder, [
    Map params,
    Duration transitionDuration = defaultPushDuration,
    bool opaque = true,
    bool barrierDismissible = false,
    Color barrierColor,
    String barrierLabel,
    bool maintainState = true,
    bool fullscreenDialog = false,
    bool replace = false,
  ]) {
    if (pageType == PageType.flutter) {
      DNavigatorManager.nodeHandle(routeName, pageType, DStackConstant.push,
          result: {});
      PageRouteBuilder route = DNavigatorManager.animationRoute(
        animatedBuilder: animatedBuilder,
        routeName: routeName,
        params: params,
        transitionDuration: transitionDuration,
        opaque: opaque,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      );
      if (replace) {
        return _navigator.pushReplacement(route);
      } else {
        return _navigator.push(route);
      }
    } else {
      DNavigatorManager.nodeHandle(routeName, pageType, DStackConstant.push,
          result: params);
      return Future.value(true);
    }
  }

  /// 提供外界直接传builder的能力
  static Future pushBuild(
      String routeName, PageType pageType, WidgetBuilder builder,
      {Map params,
      bool maintainState,
      bool fullscreenDialog,
      bool animated = true}) {
    if (pageType == PageType.flutter) {
      DNavigatorManager.nodeHandle(
          routeName, PageType.flutter, DStackConstant.push,
          result: {}, animated: animated);
      var route = DNavigatorManager.materialRoute(
          routeName: routeName,
          params: params,
          maintainState: maintainState,
          pushAnimated: animated,
          fullscreenDialog: fullscreenDialog,
          builder: builder);
      return _navigator.push(route);
    } else {
      DNavigatorManager.nodeHandle(routeName, pageType, DStackConstant.push,
          result: params, animated: animated);
      return Future.value(true);
    }
  }

  /// 目前只支持flutter使用，替换flutter页面
  static Future replace(String routeName, PageType pageType,
      {Map params,
      bool maintainState = true,
      bool homePage = false,
      bool animated = true,
      bool fullscreenDialog = false}) {
    DNavigatorManager.nodeHandle(routeName, pageType, DStackConstant.replace,
        result: params, homePage: homePage, animated: animated);
    if (pageType == PageType.flutter) {
      var route = DNavigatorManager.materialRoute(
          routeName: routeName,
          params: params,
          maintainState: maintainState,
          pushAnimated: animated,
          fullscreenDialog: fullscreenDialog);
      return _navigator.pushReplacement(route);
    } else {
      return Future.error('not flutter page');
    }
  }

  /// result 返回值，可为空
  /// pop可以不传路由信息
  static void pop({Map result, bool animated = true}) {
    DNavigatorManager.nodeHandle(null, null, DStackConstant.pop,
        result: result, animated: animated);
  }

  static void popWithGesture() {
    DNavigatorManager.nodeHandle(null, null, DStackConstant.gesture);
  }

  static void popTo(String routeName, PageType pageType,
      {Map result, bool animated = true}) {
    DNavigatorManager.nodeHandle(routeName, pageType, DStackConstant.popTo,
        result: result, animated: animated);
  }

  static void popToRoot({bool animated = true}) {
    DNavigatorManager.nodeHandle(null, null, DStackConstant.popToRoot,
        animated: animated);
  }

  static void popToNativeRoot() {
    DNavigatorManager.nodeHandle(null, null, 'popToNativeRoot');
  }

  static void popSkip(String skipName, {Map result, bool animated = true}) {
    DNavigatorManager.nodeHandle(skipName, null, DStackConstant.popSkip,
        result: result, animated: animated);
  }

  static void dismiss({Map result, bool animated = true}) {
    DNavigatorManager.nodeHandle(null, null, DStackConstant.dismiss,
        result: result, animated: animated);
  }

  static void nodeHandle(String target, PageType pageType, String actionType,
      {Map result, bool homePage, bool animated = true}) {
    Map arguments = {
      'target': target,
      'pageType': '$pageType'.split('.').last,
      'params': (result != null) ? result : {},
      'actionType': actionType,
      'homePage': homePage,
      'animated': animated
    };
    DStack.instance.channel.sendNodeToNative(arguments);
  }

  static void removeFlutterNode(String target) {
    String actionType = (Platform.isAndroid ? 'pop' : 'didPop');
    Map arguments = {
      'target': target,
      'pageType': 'flutter',
      'actionType': actionType
    };
    DStack.instance.channel.sendRemoveFlutterPageNode(arguments);
  }

  // 记录节点进出，如果已经是首页，则不再pop
  static Future gardPop([Map params, bool animated = true]) {
    if (DStackNavigatorObserver.instance.routerCount <= 1) {
      return Future.value('已经是首页，不再出栈');
    }
    _navigator.pop(_DStackPopResult<Map>(animated: animated, result: params));
    return Future.value(true);
  }

  /// 2.处理Native发过来的指令
  /// argument里包含必选参数routeName，actionTpye，可选参数params
  static Future handleActionToFlutter(Map arguments) {
    // 处理实际跳转
    debugPrint("【sendActionToFlutter】 \n"
        "【arguments】$arguments \n"
        "【navigator】$_navigator ");
    final String action = arguments['action'];
    final List nodes = arguments['nodes'];
    final Map params = arguments['params'];
    bool homePage = arguments["homePage"];
    bool animated = arguments['animated'];
    final Map pageTypeMap = arguments['pageType'];
    switch (action) {
      case DStackConstant.push:
        continue Present;
      Present:
      case DStackConstant.present:
        {
          if (homePage != null &&
              homePage == true &&
              DStack.instance.hasHomePage == false) {
            String router = nodes.first;
            String pageTypeStr = pageTypeMap[router];
            pageTypeStr = pageTypeStr.toLowerCase();
            PageType pageType = PageType.native;
            if (pageTypeStr == "flutter") {
              pageType = PageType.flutter;
            }
            return replace(router, pageType,
                homePage: homePage, animated: false);
          } else {
            bool boundary = arguments['boundary'];
            if (boundary != null && boundary) {
              /// 临界页面不开启动画
              PageRoute route = DNavigatorManager.materialRoute(
                routeName: nodes.first,
                params: params,
                fullscreenDialog: action == DStackConstant.present,
                pushAnimated: false,
              );
              return _navigator.push(route);
            } else {
              MaterialPageRoute route = DNavigatorManager.materialRoute(
                  routeName: nodes.first,
                  params: params,
                  fullscreenDialog: action == DStackConstant.present);

              return _navigator.push(route);
            }
          }
        }
        break;
      case DStackConstant.pop:
        {
          if (nodes != null && nodes.isNotEmpty) {
            return DNavigatorManager.gardPop(params, animated);
          }
          return Future.value(false);
        }
        break;
      case DStackConstant.popTo:
        continue PopSkip;
      case 'popToNativeRoot':
        continue PopSkip;
      case DStackConstant.popToRoot:
        continue PopSkip;
      PopSkip:
      case DStackConstant.popSkip:
        {
          if (nodes != null && nodes.isNotEmpty) {
            Future pop;
            int length = nodes.length - 1;
            for (int i = length; i >= 0; i--) {
              bool _animated = i == length;
              if (!animated) {
                _animated = animated;
              }
              pop = DNavigatorManager.gardPop(null, _animated);
            }
            return pop;
          }
          return Future.value(false);
        }
        break;
      case DStackConstant.dismiss:
        {
          if (nodes != null && nodes.isNotEmpty) {
            return DNavigatorManager.gardPop(params, animated);
          }
          return Future.value(false);
        }
        break;
      case DStackConstant.gesture:
        {
          // native发消息过来时，需要处理返回至上一页
          if (nodes != null && nodes.isNotEmpty) {
            DStackNavigatorObserver.instance
                .setGesturingRouteName('NATIVEGESTURE');
            return DNavigatorManager.gardPop(params);
          }
          return Future.value(false);
        }
        break;
    }
    return null;
  }

  /// 从下往上弹出动画
  static PageRouteBuilder slideRoute(
      {String routeName,
      Map params,
      int milliseconds,
      bool fullscreenDialog = false}) {
    return animationRoute(
        routeName: routeName,
        params: params,
        animatedBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation, WidgetBuilder widgetBuilder) {
          double startOffsetX = fullscreenDialog ? 0 : 1.0;
          double startOffsetY = fullscreenDialog ? 1.0 : 0;
          Offset startOffset = Offset(startOffsetX, startOffsetY);
          Offset endOffset = const Offset(0, 0);

          return SlideTransition(
            transformHitTests: true,
            position: new Tween<Offset>(
              begin: startOffset,
              end: endOffset,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: widgetBuilder(context),
          );
        },
        transitionDuration: Duration(milliseconds: milliseconds));
  }

  /// 用户自定义flutter页面转场动画
  static PageRouteBuilder animationRoute({
    @required AnimatedPageBuilder animatedBuilder,
    @required String routeName,
    Map params,
    Duration transitionDuration = const Duration(milliseconds: 200),
    bool opaque = true,
    bool barrierDismissible = false,
    Color barrierColor,
    String barrierLabel,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    RouteSettings settings = RouteSettings(name: routeName, arguments: params);
    PageRouteBuilder pageRoute = PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: transitionDuration,
      opaque: opaque,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        DStackWidgetBuilder stackWidgetBuilder =
            DStack.instance.pageBuilder(routeName);

        return animatedBuilder(
            context, animation, secondaryAnimation, stackWidgetBuilder(params));
      },
    );
    return pageRoute;
  }

  /// 创建PageRoute
  /// pushAnimated 是否有进场动画
  /// popAnimated 是否有退场动画
  static PageRoute materialRoute(
      {String routeName,
      Map params,
      bool pushAnimated = true,
      bool popAnimated = true,
      bool maintainState = true,
      bool fullscreenDialog = false,
      WidgetBuilder builder}) {
    RouteSettings userSettings =
        RouteSettings(name: routeName, arguments: params);

    if (builder == null) {
      DStackWidgetBuilder stackWidgetBuilder =
          DStack.instance.pageBuilder(routeName);
      builder = stackWidgetBuilder(params);
    }

    _DStackPageRouteBuilder route = _DStackPageRouteBuilder(
      pageBuilder: builder,
      settings: userSettings,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
      pushTransition: pushAnimated ? defaultPushDuration : Duration.zero,
      popTransition: popAnimated ? defaultPopDuration : Duration.zero,
    );
    return route;
  }
}

class _DStackPopResult<T> {
  /// pop 返回时是否关闭返回动画
  final bool animated;
  final T result;
  _DStackPopResult({this.animated = true, this.result});
}

class _DStackPageRouteBuilder<T> extends PageRoute<T> {
  final Duration pushTransition;
  final Duration popTransition;
  final WidgetBuilder pageBuilder;
  final bool fullscreenDialog;

  _DStackPageRouteBuilder({
    @required this.pageBuilder,
    RouteSettings settings,
    this.pushTransition = defaultPushDuration,
    this.popTransition = defaultPopDuration,
    this.fullscreenDialog = false,
    this.maintainState = true,
  }) : super(settings: settings, fullscreenDialog: fullscreenDialog);

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  @override
  final bool maintainState;

  @override
  Duration get transitionDuration => pushTransition;

  @override
  Duration get reverseTransitionDuration => popTransition;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    return (nextRoute is MaterialPageRoute && !nextRoute.fullscreenDialog) ||
        (nextRoute is CupertinoPageRoute && !nextRoute.fullscreenDialog) ||
        (nextRoute is _DStackPageRouteBuilder && !nextRoute.fullscreenDialog);
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final Widget result = pageBuilder(context);
    assert(() {
      if (result == null) {
        throw FlutterError(
            'The builder for route "${settings.name}" returned null.\n'
            'Route builders must never return null.');
      }
      return true;
    }());
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: result,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final PageTransitionsTheme theme = Theme.of(context).pageTransitionsTheme;
    return theme.buildTransitions<T>(
        this, context, animation, secondaryAnimation, child);
  }

  @override
  bool didPop(T result) {
    if (result != null && result is _DStackPopResult) {
      _DStackPopResult pop = result;
      if (!pop.animated) {
        controller.reverseDuration = Duration.zero;
      }
    }
    return super.didPop(result);
  }
}
