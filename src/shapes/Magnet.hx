package shapes;

import hxd.snd.effect.Spatialization;
import src.ResourceLoader;
import src.AudioManager;
import hxd.snd.Channel;
import h3d.Vector;
import src.ForceObject;

class Magnet extends ForceObject {
	var soundChannel:Channel;

	public function new() {
		super();
		this.dtsPath = "data/shapes/hazards/magnet/magnet.dts";
		this.isCollideable = true;
		this.isTSStatic = false;
		this.identifier = "Magnet";
		this.useInstancing = true;
		this.forceDatas = [
			{
				forceType: ForceCone,
				forceNode: 0,
				forceStrength: -90,
				forceRadius: 10,
				forceArc: 0.7,
				forceVector: new Vector()
			}
		];
	}

	public override function init(level:src.MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/magnet.wav").entry.load(() -> {
				this.soundChannel = AudioManager.playSound(ResourceLoader.getResource("data/sound/magnet.wav", ResourceLoader.getAudio, this.soundResources),
					new Vector(1e8, 1e8, 1e8), true);
				this.soundChannel.pause = true;
				onFinish();
			});
		});
	}

	public override function reset() {
		super.reset();

		if (this.soundChannel != null) {
			var seffect = this.soundChannel.getEffect(Spatialization);
			seffect.position = this.getAbsPos().getPosition();
			seffect.fadeDistance = 15;
			// seffect.maxDistance = 5;

			if (this.soundChannel.pause)
				this.soundChannel.pause = false;
		}
	}
}
