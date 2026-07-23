package triggers;

import src.TimeState;
import src.Marble;
import mis.MisParser;

@:publicFields
@:structInit
class CameraDistanceState {
	var startDistance:Float;
	var targetDistance:Float;
	var startTime:Float;
	var duration:Float;
	var smooth:Bool;
}

class CameraDistanceTrigger extends Trigger {
	var prevDistances:Map<Marble, Float> = [];
	var states:Map<Marble, CameraDistanceState> = [];

	function getTime():Float {
		var field = this.element.fields.get("time");
		var time = field != null ? Std.parseFloat(field[0]) : 1000;
		return (Math.isNaN(time) || time <= 0) ? 1 : time / 1000;
	}

	function getSmooth():Bool {
		var field = this.element.fields.get("smooth");
		return field == null || MisParser.parseBoolean(field[0]);
	}

	function startTransition(marble:Marble, timeState:TimeState, target:Float) {
		states.set(marble, {
			startDistance: marble.camera.CameraDistance,
			targetDistance: target,
			startTime: timeState.currentAttemptTime,
			duration: getTime(),
			smooth: getSmooth()
		});
	}

	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		if (marble != this.level.marble)
			return;

		prevDistances.set(marble, marble.camera.CameraDistance);

		var distanceField = this.element.fields.get("distance");
		var distance = distanceField != null ? Std.parseFloat(distanceField[0]) : 2.5;
		if (Math.isNaN(distance))
			distance = 2.5;

		startTransition(marble, timeState, distance);
	}

	override function onMarbleLeave(marble:Marble, timeState:TimeState) {
		if (marble != this.level.marble)
			return;

		var keepField = this.element.fields.get("keepeffectonleave");
		var keepEffectOnLeave = keepField == null || MisParser.parseBoolean(keepField[0]);
		if (keepEffectOnLeave)
			return;

		var forceExitField = this.element.fields.get("forceexitvalue");
		var forceExitValue = forceExitField != null ? Std.parseFloat(forceExitField[0]) : 0;

		var target = forceExitValue != 0 ? forceExitValue : prevDistances.get(marble);
		if (target == null)
			target = marble.camera.CameraDistance;

		startTransition(marble, timeState, target);
	}

	public override function update(timeState:TimeState) {
		for (marble => state in states) {
			var t = (timeState.currentAttemptTime - state.startTime) / state.duration;
			if (t >= 1) {
				marble.camera.CameraDistance = state.targetDistance;
				states.remove(marble);
				continue;
			}
			var eased = state.smooth ? (-0.5 * Math.cos(t * Math.PI) + 0.5) : t;
			marble.camera.CameraDistance = state.startDistance + eased * (state.targetDistance - state.startDistance);
		}
	}
}
