package touch;

import src.MarbleGame;
import touch.TouchInput.Touch;
import h3d.Vector;
import hxd.Window;
import src.ResourceLoader;
import src.Settings;

class BlastButton extends TouchButton {
	public var didPressIt:Bool = true;

	public function new() {
		var mode = MarbleGame.instance.world != null ? @:privateAccess MarbleGame.instance.world.marble.camera.spectate : false;
		super(ResourceLoader.getImage(mode ? "data/ui/touch/video-camera.png" : "data/ui/touch/explosion.png").resource,
			new Vector(Settings.touchSettings.blastButtonPos[0], Settings.touchSettings.blastButtonPos[1]), Settings.touchSettings.blastButtonSize);
		this.setEnabled(false);
		this.onClick = () -> {
			this.pressed = true;
			didPressIt = true;
		}
	}
}
