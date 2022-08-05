package touch;

import touch.TouchInput.Touch;
import h3d.Vector;
import hxd.Window;
import src.ResourceLoader;
import src.Settings;

class JumpButton extends TouchButton {
	public function new() {
		super(ResourceLoader.getImage("data/ui/touch/up-arrow.png").resource, new Vector(440, 320), 60);
	}
}
