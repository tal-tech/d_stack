package tal.com.d_stack.utils;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.drawable.BitmapDrawable;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.FrameLayout;

import java.lang.reflect.Field;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.android.FlutterSurfaceView;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
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
     * 获取FlutterRenderer
     *
     * @param activity
     * @return
     */
    public static FlutterRenderer getFlutterSurfaceView(Activity activity) {
        FlutterView view = getFlutterView(activity);
        if (view == null) {
            return null;
        }
        FlutterRenderer flutterRenderer = null;
        try {
            Field flutterSurfaceViewField = view.getClass().getDeclaredField("flutterSurfaceView");
            flutterSurfaceViewField.setAccessible(true);
            FlutterSurfaceView flutterSurfaceView = (FlutterSurfaceView) flutterSurfaceViewField.get(view);
            Field FlutterRendererField = FlutterSurfaceView.class.getDeclaredField("flutterRenderer");
            FlutterRendererField.setAccessible(true);
            flutterRenderer = (FlutterRenderer) FlutterRendererField.get(flutterSurfaceView);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            return flutterRenderer;
        }
    }

    /**
     * 获取flutter页面截图
     *
     * @return
     */
    public static Bitmap getFlutterScreenshot(FlutterRenderer flutterRenderer) {
        if (flutterRenderer == null) {
            return null;
        }
        return flutterRenderer.getBitmap();
    }

    /**
     * 获取flutter页面截图
     *
     * @param activity
     * @return
     */
    public static Bitmap getFlutterScreenshot(Activity activity) {
        return getFlutterScreenshot(getFlutterSurfaceView(activity));
    }

    /**
     * 使用截图覆盖flutter页面展示
     */
    public static void coverActivityWithBitmap(Activity activity, Bitmap bitmap) {
        if (activity == null || bitmap == null) {
            return;
        }
        FrameLayout contentView = activity.getWindow().getDecorView().findViewById(Window.ID_ANDROID_CONTENT);
        View view = new View(activity);
        view.setBackground(new BitmapDrawable(activity.getResources(), bitmap));
        ViewGroup.LayoutParams params =
                new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        contentView.addView(view, params);
    }

    /**
     * 使用当前页面截图覆盖flutter页面展示
     */
    public static void coverActivityWithFlutterScreenshot(Activity activity) {
        Bitmap flutterScreenshot = getFlutterScreenshot(activity);
        if (flutterScreenshot != null) {
            coverActivityWithBitmap(activity, getFlutterScreenshot(activity));
        }
    }

}
