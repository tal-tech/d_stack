/*
 * Created with Android Studio.
 * User: whqfor
 * Date: 2020-02-03
 * Time: 14:20
 * email: wanghuaqiang@tal.com
 * tartget: 拦截flutter手势，生成节点信息，然后将节点信息发送到native侧
 */

import 'package:flutter/material.dart';

import 'dnavigator_manager.dart';

// 路由监听
class DStackNavigatorObserver extends NavigatorObserver {
  // 单例
  factory DStackNavigatorObserver() => _getInstance();

  static DStackNavigatorObserver get instance => _getInstance();
  static DStackNavigatorObserver _instance;
  // 避免过度pop
  int routerCount = 0;

  DStackNavigatorObserver._internal();

  static DStackNavigatorObserver _getInstance() {
    if (_instance == null) {
      _instance = new DStackNavigatorObserver._internal();
    }
    return _instance;
  }

  // 标识手势引起的pop事件
  String _gesturingRouteName;
  String get gesturingRouteName => this._gesturingRouteName;
  void setGesturingRouteName(String gesturingRouteName) {
    this._gesturingRouteName = gesturingRouteName;
  }

  /// 页面进入了
  /// route 路由目标页面
  /// previousRoute 目标页面的上一个页面
  @override
  void didPush(Route route, Route previousRoute) {
    super.didPush(route, previousRoute);
    print('didPush ${route.settings.name}');
    routerCount += 1;
  }

  /// 页面退出了（手势返回也会走这个方法）
  /// route 当前操作页面
  /// previousRoute 操作页面的上一个页面
  @override
  void didPop(Route route, Route previousRoute) {
    super.didPop(route, previousRoute);
    routerCount -= 1;
    print('didPop 🍎🍎🍎🍎🍎🍎🍎  ${route.settings.name}');
    if (gesturingRouteName != null && gesturingRouteName == route.settings.name) {
      // 由手势导致的pop事件
      print('didPop gesturingRouteName ${route.settings.name}');
      DNavigatorManager.popWithGesture();
    } else if (gesturingRouteName != null && gesturingRouteName == 'NATIVEGESTURE') {
      // native手势引起的didpop，native侧已经删除节点，flutter侧不再removeFlutterNode
      print('didPop gesturingRouteName $gesturingRouteName');
      DStackNavigatorObserver.instance.setGesturingRouteName(null);
    } else {
      print('除了手势导致的didPop native处理删除节点 ${route.settings.name}');
      if (route.settings.name != null) {
        DNavigatorManager.removeFlutterNode(route.settings.name);
      }
    }
  }

  /// route 路由目标页面
  /// previousRoute 目标页面的上一个页面
  // 滑动手势开始
  @override
  void didStartUserGesture(Route route, Route previousRoute) {
    super.didStartUserGesture(route, previousRoute);
    print('didStartUserGesture ${route.settings.name}');

    DStackNavigatorObserver.instance.setGesturingRouteName(route.settings.name);
  }

  // 滑动手势结束
  @override
  void didStopUserGesture() {
    super.didStopUserGesture();
    print('didStopUserGesture ${this._gesturingRouteName}');

    DStackNavigatorObserver.instance.setGesturingRouteName(null);
  }
}
