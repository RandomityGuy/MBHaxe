package;

import datachannel.RTC;
import gui.VersionGui;
import gui.PresentsGui;
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
import src.Renderer;
import src.MissionList;

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
			zoomRatio = 1.5;
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
		var zoomRatio = Math.min(Window.getInstance().height, Window.getInstance().width) / 600;
		s2d.scaleMode = Zoom(zoomRatio);

		trace("Initial Window resized to "
			+ Window.getInstance().width
			+ "x"
			+ Window.getInstance().height
			+ " (Zoom "
			+ zoomRatio
			+ ")");
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

		// try {
		RTC.init();
		Http.init();
		haxe.MainLoop.add(() -> Http.loop());
		Settings.init();
		Gamepad.init();
		MPCustoms.loadMissionList();
		ResourceLoader.init(s2d, () -> {
			AudioManager.init();
			AudioManager.playShell();
			// Marbleland.init();
			marbleGame = new MarbleGame(s2d, s3d);
			MarbleGame.canvas.setContent(new PresentsGui());
			MissionList.buildMissionList(); // Yeah pls
			marbleGame.startPreviewWorld(() -> {
				marbleGame.setPreviewMission('urban', () -> {
					MarbleGame.canvas.setContent(new MainMenuGui());
					VersionGui.checkVersion();
				});
			});

			new ProfilerUI(s2d);

			loaded = true;
		});
		// } catch (e) {
		// 	Console.error(e.message);
		// 	Console.error(e.stack.toString());
		// 	throw e;
		// }

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
		ProfilerUI.begin(1);
		ProfilerUI.measure("updateBegin", 1);
		if (loaded) {
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
			ProfilerUI.update(this.engine.fps);
		}
		ProfilerUI.end(1);
	}

	override function render(e:h3d.Engine) {
		// this.world.render(e);
		ProfilerUI.begin(0);
		if (loaded) {
			ProfilerUI.measure("renderBegin", 0);
			marbleGame.render(e);
		}
		super.render(e);
		ProfilerUI.end(0);
		#if hl
		e.driver.present();
		#end
	}

	static function main() {
		// h3d.mat.PbrMaterialSetup.set();
		new Main();
	}
}
