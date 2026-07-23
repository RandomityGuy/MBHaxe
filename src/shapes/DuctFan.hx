package shapes;

import hxd.snd.effect.Spatialization;
import src.ResourceLoader;
import src.AudioManager;
import hxd.snd.Channel;
import h3d.Vector;
import src.ForceObject;
import mis.MissionElement.MissionElementStaticShape;

class DuctFan extends ForceObject {
	var soundChannel:Channel;

	public function new(?element:MissionElementStaticShape) {
		super();
		var datablockLower = element != null ? element.datablock.toLowerCase() : "";
		this.dtsPath = switch (datablockLower) {
			case "ductfan_pq": "data/shapes_pq/gameplay/hazards/ductfan.dts";
			case "nomeshductfan_pq": "data/shapes_pq/gameplay/hazards/ductfannomesh.dts";
			default: "data/shapes/hazards/ductfan.dts";
		}
		this.isCollideable = true;
		this.isTSStatic = false;
		// Instancing batches by `identifier`, and the PQ variants use a different mesh - keep the
		// dtsPath in the identifier so they don't get batched with the vanilla mesh (or each other).
		this.identifier = "DuctFan" + this.dtsPath;
		this.forceDatas = [
			{
				forceType: ForceCone,
				forceNode: 0,
				forceStrength: 40,
				forceRadius: 10,
				forceArc: 0.7,
				forceVector: new Vector()
			}
		];
	}

	public override function init(level:src.MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/fan_loop.wav").entry.load(() -> {
				this.soundChannel = AudioManager.playSound(ResourceLoader.getResource("data/sound/fan_loop.wav", ResourceLoader.getAudio,
					this.soundResources), new Vector(1e8, 1e8, 1e8), true);
				this.soundChannel.pause = true;
				onFinish();
			});
		});
	}

	public override function reset() {
		super.reset();

		var seffect = this.soundChannel.getEffect(Spatialization);
		seffect.position = this.getAbsPos().getPosition();

		this.soundChannel.pause = !this.powered;
	}

	public override function setPowered(p:Bool) {
		super.setPowered(p);
		if (this.soundChannel != null)
			this.soundChannel.pause = !p;
	}
}
