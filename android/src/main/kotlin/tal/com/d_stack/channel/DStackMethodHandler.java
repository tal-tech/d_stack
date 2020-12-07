package tal.com.d_stack.channel;


import android.util.Log;

import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import tal.com.d_stack.DStack;
import tal.com.d_stack.lifecycle.PageModel;
import tal.com.d_stack.node.DNode;
import tal.com.d_stack.node.DNodeManager;
import tal.com.d_stack.node.DNodeResponse;
import tal.com.d_stack.utils.DLog;

/**
 * 框架消息通道
 */
public class DStackMethodHandler implements MethodChannel.MethodCallHandler {

    /**
     * native侧接受flutter侧发来的消息
     */
    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        String method = methodCall.method;
        Map<String, Object> args = (Map<String, Object>) methodCall.arguments;
        switch (method) {
            case "sendNodeToNative":
                handleSendNodeToNative(args);
                break;
            case "sendRemoveFlutterPageNode":
                handleSendRemoveFlutterPageNode(args);
                break;
            case "sendNodeList":
                handleSendNodeList(result);
                break;
            default:
                break;
        }
    }

    /**
     * flutter侧发来的节点信息
     */
    private static void handleSendNodeToNative(Map<String, Object> args) {
        DNode node = createNodeFromFlutter(args);
        if (node != null) {
            DLog.logD("----------接收handleSendNodeToNative消息----------");
            DLog.logD(node.toString());
            DLog.logD("----------接收handleSendNodeToNative消息----------");
            DNodeManager.getInstance().checkNode(node);
        }
    }

    /**
     * flutter侧发来的要移除的节点信息
     */
    private static void handleSendRemoveFlutterPageNode(Map<String, Object> args) {
        DNode node = createNodeFromFlutter(args);
        if (node != null) {
            DLog.logD("----------接收handleSendRemoveFlutterPageNode消息----------");
            DLog.logD(node.toString());
            DLog.logD("----------接收handleSendRemoveFlutterPageNode消息----------");
            DNodeManager.getInstance().handleNeedRemoveFlutterNode(node);
        }
    }

    /**
     * flutter侧发来的获取节点列表
     */
    private void handleSendNodeList(MethodChannel.Result result) {
        List<DNode> nodeList = DNodeManager.getInstance().getNodeList();
        List<Map<String, Object>> resultList = new ArrayList<>();
        for (DNode node : nodeList) {
            Map<String, Object> tempMap = new HashMap<>();
            tempMap.put("route", node.getTarget());
            tempMap.put("pageType", node.getPageType());
            resultList.add(tempMap);
        }
        result.success(resultList);
    }

    /**
     * native侧发送单个节点给flutter侧
     */
    public static void sendNode(DNodeResponse nodeResponse, String action, boolean animated) {
        Map<String, Object> resultMap = new HashMap();
        List<Map<String, Object>> nodes = new ArrayList<>();
        nodes.add(nodeResponse.toMap());
        resultMap.put("nodes", nodes);
        resultMap.put("action", action);
        resultMap.put("animated", animated);
        DStack.getInstance().getMethodChannel().invokeMethod("sendActionToFlutter", resultMap, new MethodChannel.Result() {
            @Override
            public void success(Object result) {

            }

            @Override
            public void error(String errorCode, String errorMessage, Object errorDetails) {

            }

            @Override
            public void notImplemented() {

            }
        });
        DLog.logD("----------发送sendNode消息----------");
        JSONObject jsonObject = new JSONObject(resultMap);
        DLog.logD(jsonObject.toString());
        DLog.logD("----------发送sendNode消息----------");
    }

    /**
     * native侧发送节点集合给flutter侧
     */
    public static void sendNode(List<Map<String, Object>> flutterNodes, String action, boolean animated) {
        Map<String, Object> resultMap = new HashMap();
        List<Map<String, Object>> nodes = new ArrayList<>();
        nodes.addAll(flutterNodes);
        resultMap.put("nodes", nodes);
        resultMap.put("action", action);
        resultMap.put("animated", animated);
        DStack.getInstance().getMethodChannel().invokeMethod("sendActionToFlutter", resultMap, new MethodChannel.Result() {
            @Override
            public void success(Object result) {

            }

            @Override
            public void error(String errorCode, String errorMessage, Object errorDetails) {

            }

            @Override
            public void notImplemented() {

            }
        });
        DLog.logD("----------发送sendNode消息----------");
        JSONObject jsonObject = new JSONObject(resultMap);
        DLog.logD(jsonObject.toString());
        DLog.logD("----------发送sendNode消息----------");
    }


    /**
     * native侧发送页面的生命周期
     */
    public static void sendPageLifeCircle(PageModel pageModel) {
        Map<String, Object> resultMap = new HashMap();
        Map<String, Object> pageInfo = new HashMap();
        pageInfo.put("appearRoute", pageModel.getCurrentPageRoute());
        pageInfo.put("appearPageType", pageModel.getCurrentPageType());
        pageInfo.put("disappearRoute", pageModel.getPrePageRoute());
        pageInfo.put("disappearPageType", pageModel.getPrePageType());
        pageInfo.put("actionType", pageModel.getActionType());
        resultMap.put("page", pageInfo);
        DStack.getInstance().getMethodChannel().invokeMethod("sendLifeCycle", resultMap, new MethodChannel.Result() {
            @Override
            public void success(Object result) {

            }

            @Override
            public void error(String errorCode, String errorMessage, Object errorDetails) {

            }

            @Override
            public void notImplemented() {

            }
        });
    }

    /**
     * native侧发送应用的生命周期
     */
    public static void sendAppLifeCircle(PageModel pageModel) {
        Map<String, Object> resultMap = new HashMap();
        Map<String, Object> appInfo = new HashMap();
        appInfo.put("currentRoute", pageModel.getCurrentPageRoute());
        appInfo.put("pageType", pageModel.getCurrentPageType());
        appInfo.put("state", pageModel.getState());
        resultMap.put("application", appInfo);
        DStack.getInstance().getMethodChannel().invokeMethod("sendLifeCycle", resultMap, new MethodChannel.Result() {
            @Override
            public void success(Object result) {

            }

            @Override
            public void error(String errorCode, String errorMessage, Object errorDetails) {

            }

            @Override
            public void notImplemented() {

            }
        });
    }

    /**
     * native侧发送节点的操作
     */
    public static void sendNodeOperation(DNodeResponse nodeResponse) {
        Map<String, Object> resultMap = new HashMap();
        resultMap.put("target", nodeResponse.target);
        resultMap.put("pageType", nodeResponse.pageType);
        resultMap.put("action", nodeResponse.action);
        resultMap.put("params", nodeResponse.params);
        resultMap.put("homePage", nodeResponse.homePage);
        resultMap.put("boundary", nodeResponse.boundary);
        resultMap.put("animated", nodeResponse.animated);
        resultMap.put("identifier", nodeResponse.identifier);
        DStack.getInstance().getMethodChannel().invokeMethod("sendOperationNodeToFlutter", resultMap, new MethodChannel.Result() {
            @Override
            public void success(Object result) {

            }

            @Override
            public void error(String errorCode, String errorMessage, Object errorDetails) {

            }

            @Override
            public void notImplemented() {

            }
        });
    }

    /**
     * 根据flutter侧传来的信息创建节点
     */
    public static DNode createNodeFromFlutter(Map<String, Object> args) {
        if (args == null) {
            return null;
        }
        String target = "";
        String pageType = "";
        String actionType = "";
        Map<String, Object> params = new HashMap<>();
        boolean homePage = false;
        boolean animated = false;
        String identifier = "";
        if (args.get("target") != null) {
            target = (String) args.get("target");
        }
        if (args.get("pageType") != null) {
            pageType = (String) args.get("pageType");
        }
        if (args.get("actionType") != null) {
            actionType = (String) args.get("actionType");
        }
        if (args.get("params") != null) {
            params = (Map<String, Object>) args.get("params");
        }
        if (args.get("homePage") != null) {
            homePage = (boolean) args.get("homePage");
        }
        if (args.get("animated") != null) {
            animated = (boolean) args.get("animated");
        }
        if (args.get("identifier") != null) {
            identifier = (String) args.get("identifier");
        }
        //创建Node节点信息
        DNode node = new DNode.Builder()
                .target(target)
                .pageType(pageType)
                .action(actionType)
                .params(params)
                .isHomePage(homePage)
                .animated(animated)
                .identifier(identifier)
                .fromFlutter(true)
                .build();
        return node;
    }
}
