package shapes;

import hxd.snd.effect.Spatialization;
import hxd.snd.Channel;
import src.ResourceLoader;
import src.AudioManager;
import h3d.Vector;
import src.ForceObject;
import mis.MissionElement.MissionElementStaticShape;

class SmallDuctFan extends ForceObject {
	var soundChannel:Channel;

	public function new(?element:MissionElementStaticShape) {
		super();
		this.dtsPath = (element != null && element.datablock.toLowerCase() == "smallductfan_pq") ? "data/shapes_pq/gameplay/hazards/ductfan.dts" :
			"data/shapes/hazards/ductfan.dts";
		this.isCollideable = true;
		this.isTSStatic = false;
		this.identifier = "DuctFan";
		this.forceDatas = [
			{
				forceType: ForceCone,
				forceNode: 0,
				forceStrength: 10,
				forceRadius: 5,
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
