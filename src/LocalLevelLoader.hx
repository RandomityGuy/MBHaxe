package src;

import h3d.Vector;
import haxe.io.Bytes;
import haxe.io.Path;
import mis.MisParser;
import src.Mission;
import src.ResourceLoader;
import src.MarbleGame;
import src.Console;
import src.DifBuilder;
import src.Settings;

class LocalLevelLoader {
	public static var currentLocalPath:String = null;
	public static var currentMission:Mission = null;
	static var keyboardRelayAttached = false;

	public static function init() {
		#if js
		setupWebPostMessage();
		notifyReady();
		#end
	}

	public static function notifyReady() {
		#if js
		if (js.Browser.window.opener != null) {
			try {
				Console.log("Notifying level editor that MBHaxe is ready...");
				js.Browser.window.opener.postMessage({type: "mbhaxe-ready"}, "*");
			} catch (e:Dynamic) {}
		}
		if (js.Browser.window.parent != null) {
			try {
				Console.log("Notifying level editor that MBHaxe is ready...");
				js.Browser.window.parent.postMessage({type: "mbhaxe-ready"}, "*");
			} catch (e:Dynamic) {}
		}
		try {
			var channel = new js.html.BroadcastChannel("mbhaxe-level-editor");
			channel.postMessage({type: "mbhaxe-ready"});
		} catch (e:Dynamic) {}
		#end
	}

	public static function notifyExitLevel() {
		#if js
		if (js.Browser.window.opener != null) {
			try {
				Console.log("Notifying level editor that we exit the level...");
				js.Browser.window.opener.postMessage({type: "mbhaxe-exit"}, "*");
			} catch (e:Dynamic) {}
		}
		if (js.Browser.window.parent != null) {
			try {
				Console.log("Notifying level editor that we exit the level...");
				js.Browser.window.parent.postMessage({type: "mbhaxe-exit"}, "*");
			} catch (e:Dynamic) {}
		}
		try {
			var channel = new js.html.BroadcastChannel("mbhaxe-level-editor");
			channel.postMessage({type: "mbhaxe-exit"});
		} catch (e:Dynamic) {}
		#end
	}

	static function attachKeyboardRelay() {
		#if js
		if (keyboardRelayAttached)
			return;
		keyboardRelayAttached = true;

		js.Browser.window.addEventListener("keydown", (e:js.html.KeyboardEvent) -> relayKeyboardEvent("mbhaxe-keydown", e));
		js.Browser.window.addEventListener("keyup", (e:js.html.KeyboardEvent) -> relayKeyboardEvent("mbhaxe-keyup", e));
		#end
	}

	static function relayKeyboardEvent(type:String, e:js.html.KeyboardEvent) {
		#if js
		var parent = js.Browser.window.parent;
		if (parent == null || parent == js.Browser.window)
			return;

		parent.postMessage({
			type: type,
			code: e.code,
			key: e.key,
			altKey: e.altKey,
			ctrlKey: e.ctrlKey,
			metaKey: e.metaKey,
			shiftKey: e.shiftKey,
			repeat: e.repeat
		}, "*");
		#end
	}

	static function setupWebPostMessage() {
		#if js
		function handleMessage(data:Dynamic) {
			if (data == null)
				return;

			switch (data.type) {
				case "loadLevel":
					{
						if (data.files == null)
							return;
						Console.log("Received level load message via postMessage/BroadcastChannel");

						var mission:Mission = null;

						var filesAccess:haxe.DynamicAccess<Dynamic> = data.files;
						for (k in filesAccess.keys()) {
							var fileData:Dynamic = filesAccess.get(k);
							var bytes:Bytes = null;
							if (Std.isOfType(fileData, String)) {
								bytes = Bytes.ofString(fileData);
							} else {
								bytes = Bytes.ofData(fileData);
							}
							ResourceLoader.registerLocalFile(k, bytes);

							if (StringTools.endsWith(k.toLowerCase(), ".mis")) {
								mission = createLocalMission(k, bytes.toString());
							}
						}

						if (mission == null) {
							Console.error("postMessage loadLevel missing .mis file in files payload");
							return;
						}

						DifBuilder.clearDifCache();

						Settings.optionsSettings.rewindEnabled = true; // enable rewind while testing!
						MarbleGame.instance.playMission(mission);
						attachKeyboardRelay();
					}
				case "teleport":
					{
						if (MarbleGame.instance.world != null && MarbleGame.instance.world.mission.isLocal) {
							// we can teleport our marble
							var destPos = new Vector(data.position.x, data.position.y, data.position.z);
							if (MarbleGame.instance.world.marble != null) {
								MarbleGame.instance.world.marble.setMarblePosition(-destPos.x, destPos.y, destPos.z);
								MarbleGame.instance.world.marble.velocity.set(0, 0, 0);
								MarbleGame.instance.world.marble.omega.set(0, 0, 0);

								// If level is paused, unpause it since we are gonna tab back to it
								if (MarbleGame.instance.paused)
									MarbleGame.instance.handlePauseGame();
							}
						}
					}
			}
		}

		js.Browser.window.addEventListener("message", (e:js.html.MessageEvent) -> {
			handleMessage(e.data);
		});

		try {
			var channel = new js.html.BroadcastChannel("mbhaxe-level-editor");
			channel.onmessage = (e:js.html.MessageEvent) -> {
				handleMessage(e.data);
			};
		} catch (e:Dynamic) {}
		#end
	}

	public static function createLocalMission(misRelPath:String, misText:String):Mission {
		var misParser = new MisParser(misText);
		var parsed = misParser.parse();
		var mInfo = misParser.parseMissionInfo();

		var mission = Mission.fromMissionInfo(misRelPath, mInfo);
		mission.isCustom = true;
		mission.isLocal = true;
		mission.game = mInfo.game?.toLowerCase();

		currentMission = mission;
		return mission;
	}
}
