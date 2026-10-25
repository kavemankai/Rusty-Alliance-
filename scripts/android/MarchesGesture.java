import android.os.SystemClock;
import android.view.InputDevice;
import android.view.InputEvent;
import android.view.MotionEvent;
import java.lang.reflect.Method;

/** OS input injector for the dedicated emulator QA harness; not part of the game APK. */
public final class MarchesGesture {
    private static Object manager;
    private static Method inject;
    private static long began;
    private static void send(int action, int count, float left, float right, float y) throws Exception {
        MotionEvent.PointerProperties[] properties = new MotionEvent.PointerProperties[count];
        MotionEvent.PointerCoords[] coords = new MotionEvent.PointerCoords[count];
        for (int i=0; i<count; i++) {
            properties[i]=new MotionEvent.PointerProperties();
            properties[i].id=i; properties[i].toolType=MotionEvent.TOOL_TYPE_FINGER;
            coords[i]=new MotionEvent.PointerCoords();
            coords[i].x=i==0?left:right; coords[i].y=y;
            coords[i].pressure=1; coords[i].size=0.1f;
        }
        MotionEvent event=MotionEvent.obtain(began,SystemClock.uptimeMillis(),action,count,properties,coords,0,0,1,1,0,0,InputDevice.SOURCE_TOUCHSCREEN,0);
        if (!Boolean.TRUE.equals(inject.invoke(manager,event,2))) throw new IllegalStateException("OS rejected gesture injection");
        event.recycle();
    }
    public static void main(String[] args) throws Exception {
        Class<?> cls;
        try { cls=Class.forName("android.hardware.input.InputManagerGlobal"); }
        catch (ClassNotFoundException error) { cls=Class.forName("android.hardware.input.InputManager"); }
        manager=cls.getMethod("getInstance").invoke(null);
        inject=cls.getMethod("injectInputEvent",InputEvent.class,int.class);
        float x=Float.parseFloat(args[0]), y=Float.parseFloat(args[1]);
        boolean pan=args.length>2 && args[2].equals("pan");
        began=SystemClock.uptimeMillis();
        send(MotionEvent.ACTION_DOWN,1,x-70,x+70,y);
        send(MotionEvent.ACTION_POINTER_DOWN|(1<<MotionEvent.ACTION_POINTER_INDEX_SHIFT),2,x-70,x+70,y);
        for (int step=1;step<=16;step++) {
            SystemClock.sleep(30);
            send(MotionEvent.ACTION_MOVE,2,x-70+(pan?step*4:-step*4),x+70+step*4,y);
        }
        send(MotionEvent.ACTION_POINTER_UP|(1<<MotionEvent.ACTION_POINTER_INDEX_SHIFT),2,x-70+(pan?64:-64),x+134,y);
        send(MotionEvent.ACTION_UP,1,x-70+(pan?64:-64),x+134,y);
        System.out.println("ANDROID TWO-POINTER INPUT COMPLETE");
    }
}
