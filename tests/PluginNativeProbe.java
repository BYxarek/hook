import de.robv.android.xposed.XposedBridge;
import de.robv.android.xposed.XC_MethodHook;
import java.lang.reflect.Method;
import java.util.HashMap;

/** Run with app_process to check ART hooks without building an APK. */
public final class PluginNativeProbe {
    public static int target(int value) { return value * 2; }
    public static void main(String[] args) throws Exception {
        System.out.println("STAGE: before backend");
        Method method = PluginNativeProbe.class.getDeclaredMethod("target", int.class);
        int cycles = args.length == 0 ? 100 : Integer.parseInt(args[0]);
        if (cycles == 0) Class.forName("de.robv.android.xposed.XposedBridge");
        for (int cycle = 0; cycle < cycles; cycle++) {
            System.out.println("STAGE: hook " + cycle);
            XC_MethodHook.Unhook handle = XposedBridge.hookMethod(method, new XC_MethodHook() {
                @Override protected void beforeHookedMethod(MethodHookParam param) { param.args[0] = (Integer) param.args[0] + 1; }
                @Override protected void afterHookedMethod(MethodHookParam param) { param.setResult((Integer) param.getResult() + 1); }
            });
            if (!method.invoke(null, 2).equals(7)) throw new AssertionError("Hook failed");
            System.out.println("STAGE: unhook " + cycle);
            handle.unhook();
            if (!method.invoke(null, 2).equals(4)) throw new AssertionError("Unhook failed");
            HashMap<Integer, String> values = new HashMap<>();
            for (int i = 0; i < 10000; i++) values.put(i, "value" + i);
            if (!values.get(9999).equals("value9999")) throw new AssertionError("Map corruption");
        }
        System.out.println("STAGE: GC after " + cycles + " cycles");
        for (int i = 0; i < 5; i++) {
            System.gc();
            System.runFinalization();
            Thread.sleep(100);
            if (!method.invoke(null, 2).equals(4)) throw new AssertionError("Original failed after GC");
        }
        System.out.println("PASS: standalone Java native hook/unhook and HashMap stress, " + cycles + " cycles");
    }
}
