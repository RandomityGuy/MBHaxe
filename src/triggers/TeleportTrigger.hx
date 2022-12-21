package triggers;

import h3d.Vector;
import src.ResourceLoader;
import src.AudioManager;
import mis.MisParser;
import src.MarbleWorld;
import mis.MissionElement.MissionElementTrigger;

class TeleportTrigger extends Trigger {
	var delay:Float = 2;

	var entryTime:Null<Float> = null;
	var exitTime:Null<Float> = null;

	public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);
		if (element.delay != null)
			this.delay = MisParser.parseNumber(element.delay) / 1000;
	}

	override function onMarbleEnter(time:src.TimeState) {
		this.exitTime = null;
		this.level.marble.setCloaking(true, time);
		if (this.entryTime != null)
			return;
		this.entryTime = time.currentAttemptTime;
		this.level.displayAlert("Teleporter has been activated, please wait.");
		AudioManager.playSound(ResourceLoader.getResource("data/sound/teleport.wav", ResourceLoader.getAudio, this.soundResources));
	}

	override function onMarbleLeave(time:src.TimeState) {
		this.exitTime = time.currentAttemptTime;
		this.level.marble.setCloaking(false, time);
	}

	public override function update(timeState:src.TimeState) {
		if (this.entryTime == null)
			return;

		if (timeState.currentAttemptTime - this.entryTime >= this.delay) {
			this.executeTeleport();
			return;
		}

		// There's a little delay after exiting before the teleporter gets cancelled
		if (this.exitTime != null && timeState.currentAttemptTime - this.exitTime > 0.050) {
			this.entryTime = null;
			this.exitTime = null;
			return;
		}
	}

	override function init(onFinish:() -> Void) {
		ResourceLoader.load("sound/teleport.wav").entry.load(onFinish);
	}

	function executeTeleport() {
		this.entryTime = null;

		function chooseNonNull(a:String, b:String) {
			if (a != null)
				return a;
			if (b != null)
				return b;
			return null;
		}

		// Find the destination trigger
		if (this.element.destination == null)
			return;
		var destinationList = this.level.triggers.filter(x -> x is DestinationTrigger
			&& x.element._name.toLowerCase() == this.element.destination.toLowerCase());
		if (destinationList.length == 0)
			return; // Who knows

		var destination = destinationList[0];

		var pos = MisParser.parseVector3(destination.element.position);
		pos.x = -pos.x;

		// Determine where to place the marble
		var position:Vector;
		if (MisParser.parseBoolean(chooseNonNull(this.element.centerdestpoint, destination.element.centerdestpoint))) {
			position = destination.collider.boundingBox.getCenter().toVector(); // Put the marble in the middle of the thing
		} else {
			position = destination.vertices[0].add(new Vector(0, 0, 3)).add(pos); // destination.vertices[0].clone().add(new Vector(0, 0, 3));
		}
		position.w = 1;
		this.level.marble.prevPos.load(position);
		this.level.marble.setPosition(position.x, position.y, position.z);
		var ct = this.level.marble.collider.transform.clone();
		ct.setPosition(position);
		this.level.marble.collider.setTransform(ct);
		if (this.level.isRecording) {
			this.level.replay.recordMarbleStateFlags(false, false, true, false);
		}

		if (!MisParser.parseBoolean(chooseNonNull(this.element.keepvelocity, destination.element.keepvelocity)))
			this.level.marble.velocity.set(0, 0, 0);
		if (MisParser.parseBoolean(chooseNonNull(this.element.inversevelocity, destination.element.inversevelocity)))
			this.level.marble.velocity.scale(-1);
		if (!MisParser.parseBoolean(chooseNonNull(this.element.keepangular, destination.element.keepangular)))
			this.level.marble.omega.set(0, 0, 0);

		// Determine camera orientation
		if (!MisParser.parseBoolean(chooseNonNull(this.element.keepcamera, destination.element.keepcamera))) {
			var yaw:Float;
			if (this.element.camerayaw != null)
				yaw = MisParser.parseNumber(this.element.camerayaw) * Math.PI / 180;
			else if (destination.element.camerayaw != null)
				yaw = MisParser.parseNumber(destination.element.camerayaw) * Math.PI / 180;
			else
				yaw = 0;

			yaw = -yaw; // Need to flip it for some reason

			this.level.marble.camera.CameraYaw = yaw + Math.PI / 2;
			this.level.marble.camera.CameraPitch = 0.45;
			this.level.marble.camera.nextCameraYaw = yaw + Math.PI / 2;
			this.level.marble.camera.nextCameraPitch = 0.45;
		}

		AudioManager.playSound(ResourceLoader.getResource("data/sound/spawn.wav", ResourceLoader.getAudio, this.soundResources));
	}
}
