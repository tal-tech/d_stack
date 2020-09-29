package tal.com.d_stack.observer;

import android.app.Activity;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

/**
 * 需要过滤的第三方activity管理
 */
public class FilterActivityManager {

    private final static AtomicReference<FilterActivityManager> INSTANCE = new AtomicReference<>();

    public static FilterActivityManager getInstance() {
        for (; ; ) {
            FilterActivityManager factory = INSTANCE.get();
            if (factory != null) {
                return factory;
            }
            factory = new FilterActivityManager();
            if (INSTANCE.compareAndSet(null, factory)) {
                return factory;
            }
        }
    }

    private FilterActivityManager() {
        filterActivities.add("rom.huawei");
        filterActivities.add("rom.oppo");
        filterActivities.add("com.tencent");
    }

    private List<String> filterActivities = new ArrayList<>();

    public boolean canAdd(Activity activity) {
        if (activity == null) {
            return false;
        }
        String fullName = activity.getClass().getName();
        for (String filterName : filterActivities) {
            if (fullName.contains(filterName)) {
                return false;
            }
        }
        return true;
    }
}
