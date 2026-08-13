package app.capgo.capacitor.camera.preview;

import android.graphics.Color;
import android.view.View;

/**
 * Policy for Android {@code toBack} compositing.
 * <p>
 * Camera preview sits behind the Capacitor WebView. Only the WebView stack should be made
 * transparent — never the Activity window drawable or system bar colors. Touching those causes
 * status/navigation bar flicker (Pixel/Android 16) and fights edge-to-edge scrims.
 */
public final class ToBackCompositorHelper {

    private ToBackCompositorHelper() {}

    public static boolean shouldModifyWindowBackground() {
        return false;
    }

    public static boolean shouldLockSystemUiColors() {
        return false;
    }

    public static boolean shouldTransparentizeWebViewParent() {
        return true;
    }

    public static int resolveWebViewBackgroundColor() {
        return Color.TRANSPARENT;
    }

    public static float resolveWebViewAlpha(float originalAlpha) {
        return originalAlpha;
    }

    public static boolean shouldUseHardwareLayerOnPreviewContainer(boolean toBack) {
        return !toBack;
    }

    public static int resolveWebViewLayerType() {
        return View.LAYER_TYPE_HARDWARE;
    }
}
