package tal.com.d_stack_example;

import android.os.Bundle;
import android.widget.Button;

import androidx.appcompat.app.AppCompatActivity;

import tal.com.d_stack.DStack;


public class NativeThreeActivity extends AppCompatActivity {

    Button btnOpenFlutter;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.layout_three);

        btnOpenFlutter = findViewById(R.id.btn_open_flutter);
        btnOpenFlutter.setOnClickListener(v -> {
            DStack.getInstance().pushFlutterPage("page4", null, FlutterContainerActivity.class);
        });
    }
}