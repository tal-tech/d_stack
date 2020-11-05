/*
 * Created with Android Studio.
 * User: whqfor
 * Date: 2019-11-26
 * Time: 14:47
 * email: wanghuaqiang@100tal.com
 * tartget: page_widgets
 */

//import 'package:battery/battery.dart';
import 'dart:io';
import 'package:d_stack/d_stack.dart';
import 'package:flutter/material.dart';

class Student {
  String name;
  int age;
  String address;
}

class Page1 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _Page1();
  }
}

class _Page1 extends State<Page1> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('flutter page1'),
          leading: RaisedButton(
            child: Text('返回'),
            onPressed: () {
              DStack.pop();
            },
          )),
      backgroundColor: Colors.white,
      body: Center(
        child: RaisedButton(
          child: Text('push flutter page 2'),
          onPressed: () {
            Student student = Student();
            student.name = '😁🍎111';
            student.age = 12;

            // 自定义动画
            DStack.animationPage('page2', PageType.flutter,
                (BuildContext context,
                    Animation<double> animation,
                    Animation<double> secondaryAnimation,
                    WidgetBuilder widgetBuilder) {
              Offset startOffset = const Offset(1.0, 0.0);
              Offset endOffset = const Offset(0.0, 0.0);
              return SlideTransition(
                position: new Tween<Offset>(
                  begin: startOffset,
                  end: endOffset,
                ).animate(animation),
                child: widgetBuilder(context),
              );
            }, params: {'key1': 12}, transitionDuration: Duration(milliseconds: 250));

            // DStack.push('page2', PageType.flutter, params: {'key1': 12})
            //     .then((data) {
            //   return print('pop to Page1 result $data');
            // });
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class Page2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Map args = ModalRoute.of(context).settings.arguments;
    print(' ==page2收到前一个页面传来的参数=====  $args');

    return Scaffold(
      appBar: AppBar(
          title: Text('flutter page2'),
          leading: RaisedButton(
            child: Text('返回'),
            onPressed: () {
              Student student = Student();
              student.name = '😁🍎33333';
              student.age = 12;
              DStack.pop(result: {'params': 'value222'});
            },
          )),
      body: Center(
        child: RaisedButton(
          child: Text('present flutter page 3'),
          onPressed: () {
            DStack.present('page3', PageType.flutter);
          },
        ),
      ),
    );
  }
}

class Page3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget present() {
      if (Platform.isIOS) {
        return RaisedButton(
          child: Text('Present打开NativePage2'),
          onPressed: () {
            DStack.present("NativePage2", PageType.native,
                params: {"name": "flutter 传递的", "id": 1000000});
          },
        );
      }
      return Container();
    }

    return Scaffold(
      appBar: AppBar(
          title: Text('flutter page3'),
          leading: RaisedButton(
            child: Text('返回'),
            onPressed: () {
              DStack.pop();
            },
          )),
      body: Center(
          child: Column(
        children: <Widget>[
          RaisedButton(
            child: Text('打开NativePage'),
            onPressed: () {
              DStack.push("NativePage", PageType.native,
                  params: {"name": "flutter 传递的", "id": 1000000});
            },
          ),
          present(),
        ],
      )),
    );
  }
}

class Page4 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('flutter page4'),
        leading: RaisedButton(
          child: Text('返回'),
          onPressed: () {
            DStack.pop(result: {'key3': 23});
          },
        ),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            RaisedButton(
              child: Text('popTo Flutter Page 2'),
              onPressed: () {
                DStack.popTo("page2", PageType.flutter);
              },
            ),
            RaisedButton(
              child: Text('popTo Root'),
              onPressed: () {
                DStack.popToNativeRoot();
              },
            ),
          ],
        ),
      ),
    );
  }
}
