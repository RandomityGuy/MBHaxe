package triggers;

import src.Marble;
import src.TimeState;
import src.MarbleWorld;
import mis.MisParser;
import mis.MissionElement.MissionElementTrigger;
import modes.GameMode.GameModeFactory;
import modes.TwoDMode;

class TDTrigger extends Trigger {
	var plane:String;
	var invertDirection:Bool;
	var keepEffectOnLeave:Bool;

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
			&& pitchField[0].toLowerCase() != "nochange" ? hxd.Math.degToRad(Std.parseFloat(pitchField[0])) : Math.NaN;
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
