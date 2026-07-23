package shapes;

import src.Marble;
import src.TimeState;
import src.MarbleWorld;
import src.ResourceLoader;
import src.ResourceLoaderWorker;
import src.AudioManager;
import mis.MissionElement.MissionElementItem;
import mis.MisParser;

/** Press-to-arm, press-again-to-fire self-teleport: first use marks the current spot (and
	shows the marble's shared wireball marker there); second use cloaks the marble, waits
	`teleTime`, then warps it back to the marked spot (restoring camera + gravity), matching
	PQ's TeleportItem::onUse / setLocation / performTeleport / finishTeleport.

	The armed state, saved position/camera/gravity, and the marker object all live on the
	Marble itself (see Marble.hx's teleporter* fields) rather than on this class - PQ stores
	this on `%user`, not on the trigger/item instance, so it's shared across every TeleportItem
	in a level: arm with one, walk over a different powerup, then walk over a second
	TeleportItem and fire it - it still fires using the position/config saved by the first one. */
class TeleportItem extends PowerUp {
	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes_pq/gameplay/powerups/teleport.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "TeleportItem";
		this.pickUpName = "Teleport PowerUp";
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
		// Debounce: only treat this as a new "fire" if there's a gap since the last time we were
		// called (i.e. the button was released and pressed again), matching PQ's
		// teleporterFireNum/client.fireNum check. `timeState.ticks` doesn't work for this - it's
		// only meaningfully incremented in multiplayer, staying static in singleplayer, which made
		// this debounce swallow every press after the first forever. `timeSinceLoad` instead is
		// the *outer* per-frame time (this function is called once per physics substep, but
		// `pTime.timeSinceLoad` - unlike `pTime.currentAttemptTime` - is never touched per substep
		// in `Marble.advancePhysics`, so it's identical across every substep of one frame and only
		// changes frame-to-frame), reliable in both singleplayer and multiplayer.
		var isNewPress = timeState.timeSinceLoad - marble.teleporterLastUseTime > 0.001;
		marble.teleporterLastUseTime = timeState.timeSinceLoad;
		if (!isNewPress)
			return false;

		if (marble.teleporterArmed) {
			marble.teleporterArmed = false;
			marble.teleporterMarker.setPosition(1e8, 1e8, 1e8);
			marble.setCloaking(true, timeState);

			var savedPos = marble.teleporterSavedPosition.clone();
			var savedYaw = marble.teleporterSavedYaw;
			var savedPitch = marble.teleporterSavedPitch;
			var savedGravity = marble.teleporterSavedGravity.clone();
			var kv = marble.teleporterKeepVelocity;
			var isLocal = marble == this.level.marble;

			this.level.schedule(timeState.currentAttemptTime + marble.teleporterTeleTime, () -> {
				marble.setCloaking(false, this.level.timeState);
				if (!kv) {
					marble.velocity.set(0, 0, 0);
					marble.omega.set(0, 0, 0);
				}
				marble.prevPos.load(savedPos);
				marble.setPosition(savedPos.x, savedPos.y, savedPos.z);
				var ct = marble.collider.transform.clone();
				ct.setPosition(savedPos);
				marble.collider.setTransform(ct);

				if (isLocal) {
					marble.camera.CameraYaw = savedYaw;
					marble.camera.CameraPitch = savedPitch;
					marble.camera.nextCameraYaw = savedYaw;
					marble.camera.nextCameraPitch = savedPitch;
					this.level.setUp(marble, savedGravity, this.level.timeState, true);
					AudioManager.playSound(ResourceLoader.getResource("data/sound/teleport.wav", ResourceLoader.getAudio, this.soundResources));
				}
				return 0;
			});
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

			if (marble == this.level.marble)
				this.level.displayAlert("Teleporter has been activated, please wait.");
			return false;
		}
	}
}
