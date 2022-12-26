package;

import src.Console;
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
import src.ProfilerUI;

class Main extends hxd.App {
	var marbleGame:MarbleGame;

	var loaded:Bool = false;

	var frameByFrame:Bool = false;

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
		var zoomRatio = Window.getInstance().height / 600;
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

		new Console(); // Singleton
		Console.log("Initializing MBHaxe");
		#if hl
		Console.log("System: " + Sys.systemName());
		#end

		try {
			Settings.init();
			ResourceLoader.init(s2d, () -> {
				AudioManager.init();
				AudioManager.playShell();
				marbleGame = new MarbleGame(s2d, s3d);
				MarbleGame.canvas.setContent(new MainMenuGui());

				new ProfilerUI(s2d);

				loaded = true;
			});
		} catch (e) {
			Console.error(e.message);
			Console.error(e.stack.toString());
			throw e;
		}

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
			ProfilerUI.begin();
			ProfilerUI.measure("updateBegin");
			try {
				marbleGame.update(dt);
			} catch (e) {
				Console.error(e.message);
				Console.error(e.stack.toString());
				throw e;
			}
			// world.update(dt);
			ProfilerUI.update(this.engine.fps);
		}
	}

	override function render(e:h3d.Engine) {
		// this.world.render(e);
		if (loaded) {
			ProfilerUI.measure("renderBegin");
			marbleGame.render(e);
			ProfilerUI.end();
		}
		super.render(e);
	}

	static function main() {
		// h3d.mat.PbrMaterialSetup.set();
		new Main();
	}
}
