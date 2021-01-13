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
        filterActivities.add("com.sina");
        filterActivities.add("com.tal.d_stack_spy");
        filterActivities.add("com.yorhp");
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

    /**
     * 添加过滤器
     * 某些功能性Activity，不需要做节点管理的，添加至过滤
     *
     * @param filterString 过滤字符串
     * @return
     */
    public boolean addFilter(String filterString) {
        return filterActivities.add(filterString);
    }

    /**
     * 移除已添加的过滤器
     *
     * @param filterString
     * @return
     */
    public boolean removeFilter(String filterString) {
        return filterActivities.remove(filterString);
    }
}
