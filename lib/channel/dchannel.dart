/*
 * Created with Android Studio.
 * User: whqfor
 * Date: 2020-02-03
 * Time: 14:20
 * email: wanghuaqiang@tal.com
 * tartget: 处理通道相关
 */

import 'dart:async';
import 'package:d_stack/navigator/dnavigator_manager.dart';
import 'package:d_stack/observer/life_cycle_observer.dart';
import 'package:flutter/services.dart';
import '../d_stack.dart';

class DChannel {
  MethodChannel _methodChannel;

  DChannel(MethodChannel methodChannel) {
    _methodChannel = methodChannel;
    _methodChannel.setMethodCallHandler((MethodCall call) {
      // sendActionToFlutter 处理Native发过来的指令
      if ('sendActionToFlutter' == call.method) {
        return DNavigatorManager.handleActionToFlutter(call.arguments);
      } else if ('sendLifeCycle' == call.method) {
        return LifeCycleHandler.handleLifecycleMessage(call.arguments);
      } else if ('sendResetHomePage' == call.method) {
        return DNavigatorManager.resetHomePage();
      }
      return Future.value();
    });
  }

  Future invokeMethod<T>(String method, [dynamic arguments]) async {
    return _methodChannel.invokeMethod(method, arguments);
  }

  Future sendNodeToNative(Map arguments) async {
    assert(arguments != null);

    return _methodChannel.invokeMethod('sendNodeToNative', arguments);
  }

  Future sendRemoveFlutterPageNode(Map arguments) async {
    assert(arguments != null);

    return _methodChannel.invokeMethod('sendRemoveFlutterPageNode', arguments);
  }

  Future<List<DStackNode>> getNodeList() async {
    return _methodChannel.invokeMethod('sendNodeList', null).then((list) {
      if (list is List) {
        List<DStackNode> nodeList = [];
        list.forEach((element) {
          DStackNode node = DStackNode(
              route: element["route"],
              pageType: element["pageType"]
          );
          nodeList.add(node);
        });
        return Future.value(nodeList);
      }
      return null;
    });
  }
}
