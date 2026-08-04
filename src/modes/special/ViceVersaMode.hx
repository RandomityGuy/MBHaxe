package modes.special;

import haxe.Json;
import src.MarbleWorld;
import src.TimeState;
import src.Marble;
import src.Settings;
import modes.GameMode.ScoreType;
import shapes.FadePlatform;
import shapes.TimeTravel;
import shapes.MegaManPlatform;
import shapes.PowerUp;
import src.PathedInterior;
#if hl
import sys.io.File;
import sys.FileSystem;
#end

typedef VVBoolState = {
	var name:String;
	var hidden:Bool;
}

typedef VVPathedInteriorState = {
	var name:String;
	var currentTime:Float;
	var targetTime:Float;
}

typedef VVStateData = {
	var fadingPlatforms:Array<VVBoolState>;
	var timeTravels:Array<VVBoolState>;
	var pathedInteriors:Array<VVPathedInteriorState>;
	var elapsedTime:Float;
	var heldPowerup:String;
}

class ViceVersaState {
	#if hl
	static var filePath = haxe.io.Path.join([Settings.settingsDir, "vicedata.json"]);
	#end
	#if js
	static inline var STORAGE_KEY = "MBHaxeViceVersaState";
	#end

	static final FADING_PLATFORMS = ("IslandOneRight01 IslandOneRight02 IslandOneRight03 IslandOneRight04 IslandOneRight05 IslandOneRight06 "
		+ "IslandOneRight07 IslandOneRight08 IslandOneRight09 IslandOneRight10 IslandOneRight11 IslandOneRight12 IslandOneRight13 IslandOneRight14 "
		+ "IslandOneRight15 IslandOneRight16 IslandOneRight17 IslandOneRight18 IslandOneRight19 IslandOneRight20 IslandOneRight21 IslandOneRight22 "
		+ "IslandOneRight23 IslandOneRight24 IslandOneRight25 IslandOneRight26 IslandOneRight27 IslandThreeLeft01 IslandThreeLeft02 IslandThreeLeft03 "
		+ "IslandThreeLeft04 IslandThreeLeft05 IslandThreeLeft06 IslandThreeLeft07 IslandThreeLeft08 IslandThreeLeft09 IslandThreeLeft10 "
		+ "IslandThreeLeft11 IslandThreeLeft12 IslandThreeLeft13 IslandThreeLeft14 IslandThreeLeft15 IslandThreeLeft16 IslandThreeLeft17 "
		+ "IslandThreeLeft18 IslandThreeLeft19 IslandThreeLeft20 IslandThreeLeft21 IslandThreeLeft22 IslandThreeLeft23 IslandThreeLeft24 "
		+ "IslandThreeUpsideDown01 IslandThreeUpsideDown02 IslandThreeUpsideDown03 IslandThreeUpsideDown04 IslandThreeUpsideDown05 "
		+ "IslandThreeUpsideDown06 IslandThreeUpsideDown07 IslandThreeUpsideDown08 IslandThreeUpsideDown09 IslandThreeUpsideDown10 "
		+ "IslandThreeUpsideDown11 IslandThreeUpsideDown12").split(" ");

	static final TIME_TRAVELS = ("TimeTravelRestStop TimeTravel01 TimeTravel02 TimeTravel03 TimeTravel04 TimeTravel05 TimeTravel06 TimeTravel07 "
		+ "TimeTravel08 TimeTravel09 TimeTravel10 TimeTravel11 TimeTravel12 TimeTravel13 TimeTravel14 TimeTravel15 TimeTravel16 TimeTravel17 "
		+ "TimeTravel18 TimeTravel19 TimeTravel20 TimeTravel21 TimeTravel22 TimeTravel23 TimeTravel24 TimeTravel25 TimeTravel26 TimeTravel27 "
		+ "TimeTravel28 TimeTravel29 TimeTravel30 TimeTravel31 TimeTravel32").split(" ");

	static final PATHED_INTERIORS = ("MustChange_1 MustChange_5 MustChange_6 MustChange_7 MustChange_8 MustChange_9 MustChange_10 MustChange_11 "
		+ "MustChange_12 MustChange_13 MustChange_14 MustChange_15 MustChange_16 MustChange_17 MustChange_18").split(" ");

	public static function save(level:MarbleWorld) {
		var data:VVStateData = {
			fadingPlatforms: [
				for (name in FADING_PLATFORMS) {
					var obj = level.namedGameObjects.get(name.toLowerCase());
					{name: name, hidden: obj != null && Std.isOfType(obj, FadePlatform) && cast(obj, FadePlatform).currentOpacity == 0};
				}
			],
			timeTravels: [
				for (name in TIME_TRAVELS) {
					var obj = level.namedGameObjects.get(name.toLowerCase());
					{name: name, hidden: obj != null && Std.isOfType(obj, TimeTravel) && cast(obj, TimeTravel).currentOpacity == 0};
				}
			],
			pathedInteriors: [
				for (name in PATHED_INTERIORS) {
					var obj = level.namedGameObjects.get(name.toLowerCase());
					var pi = obj != null && Std.isOfType(obj, PathedInterior) ? cast(obj, PathedInterior) : null;
					{name: name, currentTime: pi != null ? pi.currentTime : 0.0, targetTime: pi != null ? pi.targetTime : 0.0};
				}
			],
			elapsedTime: level.finishTime != null ? level.finishTime.gameplayClock : 0.0,
			heldPowerup: level.marble.heldPowerup != null ? level.marble.heldPowerup.element.datablock : null,
		};
		writeRaw(Json.stringify(data));
	}

	public static function load():VVStateData {
		var raw = readRaw();
		return raw != null ? Json.parse(raw) : null;
	}

	public static function applyToLevel(level:MarbleWorld, data:VVStateData) {
		if (data == null)
			return;
		for (s in data.fadingPlatforms) {
			var obj = level.namedGameObjects.get(s.name.toLowerCase());
			if (obj != null && Std.isOfType(obj, FadePlatform)) {
				var fp = cast(obj, FadePlatform);
				fp.reset();
				if (s.hidden)
					fp.fadingState = fp.fadingLevel; // fully broken
			}
		}
		for (s in data.timeTravels) {
			var obj = level.namedGameObjects.get(s.name.toLowerCase());
			if (obj != null && Std.isOfType(obj, TimeTravel)) {
				var tt = cast(obj, TimeTravel);
				tt.reset();
				if (s.hidden)
					tt.lastPickUpTime = 1;
			}
		}
		for (s in data.pathedInteriors) {
			var obj = level.namedGameObjects.get(s.name.toLowerCase());
			if (obj != null && Std.isOfType(obj, PathedInterior)) {
				var pi = cast(obj, PathedInterior);
				pi.currentTime = s.currentTime;
				pi.targetTime = s.targetTime;
			}
		}
	}

	public static function hasSavedState():Bool {
		return readRaw() != null;
	}

	static function writeRaw(json:String) {
		#if hl
		if (!FileSystem.exists(Settings.settingsDir))
			FileSystem.createDirectory(Settings.settingsDir);
		File.saveContent(filePath, json);
		#end
		#if js
		var localStorage = js.Browser.getLocalStorage();
		if (localStorage != null)
			localStorage.setItem(STORAGE_KEY, json);
		#end
	}

	static function readRaw():String {
		#if hl
		if (FileSystem.exists(filePath))
			return File.getContent(filePath);
		#end
		#if js
		var localStorage = js.Browser.getLocalStorage();
		if (localStorage != null)
			return localStorage.getItem(STORAGE_KEY);
		#end
		return null;
	}
}

class ViceVersaMode extends NullMode {
	var isVersa:Bool;

	var checkedFinish:Bool = false;

	var loadedState:VVStateData;
	var targetElapsedTime:Float = 0;
	var startPowerupDatablock:String;

	var rampStartTime:Float = -1e8;

	public function new(level:MarbleWorld, isVersa:Bool) {
		super(level);
		this.isVersa = isVersa;
	}

	public override function onMissionLoad() {
		if (!this.isVersa)
			return;
		this.loadedState = ViceVersaState.load();
		if (!this.level.isWatching)
			applyLoadedState();
	}

	function applyLoadedState() {
		if (this.loadedState == null)
			return;
		ViceVersaState.applyToLevel(this.level, this.loadedState);
		this.targetElapsedTime = this.loadedState.elapsedTime;
		this.startPowerupDatablock = this.loadedState.heldPowerup;
	}

	public override function saveReplayData(bw:haxe.io.BytesOutput) {
		if (!this.isVersa)
			return;
		var json = this.loadedState != null ? Json.stringify(this.loadedState) : "";
		var bytes = haxe.io.Bytes.ofString(json);
		bw.writeInt32(bytes.length);
		bw.write(bytes);
	}

	public override function loadReplayData(br:haxe.io.BytesInput) {
		if (!this.isVersa)
			return;
		var len = br.readInt32();
		this.loadedState = len > 0 ? Json.parse(br.readString(len)) : null;
		applyLoadedState();
	}

	public override function onRestart() {
		super.onRestart();
		this.checkedFinish = false;
		if (!this.isVersa)
			return;
		applyLoadedState();
		this.rampStartTime = this.level.timeState.currentAttemptTime;
		givePowerup();
	}

	function givePowerup() {
		if (this.startPowerupDatablock == null)
			return;
		var wanted = this.startPowerupDatablock.toLowerCase();
		for (obj in this.level.dtsObjects) {
			if (Std.isOfType(obj, PowerUp)) {
				var p:PowerUp = cast obj;
				if (p.element.datablock.toLowerCase() == wanted) {
					this.level.pickUpPowerUp(this.level.marble, p);
					break;
				}
			}
		}
	}

	public override function onOutOfBounds(marble:Marble):Bool {
		for (obj in this.level.dtsObjects)
			if (Std.isOfType(obj, MegaManPlatform))
				cast(obj, MegaManPlatform).reset();
		return false;
	}

	public override function update(t:TimeState) {
		super.update(t);
		if (this.isVersa) {
			if (this.rampStartTime > -1e7) {
				var elapsed = t.currentAttemptTime - this.rampStartTime;
				var progress = hxd.Math.clamp(elapsed / 3.5, 0, 1);
				this.level.timeState.gameplayClock = this.targetElapsedTime * progress;
				if (progress >= 1)
					this.rampStartTime = -1e8; // ramp finished - let normal per-frame increment take over
			}
			return;
		}
		if (this.checkedFinish || this.level.finishTime == null)
			return;
		this.checkedFinish = true;
		var result = this.level.gameMode.getFinishScore();
		if (isNewPersonalBest(result.score, result.type))
			ViceVersaState.save(this.level);
	}

	function isNewPersonalBest(score:Float, type:ScoreType):Bool {
		var best = Settings.getScores(this.level.mission.path);
		if (best.length == 0)
			return true;
		return switch (type) {
			case Time: score < best[0].time;
			case Score: score > best[0].time;
		}
	}
}
