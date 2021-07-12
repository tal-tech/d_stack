/*
 * Created with Android Studio.
 * User: whqfor
 * Date: 2019-11-26
 * Time: 14:47
 * email: wanghuaqiang@100tal.com
 * tartget: page_widgets
 */

import 'package:d_stack/d_stack.dart';
import 'package:d_stack_example/test_case.dart';
import 'package:flutter/material.dart';

class Student {
  String? name;
  int? age;
  String? address;
}

Widget _caseWidget(List<Map> items, {BuildContext? context}) {
  return Center(
    child: ListView.builder(
      itemExtent: 60,
      itemCount: items.length,
      itemBuilder: (BuildContext context, index) {
        Map caseMap = items[index];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: Colors.grey, width: 0.5))),
            child: Text(caseMap["text"]),
          ),
          onTap: () {
            caseMap["clicked"](context);
          },
        );
      },
    ),
  );
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
    final Map? args =
        ModalRoute.of(context)!.settings.arguments as Map<dynamic, dynamic>?;
    debugPrint('page1收到前一个页面传来的参数 ==> $args');
    return Scaffold(
      appBar: AppBar(title: Text('flutter page1'), leading: Container()),
      backgroundColor: Colors.white,
      body: _caseWidget(TestCase.openFlutterPageCase),
    );
  }
}

class Page2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Map? args =
        ModalRoute.of(context)!.settings.arguments as Map<dynamic, dynamic>?;
    debugPrint('page2收到前一个页面传来的参数 ==> $args');

    return Scaffold(
      appBar: AppBar(
          title: Text('flutter page2'),
          leading: ElevatedButton(
            child: Text('返回'),
            onPressed: () {
              DStack.pop();
            },
          )),
      body: _caseWidget(TestCase.closeFlutterPage, context: context),
    );
  }
}

class Page3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('flutter page3'),
          leading: ElevatedButton(
            child: Text('返回'),
            onPressed: () {
              DStack.pop();
            },
          )),
      body: _caseWidget(TestCase.popToPage),
    );
  }
}

class Page4 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('flutter page4'),
        leading: ElevatedButton(
          child: Text('返回'),
          onPressed: () {
            DStack.pop();
          },
        ),
      ),
      body: _caseWidget(TestCase.openFlutterPageCase),
    );
  }
}

class Page5 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('flutter page5'),
        leading: ElevatedButton(
          child: Text('返回'),
          onPressed: () {
            DStack.pop();
          },
        ),
      ),
      body: _caseWidget(TestCase.page5Cases),
    );
  }
}

class Page6 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('flutter page6'),
        leading: ElevatedButton(
          child: Text('返回'),
          onPressed: () {
            DStack.pop();
          },
        ),
      ),
      body: _caseWidget(TestCase.page6Cases),
    );
  }
}

class Page7 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('flutter page7'),
        leading: ElevatedButton(
          child: Text('返回'),
          onPressed: () {
            DStack.pop();
          },
        ),
      ),
      body: _caseWidget(TestCase.page7Cases),
    );
  }
}
