package shapes;

import hxd.snd.effect.Spatialization;
import hxd.snd.Channel;
import h3d.Vector;
import src.ForceObject;
import src.ResourceLoader;
import src.AudioManager;

class Tornado extends ForceObject {
	var soundChannel:Channel;

	public function new() {
		super();
		this.dtsPath = "data/shapes/hazards/tornado.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "Tornado";
		this.forceDatas = [
			{
				forceType: ForceSpherical,
				forceNode: 0,
				forceStrength: -60,
				forceRadius: 8,
				forceArc: 0,
				forceVector: new Vector()
			},
			{
				forceType: ForceSpherical,
				forceNode: 0,
				forceStrength: 60,
				forceRadius: 3,
				forceArc: 0,
				forceVector: new Vector()
			},
			{
				forceType: ForceField,
				forceNode: 0,
				forceStrength: 250,
				forceRadius: 3,
				forceArc: 0,
				forceVector: new Vector(0, 0, 1)
			},
		];
	}

	public override function init(level:src.MarbleWorld) {
		super.init(level);
		this.soundChannel = AudioManager.playSound(ResourceLoader.getAudio("data/sound/tornado.wav"), this.getAbsPos().getPosition(), true);
		for (material in this.materials) {
			material.blendMode = Alpha;
			material.mainPass.culling = h3d.mat.Data.Face.None;
		}
	}

	public override function update(timeState:src.TimeState) {
		super.update(timeState);

		var seffect = this.soundChannel.getEffect(Spatialization);
		seffect.position = this.getAbsPos().getPosition();
	}
}
