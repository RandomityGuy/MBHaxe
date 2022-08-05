package touch;

import touch.TouchInput.Touch;
import h3d.Vector;
import hxd.Window;
import src.ResourceLoader;
import src.Settings;

class PowerupButton extends TouchButton {
	public function new() {
		super(ResourceLoader.getImage("data/ui/touch/energy.png").resource, new Vector(440, 180), 60);
		this.setEnabled(false);
	}
}
