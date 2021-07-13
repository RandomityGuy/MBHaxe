package;

import src.ResourceLoader;
import fs.ManifestFileSystem;
import hxd.Timer;
import hxd.Window;
import src.AudioManager;
import src.Settings;
import src.MarbleGame;
import gui.MainMenuGui;
import hxd.res.DefaultFont;
import h2d.Text;
import h3d.Vector;
import fs.ManifestBuilder;

class Main extends hxd.App {
	var marbleGame:MarbleGame;

	var fpsCounter:Text;

	var loaded:Bool = false;

	override function init() {
		super.init();

		#if hl
		hl.UI.closeConsole();
		#end
		ResourceLoader.init(s2d, () -> {
			Settings.init();
			AudioManager.init();
			AudioManager.playShell();
			marbleGame = new MarbleGame(s2d, s3d);
			MarbleGame.canvas.setContent(new MainMenuGui());
			// world = new MarbleWorld(s3d, s2d, mission);

			// world.init();
			// world.start();

			fpsCounter = new Text(DefaultFont.get(), s2d);
			fpsCounter.y = 40;
			fpsCounter.color = new Vector(1, 1, 1, 1);

			loaded = true;
		});
	}

	override function update(dt:Float) {
		super.update(dt);
		if (loaded) {
			marbleGame.update(dt);
			// world.update(dt);
			fpsCounter.text = 'FPS: ${this.engine.fps}';
		}
	}

	override function render(e:h3d.Engine) {
		// this.world.render(e);
		if (loaded)
			marbleGame.render(e);
		super.render(e);
	}

	static function main() {
		// h3d.mat.PbrMaterialSetup.set();
		new Main();
	}
}
