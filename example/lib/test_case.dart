/*
 * Created with Android Studio.
 * User: linkewen
 * Date: 2020/12/4
 * Time: 15:12
 * target: 测试用例
 */

import 'dart:ui';

import 'package:d_stack/d_stack.dart';
import 'package:d_stack_example/page_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TestCase {
  /// 打开flutter页面用例
  static List<Map> openFlutterPageCase = [
    {
      "text": "【pop】 有动画",
      "clicked": (context) {
        DStack.pop();
      }
    },
    {
      "text": "【pop】 无动画",
      "clicked": (context) {
        DStack.pop(animated: false);
      }
    },
    {"text": "", "clicked": (context) {}},
    {"text": "", "clicked": (context) {}},
    {
      "text": "【push】 flutter page2 有动画",
      "clicked": (context) {
        DStack.push('page2', PageType.flutter);
      }
    },
    {
      "text": "【push】 flutter page2 无动画",
      "clicked": (context) {
        DStack.push('page2', PageType.flutter, animated: false);
      }
    },
    {
      "text": "【present】 flutter page2 有动画",
      "clicked": (context) {
        DStack.present('page2', PageType.flutter);
      }
    },
    {
      "text": "【present】 flutter page2 无动画",
      "clicked": (context) {
        DStack.present('page2', PageType.flutter, animated: false);
      }
    },
    {
      "text": "【replace】 flutter page2 有动画",
      "clicked": (context) {
        DStack.replace('page2', PageType.flutter);
      }
    },
    {
      "text": "【replace】 flutter page2 无动画",
      "clicked": (context) {
        DStack.replace('page2', PageType.flutter, animated: false);
      }
    },
    {
      "text": "【pushBuild】 flutter page2 有动画",
      "clicked": (context) {
        DStack.pushBuild('page2', PageType.flutter, (context) {
          return Page2();
        });
      }
    },
    {
      "text": "【pushBuild】 flutter page2 无动画",
      "clicked": (context) {
        DStack.pushBuild('page2', PageType.flutter, (context) {
          return Page2();
        }, animated: false);
      }
    },
    {
      "text": "【pushWithAnimation】 flutter page2 有动画，无手势返回",
      "clicked": (context) {
        DStack.pushWithAnimation("page2", PageType.flutter,
            (context, animation, secondaryAnimation, child) {
          Offset startOffset = const Offset(1.0, 0.0);
          Offset endOffset = const Offset(0.0, 0.0);
          return SlideTransition(
            position: Tween<Offset>(
              begin: startOffset,
              end: endOffset,
            ).animate(animation),
            child: child,
          );
        });
      }
    },
    {
      "text": "【pushWithAnimation】 flutter page2 有动画，有手势返回",
      "clicked": (context) {
        DStack.pushWithAnimation("page2", PageType.flutter,
            (context, animation, secondaryAnimation, child) {
          Offset startOffset = const Offset(1.0, 0.0);
          Offset endOffset = const Offset(0.0, 0.0);
          return SlideTransition(
            position: Tween<Offset>(
              begin: startOffset,
              end: endOffset,
            ).animate(animation),
            child: child,
          );
        }, popGesture: true);
      }
    },
    {
      "text": "【pushWithAnimation】 flutter page2 无动画，无手势返回",
      "clicked": (context) {
        DStack.pushWithAnimation("page2", PageType.flutter,
            (context, animation, secondaryAnimation, child) {
          Offset startOffset = const Offset(1.0, 0.0);
          Offset endOffset = const Offset(0.0, 0.0);
          return SlideTransition(
            position: Tween<Offset>(
              begin: startOffset,
              end: endOffset,
            ).animate(animation),
            child: child,
          );
        }, pushDuration: Duration.zero);
      }
    },
    {
      "text": "【pushWithAnimation】 flutter page2 无动画，有手势返回",
      "clicked": (context) {
        DStack.pushWithAnimation("page2", PageType.flutter,
            (context, animation, secondaryAnimation, child) {
          Offset startOffset = const Offset(1.0, 0.0);
          Offset endOffset = const Offset(0.0, 0.0);
          return SlideTransition(
            position: Tween<Offset>(
              begin: startOffset,
              end: endOffset,
            ).animate(animation),
            child: child,
          );
        }, pushDuration: Duration.zero, popGesture: true);
      }
    },
    {
      "text": "【pushWithAnimation】 flutter page2, replace",
      "clicked": (context) {
        DStack.pushWithAnimation("page2", PageType.flutter,
            (context, animation, secondaryAnimation, child) {
          Offset startOffset = const Offset(1.0, 0.0);
          Offset endOffset = const Offset(0.0, 0.0);
          return SlideTransition(
            position: Tween<Offset>(
              begin: startOffset,
              end: endOffset,
            ).animate(animation),
            child: child,
          );
        }, replace: true);
      }
    },
    {"text": "", "clicked": (context) {}},
    {
      "text": "【push】SixViewController 有动画",
      "clicked": (context) {
        DStack.push("SixViewController", PageType.native,
            params: {"name": "flutter 传递的", "id": 1000000});
      }
    },
    {"text": "", "clicked": (context) {}},
  ];

  /// 关闭flutter页面用例
  static List<Map> closeFlutterPage = [
    {
      "text": "【pop】 flutter page2 有动画",
      "clicked": (context) {
        DStack.pop();
      }
    },
    {
      "text": "【pop】 flutter page2 无动画",
      "clicked": (context) {
        DStack.pop(animated: false);
      }
    },
    {
      "text": "【dismiss】 flutter page2 有动画",
      "clicked": (context) {
        DStack.dismiss();
      }
    },
    {
      "text": "【dismiss】 flutter page2 无动画",
      "clicked": (context) {
        DStack.pop(animated: false);
      }
    },
    {"text": "", "clicked": (context) {}},
    {
      "text": "打开 flutter page3",
      "clicked": (context) {
        DStack.push('page3', PageType.flutter);
      }
    },
    {
      "text": "打开dialog",
      "clicked": (context) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext cxt) {
              return Container(
                alignment: Alignment.center,
                child: GestureDetector(
                  child: Container(
                    width: 300,
                    height: 240,
                    color: Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("dialog",
                            style: TextStyle(decoration: TextDecoration.none)),
                        RaisedButton(
                          onPressed: () {
                            DStack.push('page3', PageType.flutter);
                          },
                          child: Text("进入下一页面",
                              style:
                                  TextStyle(decoration: TextDecoration.none)),
                        ),
                        RaisedButton(
                          onPressed: () {
                            Navigator.pop(cxt);
                          },
                          child: Text("关闭弹窗",
                              style:
                                  TextStyle(decoration: TextDecoration.none)),
                        )
                      ],
                    ),
                  ),
                ),
              );
            });
      }
    },
  ];

  /// 关闭一组页面用例
  static List<Map> popToPage = [
    {
      "text": "【popTo】 flutter page1 有动画",
      "clicked": (context) {
        DStack.popTo("page1", PageType.flutter);
      }
    },
    {
      "text": "【popTo】 flutter page1 无动画",
      "clicked": (context) {
        DStack.popTo("page1", PageType.flutter, animated: false);
      }
    },
    {
      "text": "【popToRoot】有动画",
      "clicked": (context) {
        DStack.popToRoot();
      }
    },
    {
      "text": "【popToRoot】无动画",
      "clicked": (context) {
        DStack.popToRoot(animated: false);
      }
    },
    {"text": "", "clicked": (context) {}},
    {"text": "", "clicked": (context) {}},
    {
      "text": "【push】NativePage 有动画",
      "clicked": (context) {
        DStack.push("NativePage", PageType.native,
            params: {"name": "flutter 传递的", "id": 1000000});
      }
    },
    {
      "text": "【push】pushNamedAndRemoveUntil page1",
      "clicked": (context) {
        DStack.pushAndRemoveUntil("page1", PageType.flutter,
            params: {"name": "flutter 传递的", "id": 1000000});
      }
    },
    {
      "text": "【push】NativePage 无动画",
      "clicked": (context) {
        DStack.push("NativePage", PageType.native,
            params: {"name": "flutter 传递的", "id": 1000000}, animated: false);
      }
    },
    {
      "text": "【present】NativePage2 有动画",
      "clicked": (context) {
        DStack.present("NativePage2", PageType.native,
            params: {"name": "flutter 传递的", "id": 1000000});
      }
    },
    {
      "text": "【present】NativePage2 无动画",
      "clicked": (context) {
        DStack.present("NativePage2", PageType.native,
            params: {"name": "flutter 传递的", "id": 1000000}, animated: false);
      }
    },
  ];

  /// page5页面用例
  static List<Map> page5Cases = [
    {
      "text": "popTo HomeViewController",
      "clicked": (context) {
        DStack.popTo("HomeViewController", PageType.native);
      }
    },
    {
      "text": "popToRoot",
      "clicked": (context) {
        DStack.popToRoot();
      }
    },
  ];

  /// page6页面用例
  static List<Map> page6Cases = [
    {
      "text": "popToRoot",
      "clicked": (context) {
        DStack.popToRoot();
      }
    },
    {
      "text": "popTo Page3",
      "clicked": (context) {
        DStack.popTo("page3", PageType.flutter);
      }
    },
    {
      "text": "push SixViewController",
      "clicked": (context) {
        DStack.push("SixViewController", PageType.native,
            params: {"data": "flutter 传递给native的参数"});
      }
    },
  ];

  /// page7页面用例
  static List<Map> page7Cases = [
    {
      "text": "popToRoot",
      "clicked": (context) {
        DStack.popToRoot();
      }
    },
    {
      "text": "popTo ThirdViewController",
      "clicked": (context) {
        DStack.popTo("ThirdViewController", PageType.native);
      }
    },
    {
      "text": "popTo page2",
      "clicked": (context) {
        DStack.popTo("page2", PageType.flutter);
      }
    },
    {
      "text": "打开dialog",
      "clicked": (context) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext cxt) {
              return Container(
                alignment: Alignment.center,
                child: GestureDetector(
                  child: Container(
                    width: 300,
                    height: 240,
                    color: Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("dialog",
                            style: TextStyle(decoration: TextDecoration.none)),
                        RaisedButton(
                          onPressed: () {
                            DStack.push('page3', PageType.flutter);
                          },
                          child: Text("进入下一页面",
                              style:
                                  TextStyle(decoration: TextDecoration.none)),
                        ),
                        RaisedButton(
                          onPressed: () {
                            Navigator.pop(cxt);
                          },
                          child: Text("关闭弹窗",
                              style:
                                  TextStyle(decoration: TextDecoration.none)),
                        )
                      ],
                    ),
                  ),
                ),
              );
            });
      }
    },
  ];
}
