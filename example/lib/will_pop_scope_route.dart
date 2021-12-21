import 'package:flutter/widgets.dart';

class WillPopScopeRoute extends StatefulWidget {
  final Widget child;

  WillPopScopeRoute(this.child);

  @override
  WillPopScopeRouteState createState() {
    return new WillPopScopeRouteState();
  }
}

class WillPopScopeRouteState extends State<WillPopScopeRoute> {
  DateTime? _lastPressedAt; //上次点击时间

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
        onWillPop: () async {
          if (_lastPressedAt == null ||
              DateTime.now().difference(_lastPressedAt!) >
                  Duration(seconds: 2)) {
            print('2秒后在按一次退出');
            //两次点击间隔超过1秒则重新计时
            _lastPressedAt = DateTime.now();
            return false;
          } else {
            print('退出了');
            return true;
          }
        },
        child: widget.child);
  }
}
