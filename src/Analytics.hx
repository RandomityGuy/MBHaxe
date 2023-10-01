package src;

import haxe.Json;
import src.Util;
import src.Settings;
import src.Http;
import src.Console;

typedef PayloadData = {
	type:String,
	payload:{
		hostname:String, language:String, referrer:String, screen:String, title:String, url:String, website:String, name:String, ?data:Dynamic
	}
};

// I'm sorry to add this
// Your data is private and anonymous and we don't track you at all, I promise!
// The analytics are stored in a self hosted Umami instance inside EU.
class Analytics {
	static var umami = "https://analytics.randomityguy.me/api/send";

	public static function trackSingle(eventName:String) {
		var p = payload(eventName, null);
		var json = Json.stringify(p);
		Http.post(umami, json, (b) -> {
			// Console.log("Analytics suceeded: " + b.toString());
		}, (e) -> {
			// Console.log("Analytics failed: " + e);
		});
	}

	public static function trackLevelPlay(levelName:String, levelFile:String) {
		var p = payload("level-play", {
			name: levelName,
			file: levelFile
		});
		var json = Json.stringify(p);
		Http.post(umami, json, (b) -> {
			// Console.log("Analytics suceeded: " + b.toString());
		}, (e) -> {
			// Console.log("Analytics failed: " + e);
		});
	}

	public static function trackLevelScore(levelName:String, levelFile:String, time:Int, oobs:Int, respawns:Int, rewind:Bool) {
		var p = payload("level-score", {
			name: levelName,
			file: levelFile,
			time: time,
			oobs: oobs,
			respawns: respawns,
			rewind: rewind
		});
		var json = Json.stringify(p);
		Http.post(umami, json, (b) -> {
			// Console.log("Analytics suceeded: " + b.toString());
		}, (e) -> {
			// Console.log("Analytics failed: " + e);
		});
	}

	public static function trackLevelQuit(levelName:String, levelFile:String, time:Int, oobs:Int, respawns:Int, rewind:Bool) {
		var p = payload("level-quit", {
			name: levelName,
			file: levelFile,
			time: time,
			oobs: oobs,
			respawns: respawns,
			rewind: rewind
		});
		var json = Json.stringify(p);
		Http.post(umami, json, (b) -> {
			// Console.log("Analytics suceeded: " + b.toString());
		}, (e) -> {
			// Console.log("Analytics failed: " + e);
		});
	}

	public static function trackPlatformInfo() {
		var p = payload("device-telemetry", {
			platform: Util.getPlatform(),
			screen: screen(),
		});
		var json = Json.stringify(p);
		Http.post(umami, json, (b) -> {
			// Console.log("Analytics suceeded: " + b.toString());
		}, (e) -> {
			// Console.log("Analytics failed: " + e);
		});
	}

	static function payload(eventName:String, eventData:Dynamic):PayloadData {
		var p:PayloadData = {
			type: "event",
			payload: {
				hostname: hostname(),
				language: language(),
				referrer: referrer(),
				screen: screen(),
				title: "MBHaxe Platinum",
				url: "/",
				website: "e6da43f0-fc6a-49cb-a4a9-4b7e7745e538",
				name: eventName
			}
		};
		if (eventData == null)
			return p;
		p.payload.data = eventData;
		return p;
	}

	static function hostname() {
		#if js
		return js.Browser.window.location.hostname;
		#end
		#if hl
		return "marbleblast.randomityguy.me";
		#end
	}

	static function language() {
		#if js
		return js.Browser.window.navigator.language;
		#end
		#if hl
		return "en-us";
		#end
	}

	static function referrer() {
		#if js
		return js.Browser.window.document.referrer;
		#end
		#if hl
		return "";
		#end
	}

	static function screen() {
		#if js
		return '${js.Browser.window.screen.width}x${js.Browser.window.screen.height}';
		#end
		#if hl
		return '${Settings.optionsSettings.screenWidth}x${Settings.optionsSettings.screenHeight}';
		#end
	}
}
