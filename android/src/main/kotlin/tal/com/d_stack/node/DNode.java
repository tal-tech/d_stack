package tal.com.d_stack.node;

import android.app.Activity;

import java.lang.ref.WeakReference;
import java.util.Map;

/**
 * 页面节点信息
 */
public class DNode {

    // 页面跳转类型
    private String action;

    // 页面类型
    private String pageType;

    // 页面唯一标识
    // flutter页面时，是route，native唯一id
    private String target = "";

    //native页面的唯一id
    private String uniqueId = "";

    // 附带参数
    private Map<String, Object> params;

    // 是否来自flutter消息通道的node
    private boolean fromFlutter;

    // 节点对应的activity
    private WeakReference<Activity> activity;

    // 是否正在执行popTo，popToRoot，popToSkip方法
    private boolean isPopTo;

    // 是否是flutter主页面
    private boolean isHomePage;

    // 页面路由和类型组合的map
    private Map<String, String> pageTypeMap;

    //是否是根页面
    private boolean isRootPage;

    public DNode() {
    }

    public String getTarget() {
        return target;
    }

    public void setTarget(String target) {
        this.target = target;
    }

    public boolean isFromFlutter() {
        return fromFlutter;
    }

    public void setFromFlutter(boolean fromFlutter) {
        this.fromFlutter = fromFlutter;
    }

    public Map getParams() {
        return params;
    }

    public void setParams(Map params) {
        this.params = params;
    }

    public String getAction() {
        return action;
    }

    public void setAction(String action) {
        this.action = action;
    }

    public String getPageType() {
        return pageType;
    }

    public void setPageType(String pageType) {
        this.pageType = pageType;
    }

    public String getUniqueId() {
        return uniqueId;
    }

    public void setUniqueId(String uniqueId) {
        this.uniqueId = uniqueId;
    }

    public WeakReference<Activity> getActivity() {
        return activity;
    }

    public void setActivity(WeakReference<Activity> activity) {
        this.activity = activity;
    }

    public boolean isPopTo() {
        return isPopTo;
    }

    public void setPopTo(boolean popTo) {
        isPopTo = popTo;
    }

    public boolean isHomePage() {
        return isHomePage;
    }

    public void setHomePage(boolean homePage) {
        isHomePage = homePage;
    }

    public Map<String, String> getPageTypeMap() {
        return pageTypeMap;
    }

    public void setPageTypeMap(Map<String, String> pageTypeMap) {
        this.pageTypeMap = pageTypeMap;
    }

    public boolean isRootPage() {
        return isRootPage;
    }

    public void setRootPage(boolean rootPage) {
        isRootPage = rootPage;
    }
}