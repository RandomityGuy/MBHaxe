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
	marble-enter, stopping it again on leave unless `KeepEffectOnLeave` is set. */
class TDTrigger extends Trigger {
	var plane:String;
	var invertDirection:Bool;
	var keepEffectOnLeave:Bool;
	// `Math.NaN` = "no override" (`camdistance`/`targetpitch` blank or "NoChange") - matches
	// `TwoDMode.activate`'s sentinel convention.
	var camDistance:Float;
	var targetPitch:Float;

	public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);

		var planeField = element.fields.get("plane");
		this.plane = planeField != null && planeField[0] != "" ? planeField[0] : "xz";

		var invertField = element.fields.get("invertdirection");
		this.invertDirection = invertField != null && MisParser.parseBoolean(invertField[0]);

		var keepField = element.fields.get("keepeffectonleave");
		this.keepEffectOnLeave = keepField != null && MisParser.parseBoolean(keepField[0]);

		var distField = element.fields.get("camdistance");
		this.camDistance = distField != null && distField[0] != "" && distField[0].toLowerCase() != "nochange" ? Std.parseFloat(distField[0]) : Math.NaN;

		var pitchField = element.fields.get("targetpitch");
		this.targetPitch = pitchField != null && pitchField[0] != "" && pitchField[0].toLowerCase() != "nochange" ? Std.parseFloat(pitchField[0]) : Math.NaN;
	}

	override function onMarbleEnter(marble:Marble, time:TimeState) {
		var twoD = GameModeFactory.findMode(this.level.gameMode, TwoDMode);
		if (twoD == null)
			return;
		twoD.activate(TwoDMode.planeToYaw(this.plane, this.invertDirection), this.camDistance, this.targetPitch);
	}

	override function onMarbleLeave(marble:Marble, time:TimeState) {
		if (this.keepEffectOnLeave)
			return;
		var twoD = GameModeFactory.findMode(this.level.gameMode, TwoDMode);
		if (twoD != null)
			twoD.deactivate();
	}
}
