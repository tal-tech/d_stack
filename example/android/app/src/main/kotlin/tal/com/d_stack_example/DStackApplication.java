package tal.com.d_stack_example;

import android.content.Intent;

import io.flutter.app.FlutterApplication;
import tal.com.d_stack.DStack;
import tal.com.d_stack.utils.DLog;

public class DStackApplication extends FlutterApplication {

    DStackApplication application;

    @Override
    public void onCreate() {
        super.onCreate();
        application = this;
        DStack.getInstance().init(this, (routerUrl, params) -> {
            if (routerUrl.equals("NativePage")) {
                Intent intent = new Intent();
                intent.setClass(application, NativeThreeActivity.class);
                intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                application.startActivity(intent);
            }
        });
        DStack.getInstance().setOpenNodeOperation(false);
    }
}
