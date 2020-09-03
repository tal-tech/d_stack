/*
 * Created with Android Studio.
 * User: whqfor
 * Date: 2020-02-03
 * Time: 14:20
 * email: wanghuaqiang@tal.com
 * tartget: flutter侧用户调用入口
 */

import 'dart:io';

import 'package:d_stack/d_stack.dart';
import 'package:d_stack/navigator/dnavigator_gesture_observer.dart';
import 'package:d_stack/widget/home_widget.dart';
import 'package:flutter/material.dart';

/// 主要两个部分：
/// 1.发送节点信息到Native，Native记录完整的路由信息
/// 2.处理Native发过来的指令，Native侧节点管理处理完节点信息，如果有指令过来，则flutter根据节点信息做相应的跳转事件

class DNavigatorManager {
  /// 1.发送节点信息到Native
  /// routeName 路由名，pageType native或者flutter, params 参数
  static Future push(String routeName, PageType pageType,
      [Map params, String storyboard, String identifier]) {
    if (pageType == PageType.flutter) {
      DNavigatorManager.nodeHandle(
          routeName, pageType, 'push', {}, storyboard, identifier);

      MaterialPageRoute route =
      DNavigatorManager.materialRoute(routeName: routeName, params: params);
      return DStack.instance.navigator.push(route);
    } else {
      DNavigatorManager.nodeHandle(
          routeName, pageType, 'push', params, storyboard, identifier);
    }
  }

  /// 提供外界直接传builder的能力
  static Future pushBuild(String routeName, WidgetBuilder builder,
      [Map params]) {
    DNavigatorManager.nodeHandle(routeName, PageType.flutter, 'push', params);

    RouteSettings userSettings =
    RouteSettings(name: routeName, arguments: params);
    MaterialPageRoute route = MaterialPageRoute(
      settings: userSettings,
      builder: builder,
    );
    return DStack.instance.navigator.push(route);
  }

  /// 目前只支持flutter使用，替换flutter页面
  static Future replace(String routeName, PageType pageType,
      [Map params, String storyboard, String identifier]) {
    DNavigatorManager.nodeHandle(
        routeName, pageType, 'replace', params, storyboard, identifier);

    if (pageType == PageType.flutter) {
      MaterialPageRoute route =
      DNavigatorManager.materialRoute(routeName: routeName, params: params);
      return DStack.instance.navigator.pushReplacement(route);
    }
  }

  /// result 返回值，可为空
  /// pop可以不传路由信息
  static void pop([Map result]) {
    DNavigatorManager.nodeHandle(null, null, 'pop', result);
  }

  static void popWithGesture() {
    DNavigatorManager.nodeHandle(null, null, 'gesture');
  }

  static void popTo(String routeName, PageType pageType, [Map result]) {
    DNavigatorManager.nodeHandle(routeName, pageType, 'popTo', result);
  }

  static void popToNativeRoot() {
    DNavigatorManager.nodeHandle(null, null, 'popToNativeRoot');
  }

  static void popSkip(String skipName, [Map result]) {
    DNavigatorManager.nodeHandle(skipName, null, 'popSkip', result);
  }

  static void present(String routeName, PageType pageType,
      [Map params, String storyboard, String identifier]) {
    DNavigatorManager.nodeHandle(
        routeName, pageType, 'present', params, storyboard, identifier);
  }

  static void dismiss([Map result]) {
    DNavigatorManager.nodeHandle(null, null, 'dismiss', result);
  }

  static void nodeHandle(String target, PageType pageType, String actionType,
      [Map result, String storyboard, String identifier]) {
    Map arguments = {
      'target': target,
      'pageType': '$pageType'
          .split('.')
          .last,
      'params': (result != null) ? result : {},
      'actionType': actionType,
      'storyboard': storyboard,
      'identifier': identifier
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
  static Future gardPop([Map params]) {
    int minCount = Platform.isIOS ? 2 : 1;
    if (DStackNavigatorObserver.instance.routerCount < minCount) {
      return Future.value('已经是首页，不再出栈');
    }
    DStack.instance.navigator.pop(params);
    return Future.value(true);
  }

  /// iOS 特有：重置homePage
  static Future resetHomePage() {
    if (DStackWidgetStream.instance.hasSetFlutterHomePage == false && Platform.isIOS) {
      StackWidgetStreamItem item =
      StackWidgetStreamItem(route: "homePage");
      DStackWidgetStream.instance.pageStreamController.sink.add(item);
    }
    return Future.value(true);
  }

  /// 2.处理Native发过来的指令
  /// argument里包含必选参数routeName，actionTpye，可选参数params
  static Future handleActionToFlutter(Map arguments) {
    // 处理实际跳转
    print(
        "收到【sendActionToFlutter】消息，参数：$arguments, navigator == ${DStack.instance
            .navigator}");
    final String action = arguments['action'];
    final List nodes = arguments['nodes'];
    final Map params = arguments['params'];
    bool homePage = arguments["homePage"];
    switch (action) {
      case 'push':
        {
          if (homePage != null && homePage == true &&
              DStackWidgetStream.instance.hasSetFlutterHomePage == false) {
            StackWidgetStreamItem item =
            StackWidgetStreamItem(route: nodes.first, params: params);
            DStackWidgetStream.instance.pageStreamController.sink.add(item);
          } else {
            bool animated = arguments['animated'];
            if (animated != null && animated == true) {
              MaterialPageRoute route = DNavigatorManager.materialRoute(
                  routeName: nodes.first, params: params);
              return DStack.instance.navigator.push(route);
            } else {
              PageRouteBuilder route = DNavigatorManager.slideRoute(
                  routeName: nodes.first, params: params, milliseconds: 0);
              return DStack.instance.navigator.push(route);
            }
          }
        }
        break;
      case 'present':
        {
          return DStack.instance.navigator
              .pushNamed(nodes.first, arguments: params);
        }
        break;
      case 'pop':
        {
          return DNavigatorManager.gardPop(params);
        }
        break;
      case 'popTo':
        continue PopSkip;
      case 'popToNativeRoot':
        continue PopSkip;
      case 'popToRoot':
        continue PopSkip;
      PopSkip:
      case 'popSkip':
        {
          Future pop;
          for (int i = nodes.length - 1; i >= 0; i--) {
            pop = DNavigatorManager.gardPop();
          }
          return pop;
        }
        break;
      case 'dismiss':
        {
          return DNavigatorManager.gardPop(params);
        }
        break;
      case 'gesture':
        {
          // native发消息过来时，需要处理返回至上一页
          return DNavigatorManager.gardPop(params);
        }
        break;
    }
    return null;
  }

  // 创建PageRoute
  static PageRouteBuilder slideRoute(
      {String routeName, Map params, int milliseconds}) {
    RouteSettings userSettings =
    RouteSettings(name: routeName, arguments: params);
    PageRouteBuilder pageRoute = PageRouteBuilder<dynamic>(
      settings: userSettings,
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        Offset startOffset = const Offset(1.0, 0.0);
        Offset endOffset = const Offset(0.0, 0.0);

        DStackWidgetBuilder stackWidgetBuilder =
        DStack.instance.pageBuilder(routeName);
        WidgetBuilder widgetBuilder = stackWidgetBuilder(params);

        return SlideTransition(
          position: new Tween<Offset>(
            begin: startOffset,
            end: endOffset,
          ).animate(animation),
          child: widgetBuilder(context),
        );
      },
      transitionDuration: Duration(milliseconds: milliseconds),
    );
    return pageRoute;
  }

  // 创建materialRoute
  static MaterialPageRoute materialRoute({String routeName, Map params}) {
    RouteSettings userSettings =
    RouteSettings(name: routeName, arguments: params);

    DStackWidgetBuilder stackWidgetBuilder =
    DStack.instance.pageBuilder(routeName);
    WidgetBuilder widgetBuilder = stackWidgetBuilder(params);

    MaterialPageRoute materialRoute = MaterialPageRoute(
      settings: userSettings,
      builder: widgetBuilder,
    );
    return materialRoute;
  }
}
