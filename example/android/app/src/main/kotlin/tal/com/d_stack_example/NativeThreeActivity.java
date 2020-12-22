package tal.com.d_stack_example;

import android.os.Bundle;
import android.view.View;
import android.widget.Button;

import androidx.appcompat.app.AppCompatActivity;

import tal.com.d_stack.DStack;


public class NativeThreeActivity extends AppCompatActivity {

    Button btnOpenFlutter;
    Button btnPopToRoot;
    Button btnPopToFlutter;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.layout_three);

        btnOpenFlutter = findViewById(R.id.btn_open_flutter);
        btnPopToRoot = findViewById(R.id.btn_popToRoot);
        btnPopToFlutter = findViewById(R.id.btn_popFlutter);

        btnOpenFlutter.setOnClickListener(v -> {
            DStack.getInstance().pushFlutterPage("page4", null, FlutterContainerActivity.class);
        });

        btnPopToRoot.setOnClickListener(v -> DStack.getInstance().popToRoot());

        btnPopToFlutter.setOnClickListener(v -> {
            DStack.getInstance().popTo("page2", null);
        });
    }
}