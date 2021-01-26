package tal.com.d_stack.node;

import android.text.TextUtils;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicReference;

import tal.com.d_stack.action.DActionManager;
import tal.com.d_stack.action.DOperationManager;
import tal.com.d_stack.lifecycle.PageLifecycleManager;
import tal.com.d_stack.node.constants.DNodeActionType;
import tal.com.d_stack.node.constants.DNodePageType;
import tal.com.d_stack.observer.DStackActivityManager;
import tal.com.d_stack.utils.DLog;

/**
 * 节点管理
 */
public class DNodeManager {

    private final static AtomicReference<DNodeManager> INSTANCE = new AtomicReference<>();

    //当前节点集合
    List<DNode> nodeList = new ArrayList<>();
    //需要移除的节点在节点集合的索引
    List<Integer> needRemoveNodesIndex = new ArrayList<>();
    //需要移除的节点集合
    List<DNode> needRemoveNodes = new ArrayList<>();
    //当前节点
    DNode currentNode;
    //节点动作类型
    String actionType;

    public static DNodeManager getInstance() {
        for (; ; ) {
            DNodeManager factory = INSTANCE.get();
            if (factory != null) {
                return factory;
            }
            factory = new DNodeManager();
            if (INSTANCE.compareAndSet(null, factory)) {
                return factory;
            }
        }
    }

    //获取当前节点
    public DNode getCurrentNode() {
        return currentNode;
    }

    //检查节点
    public void checkNode(DNode node) {
        if (node == null) {
            return;
        }
        actionType = node.getAction();
        switch (actionType) {
            case DNodeActionType.DNodeActionTypePush:
            case DNodeActionType.DNodeActionTypePresent:
                //打开新页面
                //入栈管理
                //去重逻辑
                DLog.logD("----------push方法开始----------");
                handlePush(node);
                updateNodes();
                DActionManager.push(node);
                PageLifecycleManager.pageAppear(node);
                DLog.logD("----------push方法结束----------");
                break;
            case DNodeActionType.DNodeActionTypePop:
            case DNodeActionType.DNodeActionTypeDissmiss:
                //返回上一个页面
                //出栈管理
                //移除最后一个节点即可
                DLog.logD("----------pop方法开始----------");
                DLog.logD("node出栈，target：" + node.getTarget());
                if (node.isFromFlutter()) {
                    //此处是flutter侧点击左上角返回键的逻辑
                    //flutter页面触发的pop有可能不带target信息，需要手动添加
                    //所有flutter侧页面关闭删除节点的逻辑都在handleNeedRemoveNode实现
                    node.setTarget(currentNode.getTarget());
                    node.setPageType(currentNode.getPageType());
                    node.setHomePage(currentNode.isHomePage());
                    node.setRootPage(currentNode.isRootPage());
                    node.setIdentifier(currentNode.getIdentifier());
                    DActionManager.pop(node);
                    updateNodes();
                } else {
                    //此处处理activity onDestroy逻辑
                    removeNodeWithOnDestroyed(node);
                }
                DLog.logD("----------pop方法结束----------");
                break;
            case DNodeActionType.DNodeActionTypePopTo:
                //返回指定页面
                DLog.logD("----------popTo方法开始----------");
                needRemoveNodes.clear();
                needRemoveNodesIndex.clear();
                needRemoveNodes = needRemoveNodes(node);
                DNode popToNode = getCurrentNode();
                deleteNodes();
                updateNodes();
                DActionManager.popTo(node, needRemoveNodes);
                PageLifecycleManager.pageDisappear(popToNode);
                DLog.logD("----------popTo方法结束----------");
                break;
            case DNodeActionType.DNodeActionTypePopToRoot:
                //返回最根节点
                DLog.logD("----------popToRoot方法开始----------");
                needRemoveNodes.clear();
                needRemoveNodesIndex.clear();
                needRemoveNodes = popToRootNeedRemoveNodes();
                DNode popToRootNode = getCurrentNode();
                deleteNodes();
                updateNodes();
                DActionManager.popToRoot(node, needRemoveNodes);
                PageLifecycleManager.pageDisappear(popToRootNode);
                DLog.logD("----------popToRoot方法结束----------");
                break;
            case DNodeActionType.DNodeActionTypePopSkip:
                DLog.logD("----------popSkip方法开始----------");
                needRemoveNodes.clear();
                needRemoveNodesIndex.clear();
                needRemoveNodes = needSkipNodes(node);
                DNode popSkipNode = getCurrentNode();
                deleteNodes();
                updateNodes();
                DActionManager.popSkip(node, needRemoveNodes);
                PageLifecycleManager.pageDisappear(popSkipNode);
                DLog.logD("----------popSkip方法结束----------");
                break;
            case DNodeActionType.DNodeActionTypeGesture:
                DLog.logD("----------gesture方法开始----------");
                nodeList.remove(nodeList.size() - 1);
                DLog.logD("----------gesture方法结束----------");
                updateNodes();
                DActionManager.gesture(node);
                break;
            case DNodeActionType.DNodeActionTypeReplace:
                DLog.logD("----------replace方法开始----------");
                DNode preNode = currentNode;
                if (node.isFromFlutter()) {
                    currentNode.setTarget(node.getTarget());
                    currentNode.setPageType(DNodePageType.DNodePageTypeFlutter);
                    currentNode.setParams(node.getParams());
                    currentNode.setIdentifier(node.getIdentifier());

                }
                updateNodes();
                PageLifecycleManager.pageAppearWithReplace(preNode, currentNode);
                DActionManager.replace(node);
                DLog.logD("----------replace方法结束----------");
                break;
            default:
                break;
        }
    }

    /**
     * 处理push过来的节点
     */
    private void handlePush(DNode node) {
        boolean repeat = repeatNode(node);
        if (!repeat) {
            nodeList.add(node);
            DLog.logD("node入栈，target：" + node.getTarget());
        } else {
            DLog.logD("node入栈被去重");
        }
    }

    /**
     * 如果node信息来自flutter并且页面类型是native，那么不记录节点，由页面拦截触发
     */
    private boolean repeatNode(DNode node) {
        return node.isFromFlutter() && node.getPageType().equals(DNodePageType.DNodePageTypeNative);
    }

    /**
     * 把要返回的目标页节点后面的所有节点按顺序添加到一个集合中
     */
    private List<DNode> needRemoveNodes(DNode node) {
        List<DNode> removeNodeList = new ArrayList<>();
        boolean startAddRemoveList = true;
        boolean existNode = false;
        int size = nodeList.size();
        for (DNode tempNode : nodeList) {
            if (tempNode.getTarget().equals(node.getTarget())) {
                existNode = true;
                break;
            }
        }
        if (existNode) {
            for (int i = size - 1; i >= 0; i--) {
                DNode currentNode = nodeList.get(i);
                if (currentNode.getTarget().equals(node.getTarget())) {
                    startAddRemoveList = false;
                }
                if (startAddRemoveList) {
                    removeNodeList.add(currentNode);
                    needRemoveNodesIndex.add(i);
                }
            }
        }
        Collections.reverse(removeNodeList);
        return removeNodeList;
    }

    /**
     * native工程返回根节点，节点集合只需要保存一个元素
     */
    private List<DNode> popToRootNeedRemoveNodes() {
        List<DNode> removeNodeList = new ArrayList<>();
        boolean startAddRemoveList = true;
        int size = nodeList.size();
        for (int i = size - 1; i >= 0; i--) {
            DNode tempNode = nodeList.get(i);
            if (i == 0) {
                startAddRemoveList = false;
            }
            if (startAddRemoveList) {
                removeNodeList.add(tempNode);
                needRemoveNodesIndex.add(i);
            }
        }
        Collections.reverse(removeNodeList);
        return removeNodeList;
    }

    /**
     * 从节点列表中删除指定节点集合
     */
    private void deleteNodes() {
        DLog.logD("从节点中删除指定元素索引: " + needRemoveNodesIndex.toString());
        for (int i : needRemoveNodesIndex) {
            nodeList.remove(i);
        }
    }

    /**
     * 通过路由从混合栈底开始查找相同的节点
     */
    public DNode findNodeByRouter(String pageRouter) {
        if (TextUtils.isEmpty(pageRouter)) {
            return null;
        }
        int size = nodeList.size();
        if (size == 0) {
            return null;
        }
        for (int i = size - 1; i >= 0; i--) {
            DNode currentNode = nodeList.get(i);
            if (currentNode.getTarget().equals(pageRouter)) {
                DLog.logD("findNodeByRouter：" + pageRouter);
                return nodeList.get(i);
            }
        }
        return null;
    }

    /**
     * 需要移除的节点索引
     */
    private List<DNode> needSkipNodes(DNode node) {
        List<DNode> removeNodeList = new ArrayList<>();
        boolean startAddRemoveList;
        int size = nodeList.size();
        for (int i = size - 1; i >= 0; i--) {
            DNode currentNode = nodeList.get(i);
            //如果当前节点路由包含要skip的模块路由，则添加
            startAddRemoveList = currentNode.getTarget().contains(node.getTarget());
            if (startAddRemoveList) {
                removeNodeList.add(currentNode);
                needRemoveNodesIndex.add(i);
            } else {
                break;
            }
        }
        Collections.reverse(removeNodeList);
        return removeNodeList;
    }

    /**
     * 每次操作后，更新节点信息
     */
    public void updateNodes() {
        DLog.logE("-----更新节点开始-----");
        int size = nodeList.size();
        if (size == 0) {
            currentNode = null;
            DLog.logE("当前栈的currentNode为null");
            return;
        }
        currentNode = nodeList.get(size - 1);
        DLog.logE("当前栈的currentNode：" + currentNode.getTarget());
        for (DNode node : nodeList) {
            DLog.logE(node.getPageType() + "--" + node.getTarget());
        }
        DLog.logE("-----更新节点结束-----");
    }

    /**
     * 由flutter侧的didPop触发，或者flutter根节点清除时触发，只有flutter页面真正关闭才会收到消息
     * 当前节点的target和flutter传入的节点target一致，则删除
     */
    public void handleNeedRemoveFlutterNode(DNode node) {
        DLog.logD("----------handleNeedRemoveFlutterNode方法开始----------");
        if (nodeList.size() == 0 || currentNode == null) {
            return;
        }
        //判断是否临界状态
        boolean isCritical = isCritical(node);
        if (isCritical) {
            //临界状态，当前清除节点flutter，上一个节点native
            if (DStackActivityManager.getInstance().isExecuteStack()) {
                //正在进行popTo等关闭多个页面操作，直接返回
                return;
            }
            //关闭栈顶flutter控制器
            DStackActivityManager.getInstance().closeTopFlutterActivity();
        } else {
            //如果当前节点的target和已经关闭的flutter页面的节点target相同，则把当前节点数据清除
            if (currentNode.getPageType().equals(DNodePageType.DNodePageTypeFlutter)) {
                if (currentNode.getTarget().equals(node.getTarget())) {
                    nodeList.remove(currentNode);
                    updateNodes();
                    PageLifecycleManager.pageDisappear(node);
                    DOperationManager.operation(node);
                }
            }
        }
        DLog.logD("----------handleNeedRemoveFlutterNode方法结束----------");
    }

    /**
     * 当activity执行了onDestroyed()之后
     * 把当前的native节点删除
     */
    public void removeNodeWithOnDestroyed(DNode node) {
        DLog.logD("----------removeNodeWithOnDestroyed方法开始----------");
        if (node.isPopTo() || nodeList == null) {
            return;
        }
        //从节点集合反向遍历第一个匹配的节点信息并移除
        DNode needRemoveNode = findNodeByRouter(node.getTarget());
        if (needRemoveNode != null) {
            nodeList.remove(needRemoveNode);
            PageLifecycleManager.pageDisappear(node);
            node.setBoundary(needRemoveNode.isBoundary());
            DOperationManager.operation(node);
        }
        updateNodes();
        DLog.logD("----------removeNodeWithOnDestroyed方法结束----------");
    }

    /**
     * 获取节点集合
     */
    public List<DNode> getNodeList() {
        return nodeList;
    }

    /**
     * 移除最后一个节点
     */
    public void deleteLastNode() {
        if (nodeList != null && nodeList.size() > 0) {
            nodeList.remove(nodeList.size() - 1);
            updateNodes();
        }
    }

    /**
     * 添加最后一个节点
     */
    public void addLastNode(DNode node) {
        if (nodeList != null) {
            nodeList.add(node);
            updateNodes();
        }
    }

    /**
     * 节点是否处在临界状态
     */
    public boolean isCritical(DNode node) {
        if (nodeList != null) {
            if (nodeList.size() == 0) {
                return true;
            }
            if (node.getPageType().equals(DNodePageType.DNodePageTypeFlutter)
                    && currentNode.getPageType().equals(DNodePageType.DNodePageTypeFlutter)
                    && node.getTarget().equals(currentNode.getTarget())) {
                if (nodeList.size() >= 2) {
                    DNode lastSecondNode = nodeList.get(nodeList.size() - 2);
                    if (lastSecondNode.getPageType().equals(DNodePageType.DNodePageTypeNative)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }


    public DNodeResponse createNodeResponse(DNode node) {
        DNodeResponse nodeResponse = new DNodeResponse();
        nodeResponse.target = node.getTarget();
        nodeResponse.pageType = node.getPageType();
        nodeResponse.action = node.getAction();
        nodeResponse.params = node.getParams();
        nodeResponse.homePage = node.isHomePage();
        nodeResponse.animated = node.isAnimated();
        nodeResponse.boundary = node.isBoundary();
        nodeResponse.identifier = node.getIdentifier();
        return nodeResponse;
    }

}