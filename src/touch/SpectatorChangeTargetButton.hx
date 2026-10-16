package touch;

import src.MarbleGame;
import touch.TouchInput.Touch;
import h3d.Vector;
import hxd.Window;
import src.ResourceLoader;
import src.Settings;

class SpectatorChangeTargetButton extends TouchButton {
	public var didPressIt:Bool = true;

	public function new(rightFacing:Bool) {
		super(ResourceLoader.getImage(rightFacing ? "data/ui/touch/right.png" : "data/ui/touch/left.png").resource, new Vector(rightFacing ? 560 : 70, 120),
			60);
		if (!rightFacing) {
			this.guiElement.horizSizing = Right;
		}
		this.setEnabled(false);
		this.onClick = () -> {
			this.pressed = true;
			didPressIt = true;
		}
	}
}
