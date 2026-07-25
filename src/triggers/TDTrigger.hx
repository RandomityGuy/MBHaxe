package triggers;

import src.Marble;
import src.TimeState;
import src.MarbleWorld;
import mis.MisParser;
import mis.MissionElement.MissionElementTrigger;
import modes.GameMode.GameModeFactory;
import modes.TwoDMode;

/** Ported from PQ's `TDTrigger` datablock (`modes/2d.cs`) - starts 2D mode (possibly on a
	different plane than the mission-wide default, or even in a mission that isn't 2D at all) on
	marble-enter, stopping it again on leave unless `KeepEffectOnLeave` is set. Matches
	`TDTrigger::onAdd`'s force-add behavior ("TDTrigger needs 2d mode but it's not listed in
	MissionInfo. Activating it ourselves"): `MarbleWorld.loadBegin` pre-scans the mission for any
	`TDTrigger` placement and appends `"2d"` to the mode string *before* `GameModeFactory.getGameMode`
	builds the mode tree, so a `TwoDMode` is always guaranteed to exist here regardless of what the
	mission itself declares - no runtime mode-tree mutation needed. */
class TDTrigger extends Trigger {
	var plane:String;
	var invertDirection:Bool;
	var keepEffectOnLeave:Bool;
	// `Math.NaN` = "no override" (`camdistance`/`targetpitch` blank or "NoChange") - matches
	// `TwoDMode.activate`'s sentinel convention.
	var camDistance:Float;
	var targetPitch:Float;
	var changesPitch:Bool;

	var twoDMode:TwoDMode;

	public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);

		this.twoDMode = GameModeFactory.findMode(level.gameMode, TwoDMode);

		var planeField = element.fields.get("plane");
		this.plane = planeField != null && planeField[0] != "" ? planeField[0] : "xz";

		var invertField = element.fields.get("invertdirection");
		this.invertDirection = invertField != null && MisParser.parseBoolean(invertField[0]);

		var keepField = element.fields.get("keepeffectonleave");
		this.keepEffectOnLeave = keepField != null && MisParser.parseBoolean(keepField[0]);

		var distField = element.fields.get("camdistance");
		this.camDistance = distField != null
			&& distField[0] != ""
			&& distField[0].toLowerCase() != "nochange" ? Std.parseFloat(distField[0]) : Math.NaN;

		var pitchField = element.fields.get("targetpitch");

		this.changesPitch = pitchField != null && pitchField[0] != "" && pitchField[0].toLowerCase() != "nochange";

		this.targetPitch = pitchField != null
			&& pitchField[0] != ""
			&& pitchField[0].toLowerCase() != "nochange" ? Std.parseFloat(pitchField[0]) : Math.NaN;
	}

	override function onMarbleEnter(marble:Marble, time:TimeState) {
		if (this.twoDMode == null)
			return;
		this.twoDMode.activate(TwoDMode.planeToYaw(this.plane, this.invertDirection), this.camDistance, this.changesPitch, this.targetPitch);
	}

	override function onMarbleLeave(marble:Marble, time:TimeState) {
		if (this.keepEffectOnLeave || this.twoDMode == null)
			return;
		this.twoDMode.deactivate();
	}
}
