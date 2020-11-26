import 'package:flutter/material.dart';

/// DStack入口Widget
class DStackWidget extends StatelessWidget {
  /// 默认的homePage
  final Widget homePage;

  DStackWidget({Key key, this.homePage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return homePage ?? Container(color: Colors.white);
  }
}