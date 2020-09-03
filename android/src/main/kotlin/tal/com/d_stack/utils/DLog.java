package tal.com.d_stack.utils;

import android.util.Log;

import tal.com.d_stack.BuildConfig;

/**
 * 框架日志打印
 */
public class DLog {

    public static String TAG = "DStack";

    public static void logE(String log) {
        if (BuildConfig.DEBUG) {
            Log.e(TAG, log);
        }
    }

    public static void logD(String log) {
        if (BuildConfig.DEBUG) {
            Log.d(TAG, log);
        }
    }
}
