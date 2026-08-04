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

/** Ported from `Vice.mcs`/`Versa.mcs`'s `vv_saveState`/`vv_loadState` - Vice and Versa are the same
	level laid out twice, and progress made in Vice (which fading platforms have broken, which Time
	Travels have already been collected, which position each "MustChange" pathed interior has
	reached, how much time had elapsed, and which powerup was held) carries over into Versa.

	Real PQ lets the player manage several named save slots via a whole dialog (`VVNameDlg`/
	`VVSelectorDlg`), auto-saving only on the player's very first-ever completion and otherwise
	prompting to save/name a slot. Simplified here (per direction) to a single always-overwritten
	slot, saved automatically whenever Vice is finished with a new personal best (generalizing the
	real "first completion" auto-save case to "any new best," since there's no slot-naming UI to
	fall back on for later completions), and applied unconditionally the next time Versa loads. The
	real `lb()` mission-checksum validation is not ported - out of scope for this simplified pass. */
class ViceVersaState {
	#if hl
	static var filePath = haxe.io.Path.join([Settings.settingsDir, "vicedata.json"]);
	#end
	#if js
	static inline var STORAGE_KEY = "MBHaxeViceVersaState";
	#end

	/** The exact named-object lists from `Vice.mcs`/`Versa.mcs`'s `$VV::FadingPlatformList`/
		`$VV::TimeTravelList`/`$VV::PathedInteriorList` - there's no in-mission way to discover which
		objects participate in Vice/Versa state transfer other than this literal list, copied
		verbatim (including the non-contiguous `MustChange_*` numbering - `_2`/`_3`/`_4` really are
		skipped in the source). */
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

	/** Ported from `TimeTravelItem_PQ::saveVVState`/`FadePlatformClass::saveVVState` (`%obj.isHidden()`)
		- both this engine's `FadePlatform` and `TimeTravel` use `setOpacity(0)`/collision-disabled as
		their "gone" state (see `DtsObject.setHide`), so `currentOpacity == 0` is the equivalent
		check regardless of *why* the object became hidden (broken vs. already picked up). */
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

	/** Just parses the save file/localStorage entry - doesn't touch the level. Split from the actual
		application (`applyToLevel`) so `ViceVersaMode` can also apply data recovered from a replay
		(recorded at a possibly-different time, against a possibly-different save) through the exact
		same code path - see `GameMode.saveReplayData`/`loadReplayData`. */
	public static function load():VVStateData {
		var raw = readRaw();
		return raw != null ? Json.parse(raw) : null;
	}

	/** Ported from `TimeTravelItem_PQ::loadVVState`/`FadePlatformClass::loadVVState`
		(`%obj.hide(%state)`) and `PathedInteriorData::loadVVState`
		(`setPathPosition`/`setTargetPosition`). `data.elapsedTime`/`data.heldPowerup` aren't applied
		here - `ViceVersaMode` handles those itself (they need to be re-applied on every restart, not
		just once).

		A plain `setHide(true)` is NOT enough for the fading platforms/Time Travels - both re-derive
		their own opacity/collision from their *own* internal state every single frame
		(`FadePlatform.update`'s `fadingState`/`fadingLevel` ratio for `functionality == "fading"`,
		`PowerUp.update`'s `lastPickUpTime`-based cooldown fade), which would silently undo a bare
		`setHide` on the very next tick - the platform would still be standable-on and the Time Travel
		still pickable regardless of how it *looks*, since `setHide` never touches the fields that
		actually gate that. `s.hidden` has to be baked into those fields directly instead. Calling
		`.reset()` first (for every object, not just the ones with `s.hidden == false`) also correctly
		un-does anything the player did to these *during this Versa attempt* before a restart - see
		`ViceVersaMode.onRestart`. */
	public static function applyToLevel(level:MarbleWorld, data:VVStateData) {
		if (data == null)
			return;
		for (s in data.fadingPlatforms) {
			var obj = level.namedGameObjects.get(s.name.toLowerCase());
			if (obj != null && Std.isOfType(obj, FadePlatform)) {
				var fp = cast(obj, FadePlatform);
				fp.reset();
				if (s.hidden)
					fp.fadingState = fp.fadingLevel; // fully broken, matches `ratio <= 0` forever
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

	/** Used to hide `Versa` from the mission list until a Vice run has actually been saved
		(simplified version of `display_Versa`'s real "beaten Vice with at least Par" + "has a saved
		run" check - see `PlayMissionGui`'s `currentList` filtering). */
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

/** Ported from `Vice.mcs`/`Versa.mcs` - see `ViceVersaState`'s doc comment for the full picture of
	what's carried over and what's simplified away. This mode's own job is the lifecycle hooks:
	apply any saved state on load and re-apply the elapsed-time ramp/held-powerup on every restart
	(Versa only), and check for + trigger a save on finish (Vice only). */
class ViceVersaMode extends NullMode {
	var isVersa:Bool;

	// Guards against re-checking every frame once finished (finishTime stays set for the rest of
	// the attempt) - reset on restart so a later attempt in the same session is checked again.
	var checkedFinish:Bool = false;

	// Versa-only: the state loaded from Vice's saved state (or, when watching a replay, from
	// whatever was actually recorded - see `saveReplayData`/`loadReplayData`), and the two fields
	// pulled out of it that need repeated access (`targetElapsedTime`/`startPowerupDatablock`, used
	// every restart, not just once).
	var loadedState:VVStateData;
	var targetElapsedTime:Float = 0;
	var startPowerupDatablock:String;

	// Ported from `vv_startTimer`'s `$VV::TimerDelta`/`Time::set($VV::TargetTime * progress)` ramp -
	// ramps `gameplayClock` from 0 up to `targetElapsedTime` over the same 3.5s window
	// `NullMode.onRestart`'s ready/set/go sequence already uses, so the mission clock visibly
	// "catches up" to where Vice left off just as real gameplay starts. `-1e8` = not currently
	// ramping (either not Versa, nothing saved, or the ramp already finished and normal per-frame
	// time increment has taken back over).
	var rampStartTime:Float = -1e8;

	public function new(level:MarbleWorld, isVersa:Bool) {
		super(level);
		this.isVersa = isVersa;
	}

	public override function onMissionLoad() {
		if (!this.isVersa)
			return;
		this.loadedState = ViceVersaState.load();
		// When watching a replay, wait for `loadReplayData` (called after this, once the mission's
		// finished loading) to overwrite `loadedState` with whatever was actually true at record
		// time, and apply from there instead - the live save file may have changed since.
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

	/** Ported from the need to keep a Versa replay reproducible even if `ViceVersaState`'s save file
		changes between recording and later playback - see `GameMode.saveReplayData`'s doc comment.
		Reuses `VVStateData`'s existing JSON (de)serialization rather than a bespoke binary format,
		since this only ever runs twice per replay (not per-frame) and the data's already JSON-shaped
		for the save file anyway. */
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
		// Fading platforms/Time Travels/pathed interiors are all still-interactive objects during a
		// Versa attempt (the player can break a platform, grab a Time Travel, nudge a "MustChange"
		// forward) - every restart has to snap them back to the loaded-from-Vice baseline, not just
		// the very first mission load, or a broken/collected/moved object would incorrectly persist
		// into the next attempt.
		applyLoadedState();
		this.rampStartTime = this.level.timeState.currentAttemptTime;
		givePowerup();
	}

	/** Ported from `serverCbOnRespawn`'s `LocalClientConnection.player.schedule(500, setPowerUp,
		$VV::StartPowerup, true)` - finds any placed powerup of the saved type (the specific instance
		doesn't matter, `MarbleWorld.pickUpPowerUp` just needs *a* reference of that type) and gives
		it to the marble. Runs from `onRestart`, which fires after `MarbleWorld.restart`'s own
		`deselectPowerUp` call, so the given powerup isn't immediately cleared afterward. */
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

	/** Ported from `serverCbOnOutOfBounds`'s `FPGroup` scan (`if (%d.className $= "MegaManPlatform")
		%d.onMissionReset(%fp);`) - present identically in both `Vice.mcs` and `Versa.mcs`. Doesn't
		take over the OOB flow itself (`false`), matching the real callback which only runs as a
		side-effect alongside the normal out-of-bounds handling. */
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
