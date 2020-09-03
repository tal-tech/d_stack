package tal.com.d_stack.observer;

import android.app.Activity;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

import io.flutter.embedding.android.FlutterActivity;
import tal.com.d_stack.node.DNode;
import tal.com.d_stack.utils.DLog;

/**
 * activity的栈管理
 */
public class DStackActivityManager {

    private final static AtomicReference<DStackActivityManager> INSTANCE = new AtomicReference<>();

    public static DStackActivityManager getInstance() {
        for (; ; ) {
            DStackActivityManager factory = INSTANCE.get();
            if (factory != null) {
                return factory;
            }
            factory = new DStackActivityManager();
            if (INSTANCE.compareAndSet(null, factory)) {
                return factory;
            }
        }
    }

    //activity栈集合
    private List<Activity> activities;
    //栈顶activity
    private Activity topActivity;
    //栈底activity
    private Activity bottomActivity;
    //需要移除出栈的activity集合
    private List<Activity> needRemoveActivities;
    //正在执行activity栈清除操作
    private boolean executeStack;
    //是否需要重新attach引擎
    private boolean needReAttachEngine = false;

    private DStackActivityManager() {
        activities = new ArrayList<>();
        needRemoveActivities = new ArrayList<>();
    }

    /**
     * 获取唯一id
     */
    public String generateUniqueId() {
        double d = Math.random();
        return (int) (d * 100000) + "";
    }

    /**
     * 栈增加activity
     */
    public void addActivity(Activity activity) {
        if (activity == null) {
            return;
        }
        activities.add(activity);
        setBottomActivity(activity);
    }

    /**
     * 栈移除activity
     */
    public void removeActivity(Activity activity) {
        if (activity == null) {
            return;
        }
        activities.remove(activity);
        handleReAttachEngine(activity);
        handleNeedRemoveActivities(activity);
    }

    /**
     * 设置栈顶Activity
     */
    public void setTopActivity(Activity activity) {
        if (activity == null) {
            return;
        }
        topActivity = activity;
    }

    /**
     * 获取栈顶Activity
     */
    public Activity getTopActivity() {
        return topActivity;
    }

    /**
     * 设置栈底Activity
     */
    public void setBottomActivity(Activity activity) {
        if (activity == null || bottomActivity != null) {
            return;
        }
        bottomActivity = activity;
    }

    /**
     * 获取栈底Activity
     */
    public Activity getBottomActivity() {
        return bottomActivity;
    }

    /**
     * 判断栈顶的activity是否和要打开的activity是同一个activity
     */
    public boolean isSameActivity(Class<?> needOpenActivity) {
        if (topActivity != null && needOpenActivity != null) {
            String topActivityName = topActivity.getClass().getSimpleName();
            String needOpenActivityName = needOpenActivity.getSimpleName();
            return topActivityName.trim().equals(needOpenActivityName.trim());
        }
        return false;
    }

    /**
     * 关闭栈顶activity
     */
    public void closeTopActivity() {
        if (topActivity == null) {
            return;
        }
        topActivity.finish();
    }

    /**
     * 关闭栈顶的flutter控制器activity
     */
    public void closeTopFlutterActivity() {
        if (topActivity == null) {
            return;
        }
        if (topActivity instanceof FlutterActivity ||
                topActivity.getParent() instanceof FlutterActivity) {
            topActivity.finish();
        }
    }

    /**
     * 把该节点对应activity之上的所有activity关闭
     */
    public void closeActivityWithNode(DNode node) {
        if (node == null || node.getActivity() == null) {
            return;
        }
        boolean find = false;
        needRemoveActivities.clear();
        Activity activity = node.getActivity();
        for (int i = activities.size() - 1; i >= 0; i--) {
            Activity tempActivity = activities.get(i);
            if (tempActivity != activity) {
                needRemoveActivities.add(tempActivity);
            } else {
                find = true;
                break;
            }
        }
        if (find) {
            if (needRemoveActivities.size() == 0) {
                return;
            }
            executeStack = true;
            needRemoveActivities.get(0).finish();
        } else {
            needRemoveActivities.clear();
        }
    }

    /**
     * 关闭bottomActivity之上的所有activity
     */
    public void closeActivityWithBottom() {
        boolean find = false;
        needRemoveActivities.clear();
        Activity activity = bottomActivity;
        for (int i = activities.size() - 1; i >= 0; i--) {
            Activity tempActivity = activities.get(i);
            if (tempActivity != activity) {
                needRemoveActivities.add(tempActivity);
            } else {
                find = true;
                break;
            }
        }
        if (find) {
            if (needRemoveActivities.size() == 0) {
                return;
            }
            executeStack = true;
            needRemoveActivities.get(0).finish();
        } else {
            needRemoveActivities.clear();
        }
    }


    /**
     * 每次关闭activity后，看看待移除列表是否还有activity，继续执行关闭操作
     */
    private void handleNeedRemoveActivities(Activity activity) {
        if (activity == null || needRemoveActivities.size() == 0) {
            return;
        }
        DLog.logE("被关闭的Activity是：" + activity.getClass().getName());
        needRemoveActivities.remove(activity);
        if (needRemoveActivities.size() == 0) {
            //activity栈的处理完成
            executeStack = false;
            return;
        }
        //继续取集合第一个activity进行关闭
        needRemoveActivities.get(0).finish();
    }

    /**
     * activity栈正在执行操作，这个方法被调用说明正在执行popTo，popToRoot，popToSkip方法
     * activity正在依次顺序关闭，也不需要在执行其他关闭activity的操作
     */
    public boolean isExecuteStack() {
        return executeStack;
    }

    /**
     * 判断是否在执行popTo，popToRoot，popToSkip方法
     * 主要给节点处理用
     */
    public boolean isPopTo() {
        return needRemoveActivities.size() > 0;
    }

    /**
     * 判断当前工程是否是一个纯Flutter工程
     */
    public boolean isFlutterApp() {
        if (bottomActivity == null) {
            return true;
        }
        if (bottomActivity instanceof FlutterActivity ||
                bottomActivity.getParent() instanceof FlutterActivity) {
            return true;
        }
        return false;
    }

    /**
     * 判断是否是FlutterActivity
     */
    public boolean isFlutterActivity(Activity activity) {
        return activity instanceof FlutterActivity;
    }

    /**
     * 关闭过一个flutterActivity，并且栈里还有flutterActivity，需要重新attach引擎
     */
    public void handleReAttachEngine(Activity activity) {
        if (activity instanceof FlutterActivity) {
            for (Activity tempActivity : activities) {
                if (tempActivity instanceof FlutterActivity) {
                    needReAttachEngine = true;
                    break;
                }
            }
        }
    }

    /**
     * 设置是否需要重新attach引擎
     */
    public void setNeedReAttachEngine(boolean needReAttachEngine) {
        this.needReAttachEngine = needReAttachEngine;
    }

    /**
     * 是否需要重新attach引擎
     */
    public boolean isNeedReAttachEngine() {
        return needReAttachEngine;
    }
}
