package tal.com.d_stack_example

import android.content.Context
import io.flutter.embedding.android.DFlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import tal.com.d_stack.DStack


/**
 * flutter的容器activity，需要重写provideFlutterEngine方法
 * 进行引擎复用
 */
class FlutterContainerActivity : DFlutterActivity() {

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return FlutterEngineCache.getInstance().get(DStack.ENGINE_ID)
    }
}
