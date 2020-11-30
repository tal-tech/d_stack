package tal.com.d_stack.lifecycle;


import java.util.List;

import tal.com.d_stack.channel.DStackMethodHandler;
import tal.com.d_stack.node.DNode;
import tal.com.d_stack.node.DNodeManager;
import tal.com.d_stack.node.constants.DNodeActionType;
import tal.com.d_stack.node.constants.DNodePageType;
import tal.com.d_stack.utils.DLog;

/**
 * 页面状态管理
 */
public class PageLifecycleManager {

    /**
     * app启动
     */
    public static void appCreate() {
        DLog.logD("appCreate");
        PageModel pageModel = new PageModel();
        pageModel.setState(PageState.APP_CREATE);
        DNode node = DNodeManager.getInstance().getCurrentNode();
        if (node == null) {
            pageModel.setCurrentPageRoute("/");
            pageModel.setCurrentPageType(DNodePageType.DNodePageTypeFlutter);
        } else {
            pageModel.setCurrentPageRoute(node.getTarget());
            pageModel.setCurrentPageType(DNodePageType.DNodePageTypeNative);
        }
        DStackMethodHandler.sendAppLifeCircle(pageModel);
    }

    /**
     * app进入前台
     */
    public static void appForeground() {
        DLog.logD("appForeground");
        PageModel pageModel = new PageModel();
        pageModel.setState(PageState.APP_FOREGROUND);
        DNode node = DNodeManager.getInstance().getCurrentNode();
        if (node == null) {
            pageModel.setCurrentPageRoute("/");
            pageModel.setCurrentPageType(DNodePageType.DNodePageTypeFlutter);
        } else {
            pageModel.setCurrentPageRoute(node.getTarget());
            pageModel.setCurrentPageType(node.getPageType());
        }
        DStackMethodHandler.sendAppLifeCircle(pageModel);
    }

    /**
     * app进入后台
     */
    public static void appBackground() {
        DLog.logD("appBackground");
        PageModel pageModel = new PageModel();
        pageModel.setState(PageState.APP_BACKGROUND);
        DNode node = DNodeManager.getInstance().getCurrentNode();
        if (node == null) {
            pageModel.setCurrentPageRoute("/");
            pageModel.setCurrentPageType(DNodePageType.DNodePageTypeFlutter);
        } else {
            pageModel.setCurrentPageRoute(node.getTarget());
            pageModel.setCurrentPageType(node.getPageType());
        }
        DStackMethodHandler.sendAppLifeCircle(pageModel);
    }

    /**
     * 页面出现
     */
    public static void pageAppear(DNode node) {
        DLog.logD("pageAppear");
        if (node == null) {
            return;
        }
        PageModel pageModel = new PageModel();
        pageModel.setActionType(DNodeActionType.DNodeActionTypePush);
        pageModel.setCurrentPageType(node.getPageType());
        pageModel.setCurrentPageRoute(node.getTarget());
        List<DNode> nodeList = DNodeManager.getInstance().getNodeList();
        DNode secondLastNode = null;
        if (nodeList.size() >= 2) {
            secondLastNode = nodeList.get(nodeList.size() - 2);
        }
        if (secondLastNode == null) {
            pageModel.setPrePageType(DNodePageType.DNodePageTypeFlutter);
            pageModel.setPrePageRoute("/");
        } else {
            pageModel.setPrePageType(secondLastNode.getPageType());
            pageModel.setPrePageRoute(secondLastNode.getTarget());
        }

        DStackMethodHandler.sendPageLifeCircle(pageModel);
    }

    /**
     * 页面消失
     */
    public static void pageDisappear(DNode node) {
        DLog.logD("pageAppear");
        if (node == null) {
            return;
        }
        PageModel pageModel = new PageModel();
        pageModel.setActionType(DNodeActionType.DNodeActionTypePop);
        pageModel.setPrePageType(node.getPageType());
        pageModel.setPrePageRoute(node.getTarget());
        List<DNode> nodeList = DNodeManager.getInstance().getNodeList();
        DNode currentNode = null;
        if (nodeList.size() > 0) {
            currentNode = nodeList.get(nodeList.size() - 1);
        }
        if (currentNode == null) {
            pageModel.setCurrentPageType(DNodePageType.DNodePageTypeFlutter);
            pageModel.setCurrentPageRoute("/");
        } else {
            pageModel.setCurrentPageType(currentNode.getPageType());
            pageModel.setCurrentPageRoute(currentNode.getTarget());
        }
        DStackMethodHandler.sendPageLifeCircle(pageModel);
    }

    /**
     * 页面出现处理节点替换情况
     */
    public static void pageAppearWithReplace(DNode preNode, DNode currentNode) {
        DLog.logE("pageAppearWithReplace");
        if (preNode == null || currentNode == null) {
            return;
        }
        PageModel pageModel = new PageModel();
        pageModel.setActionType(DNodeActionType.DNodeActionTypePush);
        pageModel.setCurrentPageType(currentNode.getPageType());
        pageModel.setCurrentPageRoute(currentNode.getTarget());
        pageModel.setPrePageType(preNode.getPageType());
        pageModel.setPrePageRoute(preNode.getTarget());
        DStackMethodHandler.sendPageLifeCircle(pageModel);
    }

}
