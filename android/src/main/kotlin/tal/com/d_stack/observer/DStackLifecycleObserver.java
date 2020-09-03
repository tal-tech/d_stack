package tal.com.d_stack.observer;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

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
    private boolean isFrontApp = true;
    private Activity activeActivity;
    private boolean appCreate = false;

    @Override
    public void onActivityCreated(@NonNull Activity activity, @Nullable Bundle savedInstanceState) {
        activeActivity = activity;
        Activity bottomActivity = DStackActivityManager.getInstance().getBottomActivity();
        appCreate = bottomActivity == null;
        DStackActivityManager.getInstance().addActivity(activity);
        String uniqueId = DStackActivityManager.getInstance().generateUniqueId();
        if (DStackActivityManager.getInstance().isFlutterActivity(activity)) {
            //如果是flutterActivity，那么不记录节点
            //把当前节点的activity赋值
            DNode currentNode = DNodeManager.getInstance().getCurrentNode();
            if (currentNode != null &&
                    currentNode.getPageType().equals(DNodePageType.DNodePageTypeFlutter)) {
                currentNode.setActivity(activity);
            }
        } else {
            //当前activity是nativeActivity，记录节点，并且赋值节点的activity
            DNode node = DNodeManager.getInstance().createNode(
                    activity.getClass().getName(),
                    uniqueId,
                    DNodePageType.DNodePageTypeNative,
                    DNodeActionType.DNodeActionTypePush,
                    null,
                    false);
            DNodeManager.getInstance().checkNode(node);
            DNode currentNode = DNodeManager.getInstance().getCurrentNode();
            if (currentNode != null) {
                currentNode.setActivity(activity);
            }
        }
        if (appCreate) {
            PageLifecycleManager.appCreate();
        }
    }

    @Override
    public void onActivityStarted(@NonNull Activity activity) {
        appCount++;
        if (!isFrontApp) {
            isFrontApp = true;
            PageLifecycleManager.appForeground();
        }
    }

    @Override
    public void onActivityResumed(@NonNull Activity activity) {
        if (activeActivity == activity) {
            //正在执行创建activity的逻辑，打开新页面操作，onCreate，onResumed方法是同一个activity
            DStackActivityManager.getInstance().setTopActivity(activity);
        } else {
            activeActivity = activity;
            DStackActivityManager.getInstance().setTopActivity(activity);
            //正在执行恢复activity的逻辑，页面返回操作，onCreate，onResumed不是同一个activity
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

    }

    @Override
    public void onActivityStopped(@NonNull Activity activity) {
        appCount--;
        if (!isFrontApp()) {
            isFrontApp = false;
            PageLifecycleManager.appBackground();
        }
    }

    @Override
    public void onActivitySaveInstanceState(@NonNull Activity activity, @NonNull Bundle outState) {

    }

    @Override
    public void onActivityDestroyed(@NonNull Activity activity) {
        boolean isPopTo = DStackActivityManager.getInstance().isPopTo();
        DStackActivityManager.getInstance().removeActivity(activity);
        if (DStackActivityManager.getInstance().isFlutterActivity(activity)) {
            return;
        }
        DNode node = DNodeManager.getInstance().createNode(
                activity.getClass().getName(),
                DStackActivityManager.getInstance().generateUniqueId(),
                DNodePageType.DNodePageTypeNative,
                DNodeActionType.DNodeActionTypePop,
                null,
                false);
        node.setPopTo(isPopTo);
        DNodeManager.getInstance().checkNode(node);
    }

    /**
     * 判断App是否在前台
     */
    private boolean isFrontApp() {
        return appCount > 0;
    }

}
