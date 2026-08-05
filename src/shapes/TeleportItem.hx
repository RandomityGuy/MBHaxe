package shapes;

import src.Marble;
import src.TimeState;
import src.MarbleWorld;
import src.ResourceLoader;
import src.ResourceLoaderWorker;
import src.AudioManager;
import mis.MissionElement.MissionElementItem;
import mis.MisParser;

class TeleportItem extends PowerUp {
	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes_pq/gameplay/powerups/teleport.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "TeleportItem";
		this.pickUpName = "Teleport PowerUp";
		this.radarIndex = 31;

		var keepVelocityField = this.element.fields.get("keepvelocity");
		var keepVelocity = keepVelocityField != null && MisParser.parseBoolean(keepVelocityField[0]);
		if (keepVelocity) {
			this.skinOverride = "yellow";
			this.identifier += "Yellow";
		}
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			var worker = new ResourceLoaderWorker(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/putteleportitemvoice.wav", ResourceLoader.getAudio, this.soundResources);
				onFinish();
			});
			worker.loadFile("sound/putteleportitemvoice.wav");
			worker.loadFile("sound/teleport.wav");
			worker.run();
		});
	}

	public function pickUp(marble:Marble):Bool {
		return this.level.pickUpPowerUp(marble, this);
	}

	public function use(marble:Marble, timeState:TimeState):Bool {
		if (marble.teleporterArmed) {
			marble.teleporterArmed = false;
			marble.teleporterMarker.setPosition(1e8, 1e8, 1e8);
			marble.setCloaking(true, timeState);

			marble.teleporterFiring = true;
			@:privateAccess marble.teleporterFireStartTime = timeState.currentAttemptTime;

			AudioManager.playSound(ResourceLoader.getResource("data/sound/teleport.wav", ResourceLoader.getAudio, this.soundResources));
			if (marble == this.level.marble)
				this.level.displayAlert("Teleporter has been activated, please wait.");
			this.level.deselectPowerUp(marble);
			return true;
		} else {
			var keepVelocityField = this.element.fields.get("keepvelocity");
			var teleTimeField = this.element.fields.get("teletime");

			marble.teleporterSavedPosition = marble.getAbsPos().getPosition().clone();
			marble.teleporterSavedYaw = marble.camera.CameraYaw;
			marble.teleporterSavedPitch = marble.camera.CameraPitch;
			marble.teleporterSavedGravity = marble.currentUp.clone();
			marble.teleporterKeepVelocity = keepVelocityField != null && MisParser.parseBoolean(keepVelocityField[0]);
			marble.teleporterTeleTime = teleTimeField != null ? MisParser.parseNumber(teleTimeField[0]) / 1000 : 2;
			marble.teleporterArmed = true;

			marble.teleporterMarker.skinOverride = marble.teleporterKeepVelocity ? "yellow" : null;
			marble.teleporterMarker.setPosition(marble.teleporterSavedPosition.x, marble.teleporterSavedPosition.y, marble.teleporterSavedPosition.z);
			return false;
		}
	}
}
