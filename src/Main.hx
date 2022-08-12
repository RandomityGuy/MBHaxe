package;

import hxd.Key;
import src.Util;
import src.ResourceLoader;
#if js
import fs.ManifestFileSystem;
import fs.ManifestBuilder;
#end
import hxd.Timer;
import hxd.Window;
import src.AudioManager;
import src.Settings;
import src.MarbleGame;
import gui.MainMenuGui;
import hxd.res.DefaultFont;
import h2d.Text;
import h3d.Vector;

class Main extends hxd.App {
	var marbleGame:MarbleGame;

	// var fpsCounter:Text;
	var debugProfiler:h3d.impl.Benchmark;
	var loaded:Bool = false;

	var keyCounter:Text;

	override function init() {
		super.init();

		#if (hl && !android)
		hl.UI.closeConsole();
		#end
		#if js
		var zoomRatio = Util.isTouchDevice() ? js.Browser.window.screen.height * js.Browser.window.devicePixelRatio / 600 : js.Browser.window.devicePixelRatio; // js.Browser.window.devicePixelRatio;
		s2d.scaleMode = Zoom(zoomRatio);
		#end

		#if android
		Window.getInstance().addEventTarget(ev -> {
			if (ev.kind == EPush || ev.kind == ERelease || ev.kind == EMove) {
				@:privateAccess s2d.window.curMouseX = cast ev.relX;
				@:privateAccess s2d.window.curMouseY = cast ev.relY;
				ev.propagate = true;
			}

			if (ev.kind == EPush) {
				@:privateAccess Key.keyPressed[Key.MOUSE_LEFT] = Key.getFrame();
			}

			if (ev.kind == ERelease) {
				@:privateAccess Key.keyPressed[Key.MOUSE_LEFT] = -Key.getFrame();
			}
		});
		#end

		ResourceLoader.init(s2d, () -> {
			Settings.init();
			AudioManager.init();
			AudioManager.playShell();
			marbleGame = new MarbleGame(s2d, s3d);
			MarbleGame.canvas.setContent(new MainMenuGui());

			keyCounter = new Text(DefaultFont.get(), s2d);
			keyCounter.color = new Vector(1, 1, 1, 1);

			loaded = true;
		});

		// ResourceLoader.init(s2d, () -> {
		// 	Settings.init();
		// 	AudioManager.init();
		// 	AudioManager.playShell();
		// 	marbleGame = new MarbleGame(s2d, s3d);
		// 	MarbleGame.canvas.setContent(new MainMenuGui());
		// 	// world = new MarbleWorld(s3d, s2d, mission);

		// 	// world.init();
		// 	// world.start();
		// 	// debugProfiler = new h3d.impl.Benchmark(s2d);
		// 	// debugProfiler.y = 40;

		// 	// fpsCounter = new Text(DefaultFont.get(), s2d);
		// 	// fpsCounter.y = 40;
		// 	// fpsCounter.color = new Vector(1, 1, 1, 1);

		// 	loaded = true;
		// });
	}

	override function update(dt:Float) {
		super.update(dt);
		if (loaded) {
			marbleGame.update(dt);
			keyCounter.text = 'Mouse: ${Window.getInstance().mouseX} ${Window.getInstance().mouseY}';
			// world.update(dt);
			// fpsCounter.text = 'FPS: ${this.engine.fps}';
		}
	}

	override function render(e:h3d.Engine) {
		// this.world.render(e);
		if (loaded) {
			// debugProfiler.begin();
			// debugProfiler.measure("marbleGame");
			marbleGame.render(e);
			// debugProfiler.end();
		}
		super.render(e);
	}

	static function main() {
		// h3d.mat.PbrMaterialSetup.set();
		new Main();
	}
}
