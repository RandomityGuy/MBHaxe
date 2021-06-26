package;

import src.Settings;
import src.MarbleGame;
import gui.MainMenuGui;
import hxd.res.DefaultFont;
import h2d.Text;
import h3d.Vector;

class Main extends hxd.App {
	var marbleGame:MarbleGame;

	var fpsCounter:Text;

	override function init() {
		super.init();

		Settings.load();
		marbleGame = new MarbleGame(s2d, s3d);
		MarbleGame.canvas.setContent(new MainMenuGui());
		// world = new MarbleWorld(s3d, s2d, mission);

		// world.init();
		// world.start();

		fpsCounter = new Text(DefaultFont.get(), s2d);
		fpsCounter.y = 40;
		fpsCounter.color = new Vector(1, 1, 1, 1);
	}

	override function update(dt:Float) {
		super.update(dt);
		marbleGame.update(dt);
		// world.update(dt);
		fpsCounter.text = 'FPS: ${this.engine.fps}';
	}

	override function render(e:h3d.Engine) {
		// this.world.render(e);
		marbleGame.render(e);
		super.render(e);
	}

	static function main() {
		// h3d.mat.PbrMaterialSetup.set();
		new Main();
	}
}
