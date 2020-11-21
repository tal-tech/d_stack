package tal.com.d_stack.action;

import android.os.Handler;

import java.util.ArrayList;
import java.util.List;

import tal.com.d_stack.DStack;
import tal.com.d_stack.channel.DStackMethodHandler;
import tal.com.d_stack.node.DNode;
import tal.com.d_stack.node.DNodeManager;
import tal.com.d_stack.node.constants.DNodePageType;
import tal.com.d_stack.observer.DStackActivityManager;

/**
 * 页面实际跳转动作管理
 */
public class DActionManager {

    /**
     * 打开页面
     */
    public static void push(DNode node) {
        enterPageWithNode(node);
    }

    /**
     * 返回当前页面
     */
    public static void pop(DNode node) {
        closePageWithNode(node);
    }

    /**
     * 返回指定页面
     */
    public static void popTo(DNode node, List<DNode> removeNodes) {
        closePageWithNodes(node, removeNodes);
    }

    /**
     * 返回指定模块页面
     */
    public static void popSkip(DNode node, List<DNode> removeNodes) {
        closePageWithNodes(node, removeNodes);
    }

    /**
     * 打开页面，根据页面类型做不同处理
     */
    private static void enterPageWithNode(DNode node) {
        if (node.isFromFlutter()) {
            // 来自flutter消息通道的node，并且是打开native页面
            if (node.getPageType().equals(DNodePageType.DNodePageTypeNative)) {
                // flutter打开native页面，回传给用户侧处理
                DStack.getInstance().getNativeRouter().openContainer(
                        node.getTarget(),
                        node.getParams()
                );
            }
        } else {
            // 只是来自Native的Node，并且是需要打开Flutter页面的，发消息至flutter，打开页面
            if (node.getPageType().equals(DNodePageType.DNodePageTypeFlutter)) {
                List<String> flutterNodes = new ArrayList<>();
                flutterNodes.add(node.getTarget());
                DStackMethodHandler.sendNode(flutterNodes, node);
            }
        }
    }

    /**
     * 关闭页面
     */
    private static void closePageWithNode(DNode node) {
        if (node.getPageType().equals(DNodePageType.DNodePageTypeFlutter)) {
            //pop的是flutter页面，发消息至flutter
            List<String> flutterNodes = new ArrayList<>();
            flutterNodes.add(node.getTarget());
            DStackMethodHandler.sendNode(flutterNodes, node);
        }
    }

    /**
     * 关闭已移除节点集合的所有页面，包括native和flutter
     */
    private static void closePageWithNodes(final DNode node, List<DNode> nodes) {
        final List<String> flutterNodes = new ArrayList<>();
        List<String> nativeNodes = new ArrayList<>();
        int size = nodes.size();
        for (int i = 0; i < size; i++) {
            DNode loopNode = nodes.get(i);
            if (loopNode.getPageType().equals(DNodePageType.DNodePageTypeFlutter)) {
                if (!loopNode.isHomePage()) {
                    flutterNodes.add(loopNode.getTarget());
                }
            } else {
                nativeNodes.add(loopNode.getUniqueId());
            }
        }
        //处理需要关闭的控制器
        DNode currentNode = DNodeManager.getInstance().getCurrentNode();
        if (currentNode == null) {
            DStackActivityManager.getInstance().closeActivityWithBottom();
        } else {
            DStackActivityManager.getInstance().closeActivityWithNode(currentNode);
        }
        //发送消息给flutter侧处理
        //为了保证native侧页面顺利关闭，此处需要延迟一些时间给flutter发消息
        //不然会引起surfaceView的绘制问题
        new Handler().postDelayed(new Runnable() {
            @Override
            public void run() {
                DStackMethodHandler.sendNode(flutterNodes, node);
            }
        }, 150);
    }

    /**
     * 替换当前页面
     */
    public static void replace(DNode node) {
        if (node.isFromFlutter()) {
            if (node.getPageType().equals(DNodePageType.DNodePageTypeFlutter)) {
                List<String> flutterNodes = new ArrayList<>();
                flutterNodes.add(node.getTarget());
                DStackMethodHandler.sendNode(flutterNodes, node);
            }
        }
    }

    /**
     * 判断页面临界状态
     * 当一个flutter页面关闭，节点清除后，看一看当前节点是否是native
     * 如果是native页面，要把最后一个flutter控制器关闭
     */
    public static void checkNodeCritical(DNode node) {
        if (node == null) {
            return;
        }
        if (DStackActivityManager.getInstance().isExecuteStack()) {
            return;
        }
        if (node.getPageType().equals(DNodePageType.DNodePageTypeNative)) {
            //如果当前节点类型是native,则把flutter控制器关掉
            DStackActivityManager.getInstance().closeTopFlutterActivity();
        }
    }
}