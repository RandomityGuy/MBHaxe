package shapes;

import hxd.snd.effect.Spatialization;
import hxd.snd.Channel;
import h3d.Vector;
import src.ForceObject;
import src.ResourceLoader;
import src.AudioManager;
import src.MarbleWorld;

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

	public override function init(level:src.MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/tornado.wav").entry.load(() -> {
				this.soundChannel = AudioManager.playSound(ResourceLoader.getResource("data/sound/tornado.wav", ResourceLoader.getAudio, this.soundResources),
					new Vector(1e8, 1e8, 1e8), true);
				for (material in this.materials) {
					material.blendMode = Alpha;
					material.mainPass.culling = h3d.mat.Data.Face.None;
					material.mainPass.depthWrite = false;
				}
				onFinish();
			});
		});
	}

	public override function reset() {
		super.reset();

		var seffect = this.soundChannel.getEffect(Spatialization);
		seffect.position = this.getAbsPos().getPosition();
	}
}
