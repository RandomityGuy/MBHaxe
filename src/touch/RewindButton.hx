package touch;

import touch.TouchInput.Touch;
import h3d.Vector;
import hxd.Window;
import src.ResourceLoader;
import src.Settings;

class RewindButton extends TouchButton {
	public function new() {
		super(ResourceLoader.getImage("data/ui/touch/rewind.png").resource,
			new Vector(Settings.touchSettings.rewindButtonPos[0], Settings.touchSettings.rewindButtonPos[1]), Settings.touchSettings.rewindButtonSize);
	}
}
