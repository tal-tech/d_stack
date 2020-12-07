package tal.com.d_stack.observer;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.lang.ref.WeakReference;

import io.flutter.embedding.android.FlutterView;
import tal.com.d_stack.lifecycle.PageLifecycleManager;
import tal.com.d_stack.node.DNode;
import tal.com.d_stack.node.DNodeManager;
import tal.com.d_stack.node.constants.DNodeActionType;
import tal.com.d_stack.node.constants.DNodePageType;
import tal.com.d_stack.utils.DLog;
import tal.com.d_stack.utils.DStackUtils;

/**
 * 监控App生命周期，进行Activity栈管理
 */
public class DStackLifecycleObserver implements Application.ActivityLifecycleCallbacks {

    private int appCount = 0;
    //app是否在前台
    private boolean isFrontApp = true;
    //当前活动activity
    private Activity activeActivity;
    //是否app启动
    boolean appStart;

    @Override
    public void onActivityCreated(@NonNull Activity activity, @Nullable Bundle savedInstanceState) {
        if (!FilterActivityManager.getInstance().canAdd(activity)) {
            return;
        }
        DStackActivityManager.getInstance().addActivity(activity);
        activeActivity = activity;
        appStart = DStackActivityManager.getInstance().getActivitiesSize() == 1;
        if (appStart) {
            DNode node;
            //应用刚刚启动时
            if (DStackActivityManager.getInstance().isFlutterActivity(activity)) {
                //是flutter工程，添加根节点
                node = new DNode.Builder()
                        .target("/")
                        .pageType(DNodePageType.DNodePageTypeFlutter)
                        .action(DNodeActionType.DNodeActionTypePush)
                        .identifier(DStackUtils.generateUniqueId())
                        .isHomePage(true)
                        .isRootPage(true)
                        .build();
            } else {
                //是native工程，添加根节点
                node = new DNode.Builder()
                        .target("/")
                        .pageType(DNodePageType.DNodePageTypeNative)
                        .action(DNodeActionType.DNodeActionTypePush)
                        .identifier(DStackUtils.generateUniqueId())
                        .isHomePage(true)
                        .isRootPage(true)
                        .build();
            }
            DNodeManager.getInstance().checkNode(node);
        } else {
            //应用已经启动，打开新的activity
            if (!DStackActivityManager.getInstance().isFlutterActivity(activity)) {
                //是native工程，添加普通节点
                DNode node = new DNode.Builder()
                        .target(activity.getClass().getName())
                        .pageType(DNodePageType.DNodePageTypeNative)
                        .action(DNodeActionType.DNodeActionTypePush)
                        .identifier(DStackUtils.generateUniqueId())
                        .build();
                DNodeManager.getInstance().checkNode(node);
            }
        }
        DNodeManager.getInstance().getCurrentNode().setActivity(new WeakReference(activity));
        if (appStart) {
            //app启动通知
            PageLifecycleManager.appCreate();
        }
    }

    @Override
    public void onActivityStarted(@NonNull Activity activity) {
        if (!FilterActivityManager.getInstance().canAdd(activity)) {
            return;
        }
        appCount++;
        if (!isFrontApp) {
            isFrontApp = true;
            PageLifecycleManager.appForeground();
        }
    }

    @Override
    public void onActivityResumed(@NonNull Activity activity) {
        if (!FilterActivityManager.getInstance().canAdd(activity)) {
            return;
        }
        if (activeActivity != activity) {
            //正在执行恢复activity的逻辑，页面返回操作，onCreate，onResumed不是同一个activity
            activeActivity = activity;
            if (DStackActivityManager.getInstance().isNeedReAttachEngine()) {
                //判断是否需要重新attach flutter引擎，1.17以上bug，解决软键盘不能弹出问题
                DLog.logE("需要needReAttachEngine");
                FlutterView flutterView = DStackUtils.getFlutterView(activity);
                DStackUtils.resetAttachEngine(flutterView);
                DStackActivityManager.getInstance().setNeedReAttachEngine(false);
            }
        }
    }


    @Override
    public void onActivityPaused(@NonNull Activity activity) {
        if (!FilterActivityManager.getInstance().canAdd(activity)) {
            return;
        }
    }

    @Override
    public void onActivityStopped(@NonNull Activity activity) {
        if (!FilterActivityManager.getInstance().canAdd(activity)) {
            return;
        }
        appCount--;
        if (!isFrontApp()) {
            isFrontApp = false;
            PageLifecycleManager.appBackground();
        }
    }

    @Override
    public void onActivityDestroyed(@NonNull Activity activity) {
        if (!FilterActivityManager.getInstance().canAdd(activity)) {
            return;
        }
        boolean isPopTo = DStackActivityManager.getInstance().isExecuteStack();
        DStackActivityManager.getInstance().removeActivity(activity);
        DNode currentNode = DNodeManager.getInstance().getCurrentNode();
        DNode node = new DNode.Builder()
                .target(currentNode.getTarget())
                .pageType(currentNode.getPageType())
                .action(DNodeActionType.DNodeActionTypePop)
                .isHomePage(currentNode.isHomePage())
                .isRootPage(currentNode.isRootPage())
                .identifier(currentNode.getIdentifier())
                .isPopTo(isPopTo)
                .build();
        DNodeManager.getInstance().checkNode(node);
    }

    /**
     * 判断App是否在前台
     */
    private boolean isFrontApp() {
        return appCount > 0;
    }

    @Override
    public void onActivitySaveInstanceState(@NonNull Activity activity, @NonNull Bundle outState) {

    }
}
