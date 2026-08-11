package src;

import haxe.io.Bytes;
import haxe.io.Path;
import mis.MisParser;
import src.Mission;
import src.ResourceLoader;
import src.MarbleGame;
import src.Console;

class LocalLevelLoader {
	public static var currentLocalPath:String = null;
	public static var currentMission:Mission = null;

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
				js.Browser.window.opener.postMessage({ type: "mbhaxe-ready" }, "*");
			} catch (e:Dynamic) {}
		}
		try {
			var channel = new js.html.BroadcastChannel("mbhaxe-level-editor");
			channel.postMessage({ type: "mbhaxe-ready" });
		} catch (e:Dynamic) {}
		#end
	}

	static function setupWebPostMessage() {
		#if js
		function handleMessage(data:Dynamic) {
			if (data == null || data.type != "loadLevel" || data.files == null) return;
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

			MarbleGame.instance.playMission(mission);
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