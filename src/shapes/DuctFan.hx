package shapes;

import hxd.snd.effect.Spatialization;
import src.ResourceLoader;
import src.AudioManager;
import hxd.snd.Channel;
import h3d.Vector;
import src.ForceObject;

class DuctFan extends ForceObject {
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
