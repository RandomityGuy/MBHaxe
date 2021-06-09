package src;

import src.MarbleWorld;
import h3d.Matrix;
import h3d.Vector;
import src.Util;
import src.PathedInteriorMarker;
import src.InteriorObject;

typedef PIState = {
	var currentTime:Float;
	var targetTime:Float;
	var changeTime:Float;
	var prevPosition:Vector;
	var currentPosition:Vector;
	var velocity:Vector;
}

class PathedInterior extends InteriorObject {
	public var markerData:Array<PathedInteriorMarker> = [];

	public var duration:Float;
	public var currentTime:Float;
	public var targetTime:Float;
	public var changeTime:Float;

	public var prevPosition:Vector;
	public var currentPosition:Vector;

	public var velocity:Vector;

	var stopped:Bool = false;
	var stopTime:Float;

	var previousState:PIState;

	public function new() {
		super();
	}

	public override function init(level:MarbleWorld) {
		this.computeDuration();
		this.reset();
	}

	public function update(currentTime:Float, dt:Float) {
		// this.previousState = {
		// 	currentTime: currentTime,
		// 	targetTime: targetTime,
		// 	changeTime: changeTime,
		// 	prevPosition: prevPosition,
		// 	currentPosition: currentPosition,
		// 	velocity: velocity
		// };
		if (stopped) {
			currentTime = stopTime;
			popTickState();
		}

		var transform = this.getTransformAtTime(this.getInternalTime(currentTime));

		this.updatePosition();

		var position = transform.getPosition();
		this.prevPosition = this.currentPosition;
		this.currentPosition = position;
		if (!stopped) {
			this.stopTime = currentTime;
			pushTickState();
		}
		// if (!stopped)
		// 	this.currentTime = currentTime;

		velocity = position.sub(this.prevPosition).multiply(1 / dt);
	}

	public function setStopped(stopped:Bool = true) {
		// if (!this.stopped)
		// 	this.stopTime = currentTime;
		this.stopped = stopped;
	}

	public function recomputeVelocity(currentTime:Float, dt:Float) {
		var transform = this.getTransformAtTime(this.getInternalTime(currentTime));
		var position = transform.getPosition();
		velocity = position.sub(this.currentPosition).multiply(1 / dt);
	}

	public function pushTickState() {
		this.previousState = {
			currentTime: currentTime,
			targetTime: targetTime,
			changeTime: changeTime,
			prevPosition: prevPosition,
			currentPosition: currentPosition,
			velocity: velocity
		};
	}

	public function popTickState() {
		this.currentTime = this.previousState.currentTime;
		this.targetTime = this.previousState.targetTime;
		this.changeTime = this.previousState.changeTime;
		this.prevPosition = this.previousState.prevPosition;
		this.currentPosition = this.previousState.currentPosition;
		this.velocity = this.previousState.velocity;
		// this.updatePosition();
	}

	function computeDuration() {
		var total = 0.0;
		for (marker in markerData) {
			total += marker.msToNext;
		}
		this.duration = total;
	}

	public function setTargetTime(now:Float, target:Float) {
		var currentInternalTime = this.getInternalTime(now);
		this.currentTime = currentInternalTime; // Start where the interior currently is
		this.targetTime = target;
		this.changeTime = now;
	}

	public function getInternalTime(externalTime:Float) {
		if (this.targetTime < 0) {
			var direction = (this.targetTime == -1) ? 1 : (this.targetTime == -2) ? -1 : 0;
			return Util.adjustedMod(this.currentTime + (externalTime - this.changeTime) * direction, this.duration);
		} else {
			var dur = Math.abs(this.currentTime - this.targetTime);
			var compvarion = Util.clamp(dur > 0 ? (externalTime - this.changeTime) / dur : 1, 0, 1);
			return Util.clamp(Util.lerp(this.currentTime, this.targetTime, compvarion), 0, this.duration);
		}
	}

	function updatePosition() {
		var tform = this.collider.transform;
		tform.setPosition(this.currentPosition);
		this.setTransform(tform);
		this.collider.setTransform(tform);
		this.collider.velocity = this.velocity;
	}

	function getTransformAtTime(time:Float) {
		var m1:PathedInteriorMarker = this.markerData[0];
		var m2:PathedInteriorMarker = this.markerData[1];
		if (m1 == null) {
			// Incase there are no markers at all
			var mat = this.getTransform();
			return mat;
		} else {
			m1 = this.markerData[0];
		}
		// Find the two markers in question
		var currentEndTime = m1.msToNext;
		var i = 2;
		while (currentEndTime < time && i < this.markerData.length) {
			m1 = m2;
			m2 = this.markerData[i++];

			currentEndTime += m1.msToNext;
		}
		if (m2 == null)
			m2 = m1;

		var m1Time = currentEndTime - m1.msToNext;
		var m2Time = currentEndTime;
		var duration = m2Time - m1Time;
		var position:Vector = null;
		var compvarion = Util.clamp(duration > 0 ? (time - m1Time) / duration : 1, 0, 1);
		if (m1.smoothingType == "Accelerate") {
			// A simple easing function
			compvarion = Math.sin(compvarion * Math.PI - (Math.PI / 2)) * 0.5 + 0.5;
		} else if (m1.smoothingType == "Spline") {
			// Smooth the path like it's a Catmull-Rom spline.
			var preStart = (i - 2) - 1;
			var postEnd = (i - 1) + 1;
			if (postEnd >= this.markerData.length)
				postEnd = 0;
			if (preStart < 0)
				preStart = this.markerData.length - 1;
			var p0 = this.markerData[preStart].position;
			var p1 = m1.position;
			var p2 = m2.position;
			var p3 = this.markerData[postEnd].position;
			position = new Vector();
			position.x = Util.catmullRom(compvarion, p0.x, p1.x, p2.x, p3.x);
			position.y = Util.catmullRom(compvarion, p0.y, p1.y, p2.y, p3.y);
			position.z = Util.catmullRom(compvarion, p0.z, p1.z, p2.z, p3.z);
		}
		if (position == null) {
			var p1 = m1.position;
			var p2 = m2.position;
			position = Util.lerpThreeVectors(p1, p2, compvarion);
		}
		// Offset by the position of the first marker
		var firstPosition = this.markerData[0].position;
		position.sub(firstPosition);
		var tform = this.getTransform().clone();
		var basePosition = tform.getPosition();
		position.add(basePosition); // Add the base position
		tform.setPosition(position);
		return tform;
	}

	override function reset() {
		this.currentTime = 0;
		this.targetTime = -1;
		this.changeTime = 0;
		this.stopTime = 0;
		this.stopped = false;
		// Reset the position
		var transform = this.getTransformAtTime(this.getInternalTime(0));
		var position = transform.getPosition();
		this.prevPosition = position.clone();
		this.currentPosition = position;
		this.velocity = new Vector();
		updatePosition();
	}
}
