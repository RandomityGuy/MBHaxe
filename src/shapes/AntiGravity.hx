package shapes;

import src.ResourceLoader;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import h3d.Vector;
import src.DtsObject;
import src.MarbleWorld;
import net.NetPacket.MarbleNetFlags;

class AntiGravity extends PowerUp {
	public function new(element:MissionElementItem, norespawn:Bool = false) {
		super(element);
		this.dtsPath = StringTools.endsWith(element.datablock, "_PQ") ? "data/shapes_pq/gameplay/powerups/gravmod.dts" : "data/shapes/items/antigravity.dts";
		this.isCollideable = false;
		this.isTSStatic = false;

		this.identifier = "AntiGravity" + this.dtsPath;
		this.pickUpName = "Gravity Modifier";
		this.autoUse = true;
		this.radarIndex = 11;
		if (norespawn)
			this.cooldownDuration = Math.NEGATIVE_INFINITY;
	}

	public function pickUp(marble:src.Marble):Bool {
		var direction = new Vector(0, 0, -1);
		direction.transform(this.getRotationQuat().toMatrix());
		return !direction.equals(marble.currentUp);
	}

	public function use(marble:src.Marble, timeState:TimeState) {
		if (!this.level.rewinding) {
			var direction = new Vector(0, 0, -1);
			direction.transform(this.getRotationQuat().toMatrix());
			if (marble == level.marble)
				this.level.setUp(marble, direction, timeState);
			else {
				@:privateAccess marble.netFlags |= MarbleNetFlags.GravityChange;
				marble.currentUp.load(direction);
			}
		}
		return true;
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/gravitychange.wav").entry.load(() -> {
				this.pickupSound = ResourceLoader.getResource("data/sound/gravitychange.wav", ResourceLoader.getAudio, this.soundResources);
				onFinish();
			});
		});
	}
}
