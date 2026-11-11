package shapes;

import src.DtsObject;
import mis.MissionElement.MissionElementStaticShape;
import src.Util;

class StartPad extends DtsObject {
	var animStart:Float = Math.POSITIVE_INFINITY;
	var isMbuPad = false;

	public function new(?element:MissionElementStaticShape) {
		super();
		var datablockLower = element != null ? element.datablock.toLowerCase() : "";
		dtsPath = switch (datablockLower) {
			case "startpad_pq": "data/shapes_pq/gameplay/pads/startpad.dts";
			case "startpad_pq_construction": "data/shapes_pq/gameplay/pads/startpadconst.dts";
			case "startpad_mbu": "data/shapes_mbu/pads/mbu/startarea.dts";
			default: "data/shapes/pads/startarea.dts";
		}
		isCollideable = true;
		identifier = "StartPad";
		useInstancing = false;
		isMbuPad = datablockLower == "startpad_mbu";
	}

	override function onLevelStart() {
		animStart = level.timeState.timeSinceLoad;
	}

	override function update(timeState:src.TimeState) {
		// Override the keyframe
		if (isMbuPad) {
			var currentCompletion = getCompletion(timeState);
			this.sequenceKeyframeOverride[0] = currentCompletion * (this.dts.sequences[0].numKeyFrames - 1);
		}
		super.update(timeState);
	}

	override function reset() {
		super.reset();
		animStart = level.timeState.timeSinceLoad;
	}

	function getCompletion(timeState:src.TimeState) {
		var elapsed = (timeState.timeSinceLoad - this.animStart) - 0.5; // 500ms for 'start' state;
		if (elapsed < 0)
			return 1.0;
		var completion = Util.clamp(elapsed / this.dts.sequences[0].duration, 0, 1);
		return completion;
	}
}
