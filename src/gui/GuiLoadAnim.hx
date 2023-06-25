package gui;

import src.ResourceLoader;

class GuiLoadAnim extends GuiAnim {
	public function new() {
		var img = ResourceLoader.getImage("data/ui/xbox/loadingAnimation.png").resource.toTile();
		var f1 = img.sub(0, 1, 63, 63);
		var f2 = img.sub(64, 1, 63, 63);
		var f3 = img.sub(0, 65, 63, 63);
		var f4 = img.sub(64, 65, 63, 63);
		var f5 = img.sub(0, 129, 63, 63);
		var f6 = img.sub(64, 129, 63, 63);
		var f7 = img.sub(0, 193, 63, 63);
		super([f1, f2, f3, f4, f5, f6, f7]);
		this.anim.loop = true;
		this.anim.speed = 20;
	}
}
