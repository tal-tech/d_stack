package tal.com.d_stack.node;

import android.app.Activity;

import java.lang.ref.WeakReference;
import java.util.HashMap;
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
    private String target;

    // 附带参数
    private Map<String, Object> params;

    // 是否来自flutter消息通道的node
    private boolean fromFlutter;

    // 节点对应的activity
    private WeakReference<Activity> activity;

    // 是否正在执行popTo，popToRoot，popToSkip方法
    private boolean popTo;

    // 是否是flutter主页面
    private boolean homePage;

    //是否是根页面
    private boolean rootPage;

    //flutter临界节点，native打开flutter使用
    private boolean boundary;

    //是否开启转场动画
    private boolean animated;

    //页面唯一标识
    private String identifier;

    public DNode(Builder builder) {
        this.action = builder.action;
        this.pageType = builder.pageType;
        this.target = builder.target;
        this.params = builder.params;
        this.homePage = builder.homePage;
        this.boundary = builder.boundary;
        this.animated = builder.animated;
        this.fromFlutter = builder.fromFlutter;
        this.activity = builder.activity;
        this.popTo = builder.popTo;
        this.rootPage = builder.rootPage;
        this.identifier = builder.identifier;
    }

    public String getIdentifier() {
        return identifier;
    }

    public void setIdentifier(String identifier) {
        this.identifier = identifier;
    }


    public static class Builder {
        private String action = "";
        private String pageType = "";
        private String target = "";
        private Map<String, Object> params = new HashMap<>();
        private boolean homePage = false;
        private boolean boundary = false;
        private boolean animated = false;
        private boolean fromFlutter = false;
        private WeakReference<Activity> activity = null;
        private boolean popTo = false;
        private boolean rootPage = false;
        private String identifier = "";

        public Builder action(String action) {
            this.action = action;
            return this;
        }

        public Builder pageType(String pageType) {
            this.pageType = pageType;
            return this;
        }

        public Builder target(String target) {
            this.target = target;
            return this;
        }

        public Builder params(Map<String, Object> params) {
            this.params = params;
            return this;
        }

        public Builder isHomePage(boolean isHomePage) {
            this.homePage = isHomePage;
            return this;
        }

        public Builder boundary(boolean boundary) {
            this.boundary = boundary;
            return this;
        }

        public Builder animated(boolean animated) {
            this.animated = animated;
            return this;
        }

        public Builder fromFlutter(boolean fromFlutter) {
            this.fromFlutter = fromFlutter;
            return this;
        }

        public Builder activity(WeakReference<Activity> activity) {
            this.activity = activity;
            return this;
        }

        public Builder isPopTo(boolean isPopTo) {
            this.popTo = isPopTo;
            return this;
        }

        public Builder isRootPage(boolean isRootPage) {
            this.rootPage = isRootPage;
            return this;
        }

        public Builder identifier(String identifier) {
            this.identifier = identifier;
            return this;
        }

        public DNode build() {
            return new DNode(this);
        }
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

    public Map<String, Object> getParams() {
        return params;
    }

    public void setParams(Map<String, Object> params) {
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

    public WeakReference<Activity> getActivity() {
        return activity;
    }

    public void setActivity(WeakReference<Activity> activity) {
        this.activity = activity;
    }

    public boolean isPopTo() {
        return popTo;
    }

    public void setPopTo(boolean popTo) {
        this.popTo = popTo;
    }

    public boolean isHomePage() {
        return homePage;
    }

    public void setHomePage(boolean homePage) {
        this.homePage = homePage;
    }

    public boolean isRootPage() {
        return rootPage;
    }

    public void setRootPage(boolean rootPage) {
        this.rootPage = rootPage;
    }

    public boolean isBoundary() {
        return boundary;
    }

    public void setBoundary(boolean boundary) {
        this.boundary = boundary;
    }

    public boolean isAnimated() {
        return animated;
    }

    public void setAnimated(boolean animated) {
        this.animated = animated;
    }

    @Override
    public String toString() {
        return "DNode{" +
                "action='" + action + '\'' +
                ", pageType='" + pageType + '\'' +
                ", target='" + target + '\'' +
                ", params=" + params + '\'' +
                ", fromFlutter=" + fromFlutter + '\'' +
                ", activity=" + activity + '\'' +
                ", popTo=" + popTo + '\'' +
                ", homePage=" + homePage + '\'' +
                ", rootPage=" + rootPage + '\'' +
                ", boundary=" + boundary + '\'' +
                ", animated=" + animated + '\'' +
                ", identifier='" + identifier + '\'' +
                '}';
    }
}