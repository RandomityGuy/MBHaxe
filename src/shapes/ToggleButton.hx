package shapes;

import src.TimeState;
import collision.CollisionInfo;
import src.Util;
import src.DtsObject;
import src.MarbleWorld;
import mis.MissionElement.MissionElementStaticShape;
import mis.MisParser;

class ToggleButton extends DtsObject {
	var activated:Bool = false;
	var initialState:Bool = false;
	var currentCompletion:Float = 0;
	var disabledUntil:Float = -1e8;

	public function new(element:MissionElementStaticShape) {
		super();
		this.dtsPath = element.datablock.toLowerCase() == "togglebuttonflat_pq" ? "data/shapes_pq/gameplay/pads/pushbuttonflathalf.dts" : "data/shapes/buttons/pushbutton.dts";
		this.isCollideable = true;
		this.isTSStatic = false;
		this.identifier = "ToggleButton" + this.dtsPath;
		this.hasNonVisualSequences = true;
		this.enableCollideCallbacks = true;

		var initialStateField = element.fields.get("initialstate");
		this.initialState = initialStateField != null && MisParser.parseBoolean(initialStateField[0]);
		this.activated = this.initialState;
		this.currentCompletion = this.initialState ? 1 : 0;
	}

	public override function update(timeState:TimeState) {
		var target = this.activated ? 1.0 : 0.0;
		var duration = this.dts.sequences[0].duration;
		var rate = duration > 0 ? timeState.dt / duration : 1;
		if (this.currentCompletion < target)
			this.currentCompletion = Math.min(target, this.currentCompletion + rate);
		else if (this.currentCompletion > target)
			this.currentCompletion = Math.max(target, this.currentCompletion - rate);

		this.sequenceKeyframeOverride[0] = this.currentCompletion * (this.dts.sequences[0].numKeyFrames - 1);
		super.update(timeState);
	}

	override function onMarbleContact(marble:src.Marble, time:TimeState, ?contact:CollisionInfo) {
		super.onMarbleContact(marble, time, contact);
		if (time.timeSinceLoad < this.disabledUntil)
			return;
		this.disabledUntil = time.timeSinceLoad + 2;
		this.activated = !this.activated;
	}

	override function reset() {
		super.reset();
		this.activated = this.initialState;
		this.currentCompletion = this.initialState ? 1 : 0;
		this.disabledUntil = -1e8;
	}
}
