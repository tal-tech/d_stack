import 'package:d_stack/d_stack.dart';
import 'package:flutter/material.dart';

/*
* DStack里面的homePage实现
* 在MaterialApp的home里面设置该widget
* 当工程是flutter为主工程时，设置home需要把工程中实际的homePage设置进去，比如DStackWidget(homePage: MyHomePage());
* 当工程是native为主工程时，设置home时直接设置成DStackWidget()，不要填写homePage
* */
/// DStack入口Widget
class DStackWidget extends StatelessWidget {
  /// 默认的homePage
  final Widget? homePage;

  /// homepage的route
  final String? homePageRoute;

  DStackWidget({Key? key, this.homePage, this.homePageRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DStack.instance.homePageRoute = homePageRoute;
    return homePage ?? Container(color: Colors.white);
  }
}
