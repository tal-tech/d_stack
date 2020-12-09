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

class TestCase {
  /// 打开flutter页面用例
  static List<Map> openFlutterPageCase = [
    {
      "text": "【pop】 有动画",
      "clicked": () {
        DStack.pop();
      }
    },
    {
      "text": "【pop】 无动画",
      "clicked": () {
        DStack.pop(animated: false);
      }
    },
    {"text": "", "clicked": () {}},
    {"text": "", "clicked": () {}},
    {
      "text": "【push】 flutter page2 有动画",
      "clicked": () {
        DStack.push('page2', PageType.flutter);
      }
    },
    {
      "text": "【push】 flutter page2 无动画",
      "clicked": () {
        DStack.push('page2', PageType.flutter, animated: false);
      }
    },
    {
      "text": "【present】 flutter page2 有动画",
      "clicked": () {
        DStack.present('page2', PageType.flutter);
      }
    },
    {
      "text": "【present】 flutter page2 无动画",
      "clicked": () {
        DStack.present('page2', PageType.flutter, animated: false);
      }
    },
    {
      "text": "【replace】 flutter page2 有动画",
      "clicked": () {
        DStack.replace('page2', PageType.flutter);
      }
    },
    {
      "text": "【replace】 flutter page2 无动画",
      "clicked": () {
        DStack.replace('page2', PageType.flutter, animated: false);
      }
    },
    {
      "text": "【pushBuild】 flutter page2 有动画",
      "clicked": () {
        DStack.pushBuild('page2', PageType.flutter, (context) {
          return Page2();
        });
      }
    },
    {
      "text": "【pushBuild】 flutter page2 无动画",
      "clicked": () {
        DStack.pushBuild('page2', PageType.flutter, (context) {
          return Page2();
        }, animated: false);
      }
    },
    {
      "text": "【pushWithAnimation】 flutter page2 有动画，无手势返回",
      "clicked": () {
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
      "clicked": () {
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
      "clicked": () {
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
      "clicked": () {
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
      "clicked": () {
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
  ];

  /// 关闭flutter页面用例
  static List<Map> closeFlutterPage = [
    {
      "text": "【pop】 flutter page2 有动画",
      "clicked": () {
        DStack.pop();
      }
    },
    {
      "text": "【pop】 flutter page2 无动画",
      "clicked": () {
        DStack.pop(animated: false);
      }
    },
    {
      "text": "【dismiss】 flutter page2 有动画",
      "clicked": () {
        DStack.dismiss();
      }
    },
    {
      "text": "【dismiss】 flutter page2 无动画",
      "clicked": () {
        DStack.pop(animated: false);
      }
    },
    {"text": "", "clicked": () {}},
    {
      "text": "打开 flutter page3",
      "clicked": () {
        DStack.push('page3', PageType.flutter);
      }
    },
  ];

  /// 关闭一组页面用例
  static List<Map> popToPage = [
    {
      "text": "【popTo】 flutter page1 有动画",
      "clicked": () {
        DStack.popTo("page1", PageType.flutter);
      }
    },
    {
      "text": "【popTo】 flutter page1 无动画",
      "clicked": () {
        DStack.popTo("page1", PageType.flutter, animated: false);
      }
    },
    {
      "text": "【popToRoot】有动画",
      "clicked": () {
        DStack.popToRoot();
      }
    },
    {
      "text": "【popToRoot】无动画",
      "clicked": () {
        DStack.popToRoot(animated: false);
      }
    },
    {"text": "", "clicked": () {}},
    {"text": "", "clicked": () {}},
    {
      "text": "【push】NativePage 有动画",
      "clicked": () {
        DStack.push("NativePage", PageType.native,
            params: {"name": "flutter 传递的", "id": 1000000});
      }
    },
    {
      "text": "【push】NativePage 无动画",
      "clicked": () {
        DStack.push("NativePage", PageType.native,
            params: {"name": "flutter 传递的", "id": 1000000}, animated: false);
      }
    },
    {
      "text": "【present】NativePage2 有动画",
      "clicked": () {
        DStack.present("NativePage2", PageType.native,
            params: {"name": "flutter 传递的", "id": 1000000});
      }
    },
    {
      "text": "【present】NativePage2 无动画",
      "clicked": () {
        DStack.present("NativePage2", PageType.native,
            params: {"name": "flutter 传递的", "id": 1000000}, animated: false);
      }
    },
  ];

  /// page5页面用例
  static List<Map> page5Cases = [
    {
      "text": "popTo HomeViewController",
      "clicked": () {
        DStack.popTo("HomeViewController", PageType.native);
      }
    },
    {
      "text": "popToRoot",
      "clicked": () {
        DStack.popToRoot();
      }
    },
  ];

  /// page6页面用例
  static List<Map> page6Cases = [
    {
      "text": "popToRoot",
      "clicked": () {
        DStack.popToRoot();
      }
    },
    {
      "text": "popTo Page3",
      "clicked": () {
        DStack.popTo("page3", PageType.flutter);
      }
    },
    {
      "text": "push SixViewController",
      "clicked": () {
        DStack.push("SixViewController", PageType.native,
            params: {"data": "flutter 传递给native的参数"});
      }
    },
  ];

  /// page7页面用例
  static List<Map> page7Cases = [
    {
      "text": "popToRoot",
      "clicked": () {
        DStack.popToRoot();
      }
    },
    {
      "text": "popTo ThirdViewController",
      "clicked": () {
        DStack.popTo("ThirdViewController", PageType.native);
      }
    },
    {
      "text": "popTo page2",
      "clicked": () {
        DStack.popTo("page2", PageType.flutter);
      }
    },
  ];
}
