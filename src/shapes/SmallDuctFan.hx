package shapes;

import hxd.snd.effect.Spatialization;
import hxd.snd.Channel;
import src.ResourceLoader;
import src.AudioManager;
import h3d.Vector;
import src.ForceObject;

class SmallDuctFan extends ForceObject {
	var soundChannel:Channel;

	public function new() {
		super();
		this.dtsPath = "data/shapes/hazards/ductfan.dts";
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

	public override function init(level:src.MarbleWorld) {
		super.init(level);

		this.soundChannel = AudioManager.playSound(ResourceLoader.getAudio("data/sound/fan_loop.wav"), this.getAbsPos().getPosition(), true);
	}

	public override function update(timeState:src.TimeState) {
		super.update(timeState);

		var seffect = this.soundChannel.getEffect(Spatialization);
		seffect.position = this.getAbsPos().getPosition();
		seffect.referenceDistance = 5;
	}
}
