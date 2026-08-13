package app.capgo.capacitor.camera.preview;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import android.graphics.Color;
import android.view.View;
import org.junit.Test;

public class ToBackCompositorHelperTest {

    @Test
    public void neverModifiesWindowBackground() {
        assertFalse(ToBackCompositorHelper.shouldModifyWindowBackground());
    }

    @Test
    public void neverLocksSystemUiColors() {
        assertFalse(ToBackCompositorHelper.shouldLockSystemUiColors());
    }

    @Test
    public void transparentizesWebViewParentOnAllDevices() {
        assertTrue(ToBackCompositorHelper.shouldTransparentizeWebViewParent());
    }

    @Test
    public void webViewBackgroundIsFullyTransparent() {
        assertEquals(Color.TRANSPARENT, ToBackCompositorHelper.resolveWebViewBackgroundColor());
    }

    @Test
    public void preservesOriginalWebViewAlpha() {
        assertEquals(0.75f, ToBackCompositorHelper.resolveWebViewAlpha(0.75f), 0.0001f);
        assertEquals(1f, ToBackCompositorHelper.resolveWebViewAlpha(1f), 0.0001f);
    }

    @Test
    public void skipsHardwareLayerOnPreviewContainerWhenToBack() {
        assertFalse(ToBackCompositorHelper.shouldUseHardwareLayerOnPreviewContainer(true));
        assertTrue(ToBackCompositorHelper.shouldUseHardwareLayerOnPreviewContainer(false));
    }

    @Test
    public void usesHardwareLayerForWebViewTransparency() {
        assertEquals(View.LAYER_TYPE_HARDWARE, ToBackCompositorHelper.resolveWebViewLayerType());
    }
}
