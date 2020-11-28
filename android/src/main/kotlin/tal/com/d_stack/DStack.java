package tal.com.d_stack;

import android.app.Application;
import android.content.Context;
import android.content.Intent;
import android.text.TextUtils;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicReference;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodChannel;
import tal.com.d_stack.channel.DStackMethodHandler;
import tal.com.d_stack.node.DNode;
import tal.com.d_stack.node.DNodeManager;
import tal.com.d_stack.node.constants.DNodeActionType;
import tal.com.d_stack.node.constants.DNodePageType;
import tal.com.d_stack.observer.DStackActivityManager;
import tal.com.d_stack.observer.DStackLifecycleObserver;
import tal.com.d_stack.observer.FilterActivityManager;
import tal.com.d_stack.router.INativeRouter;
import tal.com.d_stack.utils.DLog;

/**
 * DStack入口类
 */
public class DStack {

    private final static AtomicReference<DStack> INSTANCE = new AtomicReference<>();

    public static DStack getInstance() {
        for (; ; ) {
            DStack factory = INSTANCE.get();
            if (factory != null) {
                return factory;
            }
            factory = new DStack();
            if (INSTANCE.compareAndSet(null, factory)) {
                return factory;
            }
        }
    }

    public static final String ENGINE_ID = "d_stack_engine";

    public static final String CHANNEL_ID = "d_stack";

    private FlutterEngine engine;

    private MethodChannel methodChannel;

    private Context context;

    private INativeRouter nativeRouter;

    //是否执行过重置引擎的操作
    private boolean hasBeenExecutedResetAttachEngine = false;

    /**
     * 初始化DStack
     *
     * @param context      全局上下文对象ApplicationContext
     * @param nativeRouter flutter打开native页面的路由回调
     */
    public void init(Context context, INativeRouter nativeRouter) {
        this.context = context;

        engine = new FlutterEngine(context);
        engine.getDartExecutor().executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
        );
        FlutterEngineCache
                .getInstance()
                .put(ENGINE_ID, engine);

        initMethodChannel(engine);
        setNativeRouter(nativeRouter);
        registerAppLifecycleObserver(context);
    }

    /**
     * 注册app生命周期监听 .
     */
    private void registerAppLifecycleObserver(Context context) {
        if (context == null) {
            return;
        }
        if (context instanceof Application) {
            ((Application) context).registerActivityLifecycleCallbacks(new DStackLifecycleObserver());
        }
    }

    /**
     * 初始化channel
     */
    public void initMethodChannel(FlutterEngine engine) {
        methodChannel = new MethodChannel(engine.getDartExecutor(), CHANNEL_ID);
        methodChannel.setMethodCallHandler(new DStackMethodHandler());
    }

    /**
     * 获取engine
     */
    public FlutterEngine getFlutterEngine() {
        return engine;
    }

    /**
     * 获取channel
     */
    public MethodChannel getMethodChannel() {
        return methodChannel;
    }


    /**
     * 设置原生路由回调
     */
    public void setNativeRouter(INativeRouter nativeRouter) {
        this.nativeRouter = nativeRouter;
    }

    /**
     * 获取原生路由回调
     */
    public INativeRouter getNativeRouter() {
        return nativeRouter;
    }

    /**
     * native侧打开flutter页面
     *
     * @param pageRouter   页面路由地址
     * @param params       参数
     * @param containerCls flutter页面容器activity的类对象
     */
    public void pushFlutterPage(String pageRouter, Map<String, Object> params, Class<?> containerCls) {
        DLog.logD("要打开的flutter页面路由是：" + pageRouter);
        DNode node = DNodeManager.getInstance().createNode(
                pageRouter,
                DStackActivityManager.getInstance().generateUniqueId(),
                DNodePageType.DNodePageTypeFlutter,
                DNodeActionType.DNodeActionTypePush,
                params,
                false,
                false, false);
        if (!DStack.getInstance().isFlutterApp()) {
            if (!DStackActivityManager.getInstance().haveFlutterContainer()) {
                node.setHomePage(true);
                Map<String, String> pageTypeMap = new HashMap<>();
                pageTypeMap.put(node.getTarget(), node.getPageType());
                node.setPageTypeMap(pageTypeMap);
            }
        }

        // 如果连续打开同一个Flutter控制器，则做个判断，只打开一次activity
        boolean isSameActivity = DStackActivityManager.getInstance().isSameActivity(containerCls);
        DNodeManager.getInstance().checkNode(node);
        // 先给flutter发消息再打开flutter容器activity，避免短暂白屏问题
        if (!isSameActivity) {
            Intent intent = FlutterActivity.withCachedEngine(ENGINE_ID).build(context);
            intent.setClass(context, containerCls);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
        }
    }

    /**
     * native侧关闭当前页面，暂时只处理关闭flutter页面
     */
    public void pop() {
        DNode currentNode = DNodeManager.getInstance().getCurrentNode();
        if (currentNode == null) {
            return;
        }
        if (currentNode.getPageType().equals(DNodePageType.DNodePageTypeFlutter)) {
            DNode node = DNodeManager.getInstance().createNode(
                    currentNode.getTarget(),
                    currentNode.getUniqueId(),
                    DNodePageType.DNodePageTypeFlutter,
                    DNodeActionType.DNodeActionTypeNativeToFlutterPop,
                    currentNode.getParams(),
                    false, false,
                    currentNode.isHomePage());
            DNodeManager.getInstance().checkNode(node);
        }
    }

    /**
     * native侧关闭flutter页面
     */
    public void popFlutterPage(String pageRouter, Map<String, Object> params) {
        DLog.logE("要关闭的flutter页面路由是：" + pageRouter);
        DNode node = DNodeManager.getInstance().createNode(
                pageRouter,
                "",
                DNodePageType.DNodePageTypeFlutter,
                DNodeActionType.DNodeActionTypePop,
                params,
                false,
                false, false);
        DNodeManager.getInstance().checkNode(node);
    }

    /**
     * native侧返回指定页面
     */
    public void popTo(String pageRouter, Map<String, Object> params) {
        DNode node = DNodeManager.getInstance().findNodeByRouter(pageRouter);
        if (node == null) {
            return;
        }
        node.setAction(DNodeActionType.DNodeActionTypePopTo);
        node.setParams(params);
        DNodeManager.getInstance().checkNode(node);
    }

    /**
     * 返回根页面
     */
    public void popToRoot() {
        DNode rootNode = DNodeManager.getInstance().createNode(""
                , "", "", DNodeActionType.DNodeActionTypePopToRoot
                , null, false, false, false);
        DNodeManager.getInstance().checkNode(rootNode);
    }

    /**
     * 返回根页面，带参数
     */
    public void popToRoot(Map<String, Object> params) {
        DNode rootNode = DNodeManager.getInstance().createNode(""
                , "", "", DNodeActionType.DNodeActionTypePopToRoot
                , params, false, false, false);
        DNodeManager.getInstance().checkNode(rootNode);
    }

    /**
     * 判断是否是纯FlutterApp
     */
    public boolean isFlutterApp() {
        return DStackActivityManager.getInstance().isFlutterApp();
    }

    /**
     * 添加过滤器
     * 某些功能性Activity，不需要做节点管理的，添加至过滤
     *
     * @param filterString 过滤字符串
     */
    public void addFilter(String filterString) {
        if (TextUtils.isEmpty(filterString)) {
            return;
        }
        FilterActivityManager.getInstance().addFilter(filterString);
    }

    /**
     * 移除已添加的过滤器
     *
     * @param filterString
     */
    public void removeFilter(String filterString) {
        if (TextUtils.isEmpty(filterString)) {
            return;
        }
        FilterActivityManager.getInstance().removeFilter(filterString);
    }

    /**
     * 在FlutterActivity的onBackPressed()方法内调用
     * 监听flutter控制器的返回键，处理多个flutter控制器，根节点无法返回的问题
     */
    public void listenBackPressed() {
//        DNode currentNode = DNodeManager.getInstance().getCurrentNode();
//        if (currentNode == null) {
//            return;
//        }
//        if (DStack.getInstance().isFlutterApp()) {
//            return;
//        }
//        if (currentNode.getPageType().equals(DNodePageType.DNodePageTypeFlutter)) {
//            if (currentNode.isHomePage()) {
//                if (hasBeenExecutedResetAttachEngine) {
//                    DStackActivityManager.getInstance().closeTopFlutterActivity();
//                    hasBeenExecutedResetAttachEngine = false;
//                }
//            }
//        }
    }

    /**
     * 设置是否重置过引擎
     */
    public void setHasBeenExecutedResetAttachEngine(boolean hasBeenExecutedResetAttachEngine) {
        this.hasBeenExecutedResetAttachEngine = hasBeenExecutedResetAttachEngine;
    }
}
