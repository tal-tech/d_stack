package tal.com.d_stack.utils;

import android.app.Activity;

import java.lang.reflect.Field;

import io.flutter.embedding.android.DFlutterActivity;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import tal.com.d_stack.DStack;

/**
 * 框架常用工具类
 * 包括获取flutterView示例和重新attach引擎功能
 */
public class DStackUtils {

    /**
     * 通过传入的FlutterActivity获取对应的FlutterView
     */
    public static FlutterView getFlutterView(Activity activity) {
        if (activity == null) {
            return null;
        }
        FlutterView flutterView = null;
        Class c = activity.getClass();
        try {
            // 处理FlutterActivity
            if (activity instanceof FlutterActivity) {
                while (c != FlutterActivity.class) {
                    c = c.getSuperclass();
                }
                Field fieldDelegate = c.getDeclaredField("delegate");
                fieldDelegate.setAccessible(true);
                Object objectDelegate = fieldDelegate.get(activity);
                Field flutterViewDelegate = objectDelegate.getClass().getDeclaredField("flutterView");
                flutterViewDelegate.setAccessible(true);
                flutterView = (FlutterView) flutterViewDelegate.get(objectDelegate);
            } else if (activity instanceof DFlutterActivity) {
                while (c != DFlutterActivity.class) {
                    c = c.getSuperclass();
                }
                Field fieldDelegate = c.getDeclaredField("delegate");
                fieldDelegate.setAccessible(true);
                Object objectDelegate = fieldDelegate.get(activity);
                Field flutterViewDelegate = objectDelegate.getClass().getDeclaredField("flutterView");
                flutterViewDelegate.setAccessible(true);
                flutterView = (FlutterView) flutterViewDelegate.get(objectDelegate);
            }
            // 处理FlutterFragmentActivity
            else if (activity instanceof FlutterFragmentActivity) {
                while (c != FlutterFragmentActivity.class) {
                    c = c.getSuperclass();
                }
                Field fieldFragment = c.getDeclaredField("flutterFragment");
                fieldFragment.setAccessible(true);
                Object objectFragment = fieldFragment.get(activity);
                Field fieldDelegate = objectFragment.getClass().getDeclaredField("delegate");
                fieldDelegate.setAccessible(true);
                Object objectDelegate = fieldDelegate.get(objectFragment);
                Field flutterViewDelegate = objectDelegate.getClass().getDeclaredField("flutterView");
                flutterViewDelegate.setAccessible(true);
                flutterView = (FlutterView) flutterViewDelegate.get(objectDelegate);
            }
        } catch (Exception e) {
            DLog.logE(e.getMessage());
        } finally {
            return flutterView;
        }
    }

    /**
     * 重新绑定当前flutterView对应的flutter引擎
     */
    public static void resetAttachEngine(FlutterView flutterView) {
        if (flutterView == null) {
            return;
        }
        FlutterEngine flutterEngine = FlutterEngineCache.getInstance().get(DStack.ENGINE_ID);
        if (flutterEngine == null) {
            return;
        }
        flutterView.detachFromFlutterEngine();
        flutterView.attachToFlutterEngine(flutterEngine);
    }

    /**
     * 获取唯一id
     */
    public static String generateUniqueId() {
        double d = Math.random();
        return (int) (d * 100000) + "";
    }
}
