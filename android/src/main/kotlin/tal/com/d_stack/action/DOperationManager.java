package tal.com.d_stack.action;

import tal.com.d_stack.DStack;
import tal.com.d_stack.channel.DStackMethodHandler;
import tal.com.d_stack.node.DNode;
import tal.com.d_stack.node.DNodeManager;
import tal.com.d_stack.node.DNodeResponse;
import tal.com.d_stack.router.INodeOperation;
import tal.com.d_stack.utils.DLog;

/**
 * 节点操作行为记录
 */
public class DOperationManager {
    public static void operation(DNode node) {
        if (!DStack.getInstance().isOpenNodeOperation()) {
            return;
        }
        DNodeResponse nodeResponse = DNodeManager.getInstance().createNodeResponse(node);
        DLog.logE("$$$$$节点操作$$$$$");
        DLog.logE(nodeResponse.action + "-----" + nodeResponse.target);
        DLog.logE("$$$$$节点操作$$$$$");
        DStackMethodHandler.sendNodeOperation(nodeResponse);
        INodeOperation nodeOperation = DStack.getInstance().getNodeOperation();
        if (nodeOperation != null) {
            nodeOperation.operationNode(nodeResponse);
        }
    }
}
