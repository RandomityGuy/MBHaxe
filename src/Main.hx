package;

import gui.VersionGui;
import src.Debug;
import src.Marbleland;
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
import src.Gamepad;
import src.Http;
import datachannel.RTC;
import src.Renderer;

class Main extends hxd.App {
	var marbleGame:MarbleGame;

	var loaded:Bool = false;

	var frameByFrame:Bool = false;

	// var timeAccumulator:Float = 0.0;

	override function init() {
		super.init();

		s3d.renderer = new Renderer();
		#if debug
		s3d.checkPasses = false;
		#end

		#if (hl && !android)
		hl.UI.closeConsole();
		#end
		#if js
		var zoomRatio = (Util.isTouchDevice() && !Util.isTablet()) ? js.Browser.window.screen.height * js.Browser.window.devicePixelRatio / 768 : js.Browser.window.devicePixelRatio; // js.Browser.window.devicePixelRatio;
		if (Util.isIPhone())
			zoomRatio = 2;
		if (Util.isIPhone() && js.Browser.window.devicePixelRatio == 2)
			zoomRatio = 1.0;
		s2d.scaleMode = Zoom(zoomRatio);
		Settings.zoomRatio = zoomRatio;
		Settings.optionsSettings.screenWidth = cast Math.max(js.Browser.window.screen.width,
			js.Browser.window.screen.height); // 1024; // cast(js.Browser.window.innerWidth / js.Browser.window.innerHeight) * 768; // cast js.Browser.window.innerWidth * js.Browser.window.devicePixelRatio * 0.5;
		Settings.optionsSettings.screenHeight = cast Math.min(js.Browser.window.screen.width,
			js.Browser.window.screen.height); // 768; // cast js.Browser.window.innerHeight * js.Browser.window.devicePixelRatio * 0.5;
		var canvasElement = js.Browser.document.getElementById("webgl");
		canvasElement.style.width = "100%";
		canvasElement.style.height = "100%";
		s3d.camera.setFovX(Settings.optionsSettings.fovX, Settings.optionsSettings.screenWidth / Settings.optionsSettings.screenHeight);
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
			RTC.init();
			Http.init();
			haxe.MainLoop.add(() -> Http.loop());
			Settings.init();
			Gamepad.init();
			ResourceLoader.init(s2d, () -> {
				AudioManager.init();
				AudioManager.playShell();
				Marbleland.init();
				marbleGame = new MarbleGame(s2d, s3d);
				MarbleGame.canvas.setContent(new MainMenuGui());
				VersionGui.checkVersion();

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

	static var updateDT:Float;

	override function update(dt:Float) {
		updateDT = dt;
		super.update(dt);
		if (loaded) {
			ProfilerUI.begin();
			ProfilerUI.measure("updateBegin");

			// try {
			// timeAccumulator += dt;
			// while (timeAccumulator > 1 / 60) {
			// 	marbleGame.update(1 / 60);
			// 	timeAccumulator -= 1 / 60;
			// }
			RTC.processEvents();
			marbleGame.update(dt);
			// } catch (e) {
			// Console.error(e.message);
			// Console.error(e.stack.toString());
			// 	throw e;
			// }
			// world.update(dt);
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

		#if hl
		static var dtAccumulator;
		dtAccumulator += updateDT;
		if (Settings.optionsSettings.fpsLimit <= 0) {
			e.driver.present();
		} else {
			if (dtAccumulator >= 1.0 / Settings.optionsSettings.fpsLimit) {
				e.driver.present();
				dtAccumulator = 0.0;
			}
		}
		#end
	}

	static function main() {
		// h3d.mat.PbrMaterialSetup.set();
		new Main();
	}
}
