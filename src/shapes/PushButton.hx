package shapes;

import hxd.snd.effect.Spatialization;
import src.TimeState;
import collision.CollisionInfo;
import src.Util;
import src.DtsObject;
import h3d.Vector;
import src.ForceObject;
import src.ResourceLoader;
import src.AudioManager;
import src.MarbleWorld;
import mis.MissionElement.MissionElementStaticShape;

class PushButton extends DtsObject {
	var lastContactTime = -1e8;
	var resetTime:Float; // Seconds until it resets, 0 for never

	public function new(element:MissionElementStaticShape) {
		super();
		this.resetTime = element.getResetTime(5000) / 1000;
		this.dtsPath = "data/shapes/buttons/pushbutton.dts";
		this.isCollideable = true;
		this.isTSStatic = false;
		this.identifier = "PushButton";
		this.hasNonVisualSequences = true;
		this.enableCollideCallbacks = true;
	}

	public override function update(timeState:TimeState) {
		var currentCompletion = this.getCurrentCompletion(timeState);

		// Override the keyframe
		this.sequenceKeyframeOverride[0] = (currentCompletion * (this.dts.sequences[0].numKeyFrames - 1));
		super.update(timeState);
	}

	function getCurrentCompletion(timeState:TimeState) {
		if (lastContactTime < -1e7)
			return 0.0; // Never touched
		var elapsed = timeState.timeSinceLoad - this.lastContactTime;
		var completion = Util.clamp(elapsed / this.dts.sequences[0].duration, 0, 1);
		if (resetTime > 0 && elapsed > resetTime)
			completion = Util.clamp(1 - (elapsed - resetTime) / this.dts.sequences[0].duration, 0, 1);
		return completion;
	}

	override function onMarbleContact(marble:src.Marble, time:TimeState, ?contact:CollisionInfo) {
		super.onMarbleContact(marble, time, contact);
		if (time.timeSinceLoad - this.lastContactTime <= 0)
			return; // The trapdoor is queued to open, so don't do anything.
		var currentCompletion = this.getCurrentCompletion(time);

		if (currentCompletion == 0)
			this.lastContactTime = time.timeSinceLoad;

		// this.level.replay.recordMarbleContact(this);
	}
}
