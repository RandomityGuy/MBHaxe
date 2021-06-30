package src;

import hxd.snd.effect.Spatialization;
import src.ResourceLoader;
import src.AudioManager;
import hxd.snd.Channel;
import src.DifBuilder;
import mis.MisParser;
import mis.MissionElement;
import triggers.MustChangeTrigger;
import mis.MissionElement.MissionElementPathedInterior;
import mis.MissionElement.MissionElementSimGroup;
import mis.MissionElement.MissionElementPath;
import h3d.Quat;
import src.TimeState;
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
	var path:MissionElementPath;
	var simGroup:MissionElementSimGroup;
	var element:MissionElementPathedInterior;

	public var triggers:Array<MustChangeTrigger> = [];

	public var markerData:Array<PathedInteriorMarker> = [];

	public var duration:Float;
	public var currentTime:Float;
	public var targetTime:Float;
	public var changeTime:Float;

	var basePosition:Vector;
	var baseOrientation:Quat;
	var baseScale:Vector;

	public var prevPosition:Vector;
	public var currentPosition:Vector;

	public var velocity:Vector;

	var stopped:Bool = false;
	var stopTime:Float;

	var previousState:PIState;

	var soundChannel:Channel;

	public static function createFromSimGroup(simGroup:MissionElementSimGroup, level:MarbleWorld) {
		var interiorElement:MissionElementPathedInterior = cast simGroup.elements.filter((element) -> element._type == MissionElementType.PathedInterior)[0];
		var difFile = level.mission.getDifPath(interiorElement.interiorresource);
		if (difFile == null)
			return null;
		var pathedInterior = new PathedInterior();
		pathedInterior.level = level;

		DifBuilder.loadDif(difFile, pathedInterior, cast MisParser.parseNumber(interiorElement.interiorindex)); // (difFile, path, level, );

		pathedInterior.identifier = difFile + interiorElement.interiorindex;

		pathedInterior.simGroup = simGroup;
		pathedInterior.element = interiorElement;
		level.interiors.push(pathedInterior);
		// await
		// Util.wait(10); // See shapes for the meaning of this hack
		// await
		pathedInterior.init(level);
		return pathedInterior;
	}

	public function new() {
		super();
	}

	public override function init(level:MarbleWorld) {
		this.basePosition = MisParser.parseVector3(this.element.baseposition);
		this.basePosition.x = -this.basePosition.x;
		this.baseOrientation = MisParser.parseRotation(this.element.baserotation);
		this.baseOrientation.x = -this.baseOrientation.x;
		this.baseOrientation.w = -this.baseOrientation.w;
		this.baseScale = MisParser.parseVector3(this.element.basescale);
		// this.hasCollision = this.baseScale.x != 0
		// 	&& this.baseScale.y != = 0 && this.baseScale.z != = 0; // Don't want to add buggy geometry

		// Fix zero-volume interiors so they receive correct lighting
		if (this.baseScale.x == 0)
			this.baseScale.x = 0.0001;
		if (this.baseScale.y == 0)
			this.baseScale.y = 0.0001;
		if (this.baseScale.z == 0)
			this.baseScale.z = 0.0001;

		this.setRotationQuat(this.baseOrientation);

		this.path = cast this.simGroup.elements.filter((element) -> element._type == MissionElementType.Path)[0];

		this.markerData = this.path.markers.map(x -> {
			var marker = new PathedInteriorMarker();
			marker.msToNext = MisParser.parseNumber(x.mstonext) / 1000;
			marker.smoothingType = x.smoothingtype;
			marker.position = MisParser.parseVector3(x.position);
			marker.position.x = -marker.position.x;
			marker.rotation = MisParser.parseRotation(x.rotation);
			marker.rotation.x = -marker.rotation.x;
			marker.rotation.w = -marker.rotation.w;
			return marker;
		});

		this.computeDuration();

		var triggers = this.simGroup.elements.filter((element) -> element._type == MissionElementType.Trigger);
		for (triggerElement in triggers) {
			var te:MissionElementTrigger = cast triggerElement;
			if (te.targettime == null)
				continue; // Not a pathed interior trigger
			var trigger = new MustChangeTrigger(te, cast this);
			this.triggers.push(trigger);
		}

		if (this.element.datablock.toLowerCase() == "pathedmovingblock") {
			this.soundChannel = AudioManager.playSound(ResourceLoader.getAudio("data/sound/movingblockloop.wav"), new Vector(), true);
		}

		this.reset();
	}

	public function update(timeState:TimeState) {
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

		var transform = this.getTransformAtTime(this.getInternalTime(timeState.currentAttemptTime));

		var position = transform.getPosition();
		this.prevPosition = this.currentPosition;
		this.currentPosition = position;
		if (!stopped) {
			this.stopTime = currentTime;
			pushTickState();
		}
		// if (!stopped)
		// 	this.currentTime = timeState.currentAttemptTime;

		velocity = position.sub(this.prevPosition).multiply(1 / timeState.dt);

		this.updatePosition();
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
		for (i in 0...(markerData.length - 1)) {
			var marker = markerData[i];
			total += marker.msToNext;
		}
		this.duration = total;
	}

	public function setTargetTime(now:TimeState, target:Float) {
		var currentInternalTime = this.getInternalTime(now.currentAttemptTime);
		this.currentTime = currentInternalTime; // Start where the interior currently is
		this.targetTime = target;
		this.changeTime = now.currentAttemptTime;
	}

	public function getInternalTime(externalTime:Float) {
		if (this.targetTime < 0) {
			var direction = (this.targetTime == -1) ? 1 : (this.targetTime == -2) ? -1 : 0;
			return Util.adjustedMod(this.currentTime + (externalTime - this.changeTime) * direction, this.duration);
		} else {
			var dur = Math.abs(this.currentTime - this.targetTime);

			var compvarion = Util.clamp(dur != 0 ? (externalTime - this.changeTime) / dur : 1, 0, 1);
			return Util.clamp(Util.lerp(this.currentTime, this.targetTime, compvarion), 0, this.duration);
		}
	}

	function updatePosition() {
		var tform = this.collider.transform;
		tform.setPosition(this.currentPosition);
		this.setTransform(tform);
		this.collider.setTransform(tform);
		this.collider.velocity = this.velocity;

		if (this.soundChannel != null) {
			var spat = this.soundChannel.getEffect(Spatialization);
			spat.position = this.currentPosition;
		}
	}

	function getTransformAtTime(time:Float) {
		var m1:PathedInteriorMarker = this.markerData[0];
		var m2:PathedInteriorMarker = this.markerData[1];
		if (m1 == null) {
			// Incase there are no markers at all
			var mat = new Matrix();
			this.baseOrientation.toMatrix(mat);
			mat.scale(this.baseScale.x, this.baseScale.y, this.baseScale.z);
			mat.setPosition(this.basePosition);
			return mat;
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
		var compvarion = Util.clamp(duration != 0 ? (time - m1Time) / duration : 1, 0, 1);
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
		position = position.sub(firstPosition);
		position = position.add(basePosition); // Add the base position

		var mat = new Matrix();
		this.baseOrientation.toMatrix(mat);

		mat.scale(this.baseScale.x, this.baseScale.y, this.baseScale.z);
		mat.setPosition(position);

		return mat;
	}

	override function reset() {
		this.currentTime = 0;
		this.targetTime = 0;
		this.changeTime = 0;

		if (this.element.initialposition != "") {
			this.currentTime = MisParser.parseNumber(this.element.initialposition) / 1000;
		}

		if (this.element.initialtargetposition != "") {
			this.targetTime = MisParser.parseNumber(this.element.initialtargetposition);
			if (this.targetTime > 0)
				this.targetTime /= 1000;
			// Alright this is strange. In Torque, there are some FPS-dependent client/server desync issues that cause the interior to start at the end position whenever the initialTargetPosition is somewhere greater than 1 and, like, approximately below 50.
			if (this.targetTime > 0 && this.targetTime < 0.05)
				this.currentTime = this.duration;
		}

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
