package touch;

import touch.TouchInput.Touch;
import h3d.Vector;
import hxd.Window;
import src.ResourceLoader;
import src.Settings;

class BlastButton extends TouchButton {
	public function new() {
		super(ResourceLoader.getImage("data/ui/touch/explosion.png").resource,
			new Vector(Settings.touchSettings.blastButtonPos[0], Settings.touchSettings.blastButtonPos[1]), Settings.touchSettings.blastButtonSize);
		this.setEnabled(false);
	}
}
