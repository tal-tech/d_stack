/*
 * Created with Android Studio.
 * User: linkewen
 * Date: 2020/11/26
 * Time: 16:23
 * target: 静态配置
 */

class DStackConstant {
  /// action类型
  static const String push = "push";
  static const String present = "present";
  static const String dismiss = "dismiss";
  static const String pop = "pop";
  static const String popTo = "popTo";
  static const String popToRoot = "popToRoot";
  static const String popSkip = "popSkip";
  static const String replace = "replace";
  static const String gesture = "gesture";
  static const String pushAndRemoveUntil = "pushAndRemoveUntil";

  /// channel通道
  static const String nodeToFlutter = "sendActionToFlutter";
  static const String nodeToNative = "sendNodeToNative";
  static const String checkRemoved = "sendRemoveFlutterPageNode";
  static const String lifeCycle = "sendLifeCycle";
  static const String nodeList = "sendNodeList";
  static const String sendFlutterRootNode = "sendFlutterRootNode";
  static const String sendOperationNodeToFlutter = 'sendOperationNodeToFlutter';
  static const String sendHomePageRoute = 'sendHomePageRoute';
  static const String sendUpdateBoundaryNode = 'sendUpdateBoundaryNode';

  /// 其他标识
  static const String nativeDidPopGesture = "nativeDidPopGesture";
  static const String flutterDialog = "flutterDialog";
}
