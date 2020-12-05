package tal.com.d_stack.action;

import android.os.Handler;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import tal.com.d_stack.DStack;
import tal.com.d_stack.channel.DStackMethodHandler;
import tal.com.d_stack.node.DNode;
import tal.com.d_stack.node.DNodeManager;
import tal.com.d_stack.node.DNodeResponse;
import tal.com.d_stack.node.constants.DNodeActionType;
import tal.com.d_stack.node.constants.DNodePageType;
import tal.com.d_stack.observer.DStackActivityManager;
import tal.com.d_stack.utils.DStackUtils;

/**
 * 页面实际跳转动作管理
 */
public class DActionManager {

    /**
     * 打开页面
     */
    public static void push(DNode node) {
        enterPageWithNode(node, DNodeActionType.DNodeActionTypePush, node.isAnimated());
        DOperationManager.operation(node);
    }

    /**
     * 返回当前页面
     */
    public static void pop(DNode node) {
        closePageWithNode(node, DNodeActionType.DNodeActionTypePop, node.isAnimated());
        DOperationManager.operation(node);
    }

    /**
     * 返回指定页面
     */
    public static void popTo(DNode node, List<DNode> removeNodes) {
        closePageWithNodes(removeNodes, DNodeActionType.DNodeActionTypePopTo, node.isAnimated());
        DOperationManager.operation(node);
    }

    /**
     * 返回根页面
     */
    public static void popToRoot(DNode node, List<DNode> removeNodes) {
        closePageWithNodes(removeNodes, DNodeActionType.DNodeActionTypePopToRoot, node.isAnimated());
        DOperationManager.operation(node);
    }

    /**
     * 返回指定模块页面
     */
    public static void popSkip(DNode node, List<DNode> removeNodes) {
        closePageWithNodes(removeNodes, DNodeActionType.DNodeActionTypePopSkip, node.isAnimated());
        DOperationManager.operation(node);
    }

    /**
     * 替换页面
     */
    public static void replace(DNode node) {
        DOperationManager.operation(node);
    }

    /**
     * 手势返回页面
     */
    public static void gesture(DNode node) {
        DOperationManager.operation(node);
    }

    /**
     * 打开页面，根据页面类型做不同处理
     */
    private static void enterPageWithNode(DNode node, String action, boolean animated) {
        if (node.isFromFlutter()) {
            // 来自flutter消息通道的node
            if (node.getPageType().equals(DNodePageType.DNodePageTypeNative)) {
                // 打开native页面
                // flutter打开native页面，回传给用户侧处理
                DStack.getInstance().getNativeRouter().openContainer(
                        node.getTarget(),
                        node.getParams()
                );
            } else if (node.getPageType().equals(DNodePageType.DNodePageTypeFlutter)) {
                // 打开flutter页面
                // 给当前flutter节点设置对应的activity
                DNode currentNode = DNodeManager.getInstance().getCurrentNode();
                currentNode.setUniqueId(DStackUtils.generateUniqueId());
                currentNode.setActivity(new WeakReference(DStackActivityManager.getInstance().getTopActivity()));
            }
        } else {
            // 只是来自native的node，并且是需要打开Flutter页面的，发消息至flutter，打开页面
            if (node.getPageType().equals(DNodePageType.DNodePageTypeFlutter)) {
                if (node.isRootPage()) {
                    //flutter根节点，不发通知给flutter
                    return;
                }
                DNodeResponse nodeResponse = DNodeManager.getInstance().createNodeResponse(node);
                DStackMethodHandler.sendNode(nodeResponse, action, animated);
            }
        }
    }

    /**
     * 关闭页面
     */
    private static void closePageWithNode(DNode node, String action, boolean animated) {
        if (node.getPageType().equals(DNodePageType.DNodePageTypeFlutter)) {
            if (node.isRootPage() || node.isHomePage()) {
                //根节点不移除栈，去判断临界状态
                DNodeManager.getInstance().handleNeedRemoveFlutterNode(node);
                return;
            }
            //pop的是flutter页面，发消息至flutter
            DNodeResponse nodeResponse = DNodeManager.getInstance().createNodeResponse(node);
            DStackMethodHandler.sendNode(nodeResponse, action, animated);
        }
    }

    /**
     * 关闭已移除节点集合的所有页面，包括native和flutter
     */
    private static void closePageWithNodes(List<DNode> nodes, final String action, final boolean animated) {
        final List<Map<String, Object>> flutterNodes = new ArrayList<>();
        List<String> nativeNodes = new ArrayList<>();
        int size = nodes.size();
        for (int i = 0; i < size; i++) {
            DNode loopNode = nodes.get(i);
            if (loopNode.getPageType().equals(DNodePageType.DNodePageTypeFlutter)) {
                if (!loopNode.isHomePage()) {
                    DNodeResponse nodeResponse = DNodeManager.getInstance().createNodeResponse(loopNode);
                    flutterNodes.add(nodeResponse.toMap());
                }
            } else {
                nativeNodes.add(loopNode.getUniqueId());
            }
        }
        //处理需要关闭的控制器
        final DNode currentNode = DNodeManager.getInstance().getCurrentNode();
        DStackActivityManager.getInstance().closeActivityWithNode(currentNode);
        //发送消息给flutter侧处理
        //为了保证native侧页面顺利关闭，此处需要延迟一些时间给flutter发消息
        //不然会引起surfaceView的绘制问题
        new Handler().postDelayed(new Runnable() {
            @Override
            public void run() {
                DStackMethodHandler.sendNode(flutterNodes,
                        action,
                        animated);
            }
        }, 150);
    }

    /**
     * 替换当前页面
     */
    public static void replace(DNode node, String action, boolean animated) {
        if (node.isFromFlutter()) {
            if (node.getPageType().equals(DNodePageType.DNodePageTypeFlutter)) {
                DNodeResponse nodeResponse = DNodeManager.getInstance().createNodeResponse(node);
                DStackMethodHandler.sendNode(nodeResponse, action, animated);
            }
        }
    }
}