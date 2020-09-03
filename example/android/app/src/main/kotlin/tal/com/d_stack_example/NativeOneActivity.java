package tal.com.d_stack_example;

import android.content.Intent;
import android.os.Bundle;
import android.widget.Button;

import androidx.appcompat.app.AppCompatActivity;

import tal.com.d_stack.DStack;

/**
 * native页面
 */
public class NativeOneActivity extends AppCompatActivity {

    Button btnOpenNative;
    Button btnOpenFlutter;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.layout_one);
        btnOpenNative = findViewById(R.id.btn_open_native);
        btnOpenFlutter = findViewById(R.id.btn_open_flutter);

        btnOpenNative.setOnClickListener(v -> {
            Intent nativeIntent = new Intent(this, NativeTwoActivity.class);
            startActivity(nativeIntent);
        });

        btnOpenFlutter.setOnClickListener(v -> {
            DStack.getInstance().pushFlutterPage("page1", null, FlutterContainerActivity.class);
        });
    }
}