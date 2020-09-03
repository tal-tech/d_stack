/*
 * Created with Android Studio.
 * User: sunjian
 * Date: 2020/6/29
 * Time: 7:45 PM
 * target: 应用的生命周期
 */

import 'package:d_stack/d_stack.dart';

/// 应用的生命周期  创建 前台 后台
enum DLifeCycleState { create, foreground, background }

class PageModel {
  String currentPageRoute; // 当前展示的页面路由
  String prePageRoute; // 前一个展示的页面路由，可能为null
  String currentPageType; // 页面类型：Flutter/Native
  String prePageType; // 页面类型：Flutter/Native
  String actionType; // 操作类型：push/pop

  PageModel(
      {this.currentPageRoute,
      this.prePageRoute,
      this.currentPageType,
      this.prePageType,
      this.actionType});

  @override
  String toString() {
    return "{'currentPageRoute':$currentPageRoute,'prePageRoute':$prePageRoute,"
        "'currentPageType':$currentPageType,'prePageType':$prePageType,"
        "'actionType':$actionType}";
  }
}

abstract class DLifeCycleObserver {
  void appDidStart(PageModel model); // 创建 对应 create

  void appDidEnterForeground(PageModel model); // 前台 对应foreground

  void appDidEnterBackground(PageModel model); // 后台 对应background

  void pageAppear(PageModel model); // 页面push/pop会调用 .
}

/// 处理页面生命周期
class LifeCycleHandler {
  static handleLifecycleMessage(Map arguments) {
    Map pageParams = arguments['page'];
    Map appParams = arguments['application'];
    if (pageParams != null) {
      String appearRoute = pageParams['appearRoute'];
      String disappearRoute = pageParams['disappearRoute'];
      String appearPageType = pageParams['appearPageType'];
      String disappearPageType = pageParams['disappearPageType'];
      String actionType = pageParams['actionType'];
      PageModel model = PageModel(
          currentPageRoute: appearRoute,
          prePageRoute: disappearRoute,
          currentPageType: appearPageType,
          prePageType: disappearPageType,
          actionType: actionType);
      DStack.instance.dLifeCycleObserver?.pageAppear(model);
    }
    if (appParams != null) {
      String currentRoute = appParams['currentRoute'];
      String pageType = appParams['pageType'];
      DLifeCycleState state = DLifeCycleState.values[appParams['state']];
      PageModel model =
          PageModel(currentPageRoute: currentRoute, currentPageType: pageType);
      switch (state) {
        case DLifeCycleState.create:
          DStack.instance.dLifeCycleObserver?.appDidStart(model);
          break;
        case DLifeCycleState.foreground:
          DStack.instance.dLifeCycleObserver?.appDidEnterForeground(model);
          break;
        case DLifeCycleState.background:
          DStack.instance.dLifeCycleObserver?.appDidEnterBackground(model);
          break;
      }
    }
  }
}
