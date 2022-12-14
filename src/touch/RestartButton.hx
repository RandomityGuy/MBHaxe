package touch;

import src.MarbleGame;
import h3d.Vector;
import src.ResourceLoader;

class RestartButton extends TouchButton {
	public function new() {
		var offset = MarbleGame.instance.world != null ? (MarbleGame.instance.world.totalGems > 0 ? 30 : 0) : 0;
		super(ResourceLoader.getImage("data/ui/touch/refresh.png").resource, new Vector(135, 55 + offset), 35);
		this.guiElement.horizSizing = Right;
		this.guiElement.vertSizing = Bottom;
	}
}
