package tal.com.d_stack.channel;


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
import tal.com.d_stack.utils.DLog;
import tal.com.d_stack.utils.DStackUtils;

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
     * 处理发来的节点信息
     */
    private static void handleSendNodeToNative(Map<String, Object> args) {
        if (args == null) {
            return;
        }
        String actionType = (String) args.get("actionType");
        String target = (String) args.get("target");
        String pageType = (String) args.get("pageType");
        Map<String, Object> params = (Map<String, Object>) args.get("params");
        boolean homePage = false;
        if (args.get("homePage") != null) {
            homePage = (boolean) args.get("homePage");
        }
        //创建Node节点信息
        DNode node = DNodeManager.getInstance().createNode(
                target,
                DStackUtils.generateUniqueId(),
                pageType,
                actionType,
                params,
                true,
                homePage, false);
        DNodeManager.getInstance().checkNode(node);
    }

    //native侧发送节点给flutter侧
    public static void sendNode(List<String> flutterNodes, DNode node) {
        Map<String, Object> resultMap = new HashMap();
        List<String> nodes = new ArrayList<>();
        nodes.addAll(flutterNodes);
        resultMap.put("action", node.getAction());
        resultMap.put("nodes", nodes);
        resultMap.put("params", node.getParams());
        resultMap.put("homePage", node.isHomePage());
        resultMap.put("pageType", node.getPageTypeMap());
        DLog.logD("sendNode信息发送到flutter侧 action: " + node.getAction());
        DLog.logD("sendNode信息发送到flutter侧 nodes: " + nodes.toString());
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
    }

    /**
     * 处理发来的要移除的节点信息
     */
    private static void handleSendRemoveFlutterPageNode(Map<String, Object> args) {
        if (args == null) {
            return;
        }
        String target = (String) args.get("target");
        String pageType = (String) args.get("pageType");
        String actionType = (String) args.get("actionType");
        boolean homePage = false;
        if (args.get("homePage") != null) {
            homePage = (boolean) args.get("homePage");
        }
        DNode node = DNodeManager.getInstance().createNode(
                target,
                "",
                pageType,
                actionType,
                null,
                true, homePage, false);
        DNodeManager.getInstance().handleNeedRemoveFlutterNode(node);
    }

    /**
     * 处理发来的获取节点列表信息
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
}
