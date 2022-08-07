package touch;

import src.MarbleGame;
import h3d.Vector;
import src.ResourceLoader;

class PauseButton extends TouchButton {
	public function new() {
		var offset = MarbleGame.instance.world != null ? (MarbleGame.instance.world.totalGems > 0 ? 30 : 0) : 0;
		super(ResourceLoader.getImage("data/ui/touch/pause-button.png").resource, new Vector(55, 55 + offset), 35);
		this.guiElement.horizSizing = Right;
		this.guiElement.vertSizing = Bottom;

		this.onClick = () -> {
			if (MarbleGame.instance.world != null) {
				@:privateAccess MarbleGame.instance.paused = true;
				MarbleGame.instance.handlePauseGame();
			}
		}
	}
}
