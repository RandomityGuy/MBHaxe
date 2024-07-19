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
import src.Resource;

typedef PIState = {
	var currentTime:Float;
	var targetTime:Float;
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

	var initialPosition:Float;
	var initialTargetPosition:Float;

	var basePosition:Vector;
	var baseOrientation:Quat;
	var baseScale:Vector;

	var prevPosition:Vector;
	var position:Vector;

	public var velocity:Vector;

	var stopped:Bool = false;
	var stoppedPosition:Vector;

	var savedPosition:Vector;
	var savedVelocity:Vector;
	var savedStopped:Bool;
	var savedStoppedPosition:Vector;
	var savedInvPosition:Vector;
	var savedTime:Float;

	var soundChannel:Channel;

	public static function createFromSimGroup(simGroup:MissionElementSimGroup, level:MarbleWorld, onFinish:PathedInterior->Void) {
		var interiorElement:MissionElementPathedInterior = cast simGroup.elements.filter((element) -> element._type == MissionElementType.PathedInterior)[0];
		var difFile = level.mission.getDifPath(interiorElement.interiorresource);
		if (difFile == null)
			onFinish(null);
		var pathedInterior = new PathedInterior();
		pathedInterior.level = level;
		pathedInterior.collisionWorld = level.collisionWorld;

		DifBuilder.loadDif(difFile, pathedInterior, () -> {
			pathedInterior.identifier = difFile + interiorElement.interiorindex;

			pathedInterior.simGroup = simGroup;
			pathedInterior.element = interiorElement;
			level.interiors.push(pathedInterior);
			pathedInterior.init(level, () -> {
				onFinish(pathedInterior);
			});
		}, cast MisParser.parseNumber(interiorElement.interiorindex));
	}

	public function new() {
		super();
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
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

		this.setRotationQuat(this.baseOrientation.clone());
		this.collider.setTransform(this.getTransform());
		this.collider.fastTransform = true;

		this.path = cast this.simGroup.elements.filter((element) -> element._type == MissionElementType.Path)[0];

		this.markerData = this.path.markers.map(x -> {
			var marker = new PathedInteriorMarker();
			marker.msToNext = MisParser.parseNumber(x.mstonext) / 1000;
			marker.smoothingType = switch (x.smoothingtype) {
				case "Accelerate":
					PathedInteriorMarker.SMOOTHING_ACCELERATE;
				case "Spline":
					PathedInteriorMarker.SMOOTHING_SPLINE;
				default:
					PathedInteriorMarker.SMOOTHING_LINEAR;
			};
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
			ResourceLoader.load("sound/movingblockloop.wav").entry.load(() -> {
				this.soundChannel = AudioManager.playSound(ResourceLoader.getResource("data/sound/movingblockloop.wav", ResourceLoader.getAudio,
					this.soundResources), new Vector(), true);
			});
		}

		this.reset();
		onFinish();
	}

	public function computeNextPathStep(timeDelta:Float) {
		stopped = false;
		prevPosition = this.position.clone();
		if (currentTime == targetTime) {
			velocity.set(0, 0, 0);
			this.collider.velocity.set(0, 0, 0);
		} else {
			var delta = 0.0;
			if (targetTime < 0) {
				if (targetTime == -1)
					delta = timeDelta;
				else if (targetTime == -2)
					delta = -timeDelta;
				currentTime += delta;
				while (currentTime >= duration)
					currentTime -= duration;
				while (currentTime < 0)
					currentTime += duration;
			} else {
				delta = targetTime - currentTime;
				if (delta < -timeDelta)
					delta = -timeDelta;
				else if (delta > timeDelta)
					delta = timeDelta;
				currentTime += delta;
			}

			var curTform = this.position;
			var tForm = getTransformAtTime(currentTime);

			var displaceDelta = tForm.getPosition().sub(curTform);
			velocity.set(displaceDelta.x / timeDelta, displaceDelta.y / timeDelta, displaceDelta.z / timeDelta);
			this.collider.velocity = velocity.clone();
		}
	}

	public function getInternalTime(externalTime:Float) {
		if (this.targetTime < 0) {
			var direction = (this.targetTime == -1) ? 1 : (this.targetTime == -2) ? -1 : 0;
			return Util.adjustedMod(this.currentTime + externalTime * direction, this.duration);
		} else {
			var dur = Math.abs(this.currentTime - this.targetTime);

			var compvarion = Util.clamp(dur != 0 ? externalTime / dur : 1, 0, 1);
			return Util.clamp(Util.lerp(this.currentTime, this.targetTime, compvarion), 0, this.duration);
		}
	}

	public function rollbackToTick(tick:Int) {
		// this.reset();
		// Reset
		this.currentTime = initialPosition;
		this.targetTime = initialTargetPosition;
		if (this.targetTime < 0) {
			var direction = (this.targetTime == -1) ? 1 : (this.targetTime == -2) ? -1 : 0;
			this.currentTime = Util.adjustedMod(this.currentTime + (tick * 0.032) * direction, duration);
		} else {
			this.currentTime = Util.clamp(this.currentTime + (tick * 0.032), 0, duration);
		}
		this.computeNextPathStep(0.032);
		this.advance(0.032);
	}

	public function advance(timeDelta:Float) {
		if (stopped)
			return;
		if (this.velocity.length() == 0)
			return;
		static var tform = new Matrix();
		velocity.w = 0;
		var newp = position.add(velocity.multiply(timeDelta));
		tform.load(this.getAbsPos()); // .clone();
		tform.setPosition(newp);

		if (this.isCollideable) {
			collider.setTransform(tform);
			collisionWorld.updateTransform(this.collider);
		}
		this.position.load(newp);

		if (this.soundChannel != null) {
			var spat = this.soundChannel.getEffect(Spatialization);
			spat.position = newp;
		}
	}

	public function update(timeState:TimeState) {
		if (!stopped)
			this.setPosition(prevPosition.x
				+ velocity.x * timeState.dt, prevPosition.y
				+ velocity.y * timeState.dt,
				prevPosition.z
				+ velocity.z * timeState.dt);
		else
			this.setPosition(stoppedPosition.x, stoppedPosition.y, stoppedPosition.z);
	}

	public function setStopped(stopped:Bool = true) {
		// if (!this.stopped)
		// 	this.stopTime = currentTime;
		this.stopped = stopped;
		this.stoppedPosition = this.position.clone();
	}

	public function pushTickState() {
		savedPosition = this.position.clone();
		savedInvPosition = @:privateAccess this.collider.invTransform.getPosition();
		savedVelocity = this.velocity.clone();
		savedStopped = this.stopped;
		savedStoppedPosition = this.stoppedPosition != null ? this.stoppedPosition.clone() : null;
		savedTime = this.currentTime;
	}

	public function popTickState() {
		this.position.load(savedPosition);
		this.velocity.load(savedVelocity);
		this.stopped = savedStopped;
		this.stoppedPosition = savedStoppedPosition;
		var oldtPos = this.collider.transform.getPosition();
		this.collider.transform.setPosition(savedPosition);
		@:privateAccess this.collider.invTransform.setPosition(savedInvPosition);

		this.collider.boundingBox.xMin += savedPosition.x - oldtPos.x;
		this.collider.boundingBox.xMax += savedPosition.x - oldtPos.x;
		this.collider.boundingBox.yMin += savedPosition.y - oldtPos.y;
		this.collider.boundingBox.yMax += savedPosition.y - oldtPos.y;
		this.collider.boundingBox.zMin += savedPosition.z - oldtPos.z;
		this.collider.boundingBox.zMax += savedPosition.z - oldtPos.z;

		collisionWorld.updateTransform(this.collider);

		this.currentTime = savedTime;
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
		this.targetTime = target;
	}

	function updatePosition() {
		var newp = this.getAbsPos().getPosition();
		this.position = newp;
		this.prevPosition = newp;
		this.setPosition(newp.x, newp.y, newp.z);
		this.collider.setTransform(this.getTransform());
		this.collider.velocity = this.velocity;

		if (this.soundChannel != null) {
			var spat = this.soundChannel.getEffect(Spatialization);
			spat.position = newp;
		}
	}

	function getTransformAtTime(time:Float) {
		var m1:PathedInteriorMarker = this.markerData[0];
		var m2:PathedInteriorMarker = this.markerData[1];
		if (m1 == null) {
			// Incase there are no markers at all
			var tmp = new Matrix();
			var mat = new Matrix();
			mat.initScale(this.baseScale.x, this.baseScale.y, this.baseScale.z);
			this.baseOrientation.toMatrix(tmp);
			mat.multiply3x4(mat, tmp);
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
		if (m1.smoothingType == PathedInteriorMarker.SMOOTHING_ACCELERATE) {
			// A simple easing function
			compvarion = Math.sin(compvarion * Math.PI - (Math.PI / 2)) * 0.5 + 0.5;
		} else if (m1.smoothingType == PathedInteriorMarker.SMOOTHING_SPLINE) {
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

		var tmp = new Matrix();
		var mat = new Matrix();
		mat.initScale(this.baseScale.x, this.baseScale.y, this.baseScale.z);
		this.baseOrientation.toMatrix(tmp);
		mat.multiply3x4(mat, tmp);
		mat.setPosition(position);

		return mat;
	}

	override function reset() {
		this.currentTime = 0;
		this.targetTime = 0;
		this.initialPosition = 0;
		this.initialTargetPosition = 0;

		if (this.element.initialposition != "") {
			this.currentTime = MisParser.parseNumber(this.element.initialposition) / 1000;
			initialPosition = this.currentTime;
		}

		if (this.element.initialtargetposition != "") {
			this.targetTime = MisParser.parseNumber(this.element.initialtargetposition);
			if (this.targetTime > 0)
				this.targetTime /= 1000;
			// Alright this is strange. In Torque, there are some FPS-dependent client/server desync issues that cause the interior to start at the end position whenever the initialTargetPosition is somewhere greater than 1 and, like, approximately below 50.
			if (this.targetTime > 0 && this.targetTime < 0.05)
				this.currentTime = this.duration;

			initialTargetPosition = this.targetTime;
		}

		this.stopped = false;
		// Reset the position
		this.velocity = new Vector();
		var initialTform = this.getTransformAtTime(this.currentTime);
		this.setTransform(initialTform);
		updatePosition();
	}
}
