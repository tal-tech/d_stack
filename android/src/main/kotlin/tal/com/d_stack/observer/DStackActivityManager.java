package tal.com.d_stack.observer;

import android.app.Activity;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

import io.flutter.embedding.android.DFlutterActivity;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterFragmentActivity;
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
     * 栈增加activity
     */
    public void addActivity(Activity activity) {
        if (activity == null) {
            return;
        }
        activities.add(activity);
        setBottomAndTopActivity();
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
        setBottomAndTopActivity();
    }

    /**
     * 设置栈顶和栈底Activity
     */
    public void setBottomAndTopActivity() {
        if (activities == null || activities.size() == 0) {
            topActivity = null;
            bottomActivity = null;
        } else {
            topActivity = activities.get(activities.size() - 1);
            bottomActivity = activities.get(0);
        }
    }

    /**
     * 获取栈顶Activity
     */
    public Activity getTopActivity() {
        return topActivity;
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
            return;
        }
        if (topActivity instanceof DFlutterActivity ||
                topActivity.getParent() instanceof DFlutterActivity) {
            topActivity.finish();
            return;
        }
        if (topActivity instanceof FlutterFragmentActivity ||
                topActivity.getParent() instanceof FlutterFragmentActivity) {
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
        Activity activity = node.getActivity().get();
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
     * 获取栈内Activity数量
     */
    public int getActivitiesSize() {
        if (activities == null) {
            return 0;
        }
        return activities.size();
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
        if (bottomActivity instanceof DFlutterActivity ||
                bottomActivity.getParent() instanceof DFlutterActivity) {
            return true;
        }
        if (bottomActivity instanceof FlutterFragmentActivity ||
                bottomActivity.getParent() instanceof FlutterFragmentActivity) {
            return true;
        }
        return false;
    }

    /**
     * 判断是否是FlutterActivity
     */
    public boolean isFlutterActivity(Activity activity) {
        if (activity instanceof FlutterActivity) {
            return true;
        }
        if (activity instanceof DFlutterActivity) {
            return true;
        }
        return false;
    }

    /**
     * 关闭过一个flutterActivity，并且栈里还有flutterActivity，需要重新attach引擎
     */
    public void handleReAttachEngine(Activity activity) {
        if (
                activity instanceof FlutterActivity ||
                        activity instanceof DFlutterActivity ||
                        activity instanceof FlutterFragmentActivity) {
            for (Activity tempActivity : activities) {
                if (tempActivity instanceof FlutterActivity ||
                        tempActivity instanceof DFlutterActivity ||
                        tempActivity instanceof FlutterFragmentActivity) {
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

    /**
     * 栈里是否有flutter控制器
     */
    public boolean haveFlutterContainer() {
        for (Activity activity : activities) {
            if (isFlutterActivity(activity)) {
                return true;
            }
        }
        return false;
    }

}
