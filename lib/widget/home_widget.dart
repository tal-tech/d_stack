import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../d_stack.dart';

class StackWidgetStreamItem {
  final String route;
  final Map params;

  StackWidgetStreamItem({this.params, this.route});
}

class DStackWidgetStream {
  factory DStackWidgetStream() => _getInstance();

  static DStackWidgetStream get instance => _getInstance();
  static DStackWidgetStream _instance;

  DStackWidgetStream._internal();

  bool hasSetFlutterHomePage = false;
  StreamController<StackWidgetStreamItem> pageStreamController;

  Stream<StackWidgetStreamItem> get pageStream => pageStreamController.stream;

  static DStackWidgetStream _getInstance() {
    if (_instance == null) {
      _instance = DStackWidgetStream._internal();
      _instance.pageStreamController = StreamController();
    }
    return _instance;
  }

  void dispose() {
    if (pageStreamController != null) {
      pageStreamController.close();
    }
  }
}

/*
* DStack里面的homePage实现
* 在MaterialApp的home里面设置该widget
* 当工程是flutter为主工程时，设置home需要把工程中实际的homePage设置进去，比如DStackWidget(homePage: MyHomePage());
* 当工程是native为主工程时，设置home时直接设置成DStackWidget()，不要填写homePage
* */
class DStackWidget extends StatelessWidget {
  /// 默认的homePage
  final Widget homePage;

  DStackWidget({Key key, this.homePage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return homePage ?? Container(color: Colors.white);
  }
}