/*
 * Created with Android Studio.
 * User: whqfor
 * Date: 12/5/20
 * Time: 6:04 PM
 * target: 监听节点的observer
 */

import 'package:d_stack/d_stack.dart';

abstract class DNodeObserver {
  /// 用户操作的所有行为都将会从这个api传出，可以基于此做行为回放
  /// 将要进行操作的节点
  void operationNode(Map? node);
}

class DNodeObserverHandler {
  static handlerNodeMessage(Map? node) {
    DStack.instance.dNodeObserver?.operationNode(node);
  }
}
