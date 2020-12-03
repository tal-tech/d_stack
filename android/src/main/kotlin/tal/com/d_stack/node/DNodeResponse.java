package tal.com.d_stack.node;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;

public class DNodeResponse {
    public String target = "";
    public String pageType = "";
    public String action = "";
    public Map<String, Object> params;
    public boolean homePage = false;
    public boolean animated = false;
    public boolean boundary = false;

    @Override
    public String toString() {
        JSONObject jo = new JSONObject();
        try {
            jo.put("target", target);
            jo.put("pageType", pageType);
            jo.put("action", action);
            jo.put("params", params);
            jo.put("homePage", homePage);
            jo.put("animated", animated);
            jo.put("boundary", boundary);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return jo.toString();
    }

    public Map<String, Object> toMap() {
        Map<String, Object> map = new HashMap<>();
        map.put("target", target);
        map.put("pageType", pageType);
        map.put("action", action);
        map.put("params", params);
        map.put("homePage", homePage);
        map.put("animated", animated);
        map.put("boundary", boundary);
        return map;
    }
}
