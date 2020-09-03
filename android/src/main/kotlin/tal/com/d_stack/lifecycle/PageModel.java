package tal.com.d_stack.lifecycle;


/**
 * 页面状态信息
 */
public class PageModel {

    // 当前展示的页面路由
    private String currentPageRoute;
    // 前一个展示的页面路由，可能为null
    private String prePageRoute;
    // 页面类型：Flutter/Native
    private String currentPageType;
    // 页面类型：Flutter/Native
    private String prePageType;
    // 操作类型：push/pop
    private String actionType;
    // 应用状态 0:应用启动 1:前台 2:后台 3:应用杀死
    private int state = 0;

    public String getCurrentPageRoute() {
        return currentPageRoute;
    }

    public void setCurrentPageRoute(String currentPageRoute) {
        this.currentPageRoute = currentPageRoute;
    }

    public String getPrePageRoute() {
        return prePageRoute;
    }

    public void setPrePageRoute(String prePageRoute) {
        this.prePageRoute = prePageRoute;
    }

    public String getCurrentPageType() {
        return currentPageType;
    }

    public void setCurrentPageType(String currentPageType) {
        this.currentPageType = currentPageType;
    }

    public String getPrePageType() {
        return prePageType;
    }

    public void setPrePageType(String prePageType) {
        this.prePageType = prePageType;
    }

    public String getActionType() {
        return actionType;
    }

    public void setActionType(String actionType) {
        this.actionType = actionType;
    }

    public int getState() {
        return state;
    }

    public void setState(int state) {
        this.state = state;
    }
}
