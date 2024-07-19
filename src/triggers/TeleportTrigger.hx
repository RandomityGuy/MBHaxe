package triggers;

import src.Marble;
import h3d.Vector;
import src.ResourceLoader;
import src.AudioManager;
import mis.MisParser;
import src.MarbleWorld;
import mis.MissionElement.MissionElementTrigger;
import src.Console;

@:publicFields
@:structInit
class TeleportationState {
	var entryTime:Null<Float>;
	var exitTime:Null<Float>;
}

class TeleportTrigger extends Trigger {
	var delay:Float = 2;

	var marbleStates:Map<Marble, TeleportationState> = [];

	public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);
		if (element.delay != null)
			this.delay = MisParser.parseNumber(element.delay) / 1000;
	}

	function getState(marble:Marble) {
		if (marbleStates.exists(marble))
			return marbleStates.get(marble);
		else {
			marbleStates.set(marble, {entryTime: null, exitTime: null});
			return marbleStates.get(marble);
		}
	}

	override function onMarbleEnter(marble:src.Marble, time:src.TimeState) {
		var state = getState(marble);
		state.exitTime = null;
		marble.setCloaking(true, time);
		if (state.entryTime != null)
			return;
		state.entryTime = time.currentAttemptTime;
		if (level.marble == marble && @:privateAccess !marble.isNetUpdate) {
			this.level.displayAlert("Teleporter has been activated, please wait.");
			AudioManager.playSound(ResourceLoader.getResource("data/sound/teleport.wav", ResourceLoader.getAudio, this.soundResources));
		}
	}

	override function onMarbleLeave(marble:src.Marble, time:src.TimeState) {
		var state = getState(marble);
		state.exitTime = time.currentAttemptTime;
		marble.setCloaking(false, time);
	}

	public override function update(timeState:src.TimeState) {
		for (marble => state in marbleStates) {
			if (state.entryTime == null)
				continue;
			if (state.exitTime != null && timeState.currentAttemptTime - state.exitTime > 0.05) {
				state.entryTime = null;
				state.exitTime = null;
				continue;
			}

			if (timeState.currentAttemptTime - state.entryTime >= this.delay) {
				state.entryTime = null;
				this.executeTeleport(marble);
			}
		}
	}

	override function init(onFinish:() -> Void) {
		ResourceLoader.load("sound/teleport.wav").entry.load(onFinish);
	}

	function executeTeleport(marble:Marble) {
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
		marble.prevPos.load(position);
		marble.setPosition(position.x, position.y, position.z);
		var ct = marble.collider.transform.clone();
		ct.setPosition(position);
		marble.collider.setTransform(ct);
		if (this.level.isRecording) {
			this.level.replay.recordMarbleStateFlags(false, false, true, false);
		}

		if (!MisParser.parseBoolean(chooseNonNull(this.element.keepvelocity, destination.element.keepvelocity)))
			marble.velocity.set(0, 0, 0);
		if (MisParser.parseBoolean(chooseNonNull(this.element.inversevelocity, destination.element.inversevelocity)))
			marble.velocity.scale(-1);
		if (!MisParser.parseBoolean(chooseNonNull(this.element.keepangular, destination.element.keepangular)))
			marble.omega.set(0, 0, 0);

		Console.log('Teleport:');
		Console.log('Marble Position: ${position.x} ${position.y} ${position.z}');
		Console.log('Marble Velocity: ${marble.velocity.x} ${marble.velocity.y} ${marble.velocity.z}');
		Console.log('Marble Angular: ${marble.omega.x} ${marble.omega.y} ${marble.omega.z}');

		// Determine camera orientation
		if (marble == level.marble) {
			if (!MisParser.parseBoolean(chooseNonNull(this.element.keepcamera, destination.element.keepcamera))) {
				var yaw:Float;
				if (this.element.camerayaw != null)
					yaw = MisParser.parseNumber(this.element.camerayaw) * Math.PI / 180;
				else if (destination.element.camerayaw != null)
					yaw = MisParser.parseNumber(destination.element.camerayaw) * Math.PI / 180;
				else
					yaw = 0;

				yaw = -yaw; // Need to flip it for some reason

				marble.camera.CameraYaw = yaw + Math.PI / 2;
				marble.camera.CameraPitch = 0.45;
				marble.camera.nextCameraYaw = yaw + Math.PI / 2;
				marble.camera.nextCameraPitch = 0.45;
			}
			AudioManager.playSound(ResourceLoader.getResource("data/sound/spawn.wav", ResourceLoader.getAudio, this.soundResources));
		}
	}
}
