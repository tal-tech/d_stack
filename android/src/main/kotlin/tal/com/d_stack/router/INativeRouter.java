package tal.com.d_stack.router;

import java.util.Map;

/**
 * 路由信息接口
 */
public interface INativeRouter {

    void openContainer(String routerUrl, Map<String, Object> params);

}
