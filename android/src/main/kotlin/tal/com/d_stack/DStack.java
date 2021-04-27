package tal.com.d_stack;

import android.app.Application;
import android.content.Context;
import android.content.Intent;
import android.text.TextUtils;

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
import tal.com.d_stack.router.INodeOperation;
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

    private INodeOperation nodeOperation;

    private boolean openNodeOperation;

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
        DNode node = new DNode.Builder()
                .target(pageRouter)
                .params(params)
                .pageType(DNodePageType.DNodePageTypeFlutter)
                .action(DNodeActionType.DNodeActionTypePush)
                .boundary(true)
                .build();

        if (!DStack.getInstance().isFlutterApp()) {
            //原生工程
            if (!DStackActivityManager.getInstance().haveFlutterContainer()) {
                //第一次打开flutter页面，设置flutter页面的homepage为true
                node.setHomePage(true);
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
        if (currentNode.getPageType().equals(DNodePageType.DNodePageTypeFlutter)) {
            DNode node = new DNode.Builder().target(currentNode.getTarget())
                    .pageType(DNodePageType.DNodePageTypeFlutter)
                    .action(DNodeActionType.DNodeActionTypePop)
                    .isHomePage(currentNode.isHomePage()).build();
            DNodeManager.getInstance().checkNode(node);
        }
    }

    /**
     * native侧关闭当前页面，暂时只处理关闭flutter页面，带参数
     */
    public void pop(Map<String, Object> params) {
        DNode currentNode = DNodeManager.getInstance().getCurrentNode();
        if (currentNode.getPageType().equals(DNodePageType.DNodePageTypeFlutter)) {
            DNode node = new DNode.Builder().target(currentNode.getTarget())
                    .pageType(DNodePageType.DNodePageTypeFlutter)
                    .action(DNodeActionType.DNodeActionTypePop)
                    .params(params)
                    .isHomePage(currentNode.isHomePage()).build();
            DNodeManager.getInstance().checkNode(node);
        }
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
        DNode node = new DNode.Builder()
                .target("/")
                .action(DNodeActionType.DNodeActionTypePopToRoot)
                .build();
        DNodeManager.getInstance().checkNode(node);
    }

    /**
     * 返回根页面，带参数
     */
    public void popToRoot(Map<String, Object> params) {
        DNode node = new DNode.Builder()
                .target("/")
                .action(DNodeActionType.DNodeActionTypePopToRoot)
                .params(params)
                .build();
        DNodeManager.getInstance().checkNode(node);
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
     */
    public void addFilter(String filterString) {
        if (TextUtils.isEmpty(filterString)) {
            return;
        }
        FilterActivityManager.getInstance().addFilter(filterString);
    }

    /**
     * 移除已添加的过滤器
     */
    public void removeFilter(String filterString) {
        if (TextUtils.isEmpty(filterString)) {
            return;
        }
        FilterActivityManager.getInstance().removeFilter(filterString);
    }

    /**
     * 设置节点操作监听
     */
    public void setNodeOperation(INodeOperation nodeOperation) {
        this.nodeOperation = nodeOperation;
    }

    /**
     * 获取节点操作监听
     */
    public INodeOperation getNodeOperation() {
        return nodeOperation;
    }

    /**
     * 节点操作是否开启
     */
    public boolean isOpenNodeOperation() {
        return openNodeOperation;
    }

    /**
     * 设置是否开启节点操作
     */
    public void setOpenNodeOperation(boolean openNodeOperation) {
        this.openNodeOperation = openNodeOperation;
    }
}
