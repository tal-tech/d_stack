package tal.com.d_stack.node.constants;

// 跳转类型
public class DNodeActionType {

    // push跳转android
    public static final String DNodeActionTypePush = "push";

    // present跳转(ios独有)
    public static final String DNodeActionTypePresent = "present";

    // pop返回android
    public static final String DNodeActionTypePop = "pop";

    // popTo 返回
    public static final String DNodeActionTypePopTo = "popTo";

    // PopToRoot
    public static final String DNodeActionTypePopToRoot = "popToNativeRoot";

    // PopSkip
    public static final String DNodeActionTypePopSkip = "popSkip";

    // 手势
    public static final String DNodeActionTypeGesture = "gesture";

    // Dissmiss返回(ios独有)
    public static final String DNodeActionTypeDissmiss = "dissmiss";

    //replace
    public static final String DNodeActionTypeReplace = "replace";
}
