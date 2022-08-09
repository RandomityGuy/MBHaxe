package touch;

import touch.TouchInput.Touch;
import h3d.Vector;
import hxd.Window;
import src.ResourceLoader;
import src.Settings;

class PowerupButton extends TouchButton {
	public function new() {
		super(ResourceLoader.getImage("data/ui/touch/energy.png").resource, Settings.touchSettings.powerupButtonPos, Settings.touchSettings.powerupButtonSize);
		this.setEnabled(false);
	}
}
