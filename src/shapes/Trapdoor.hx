package shapes;

import hxd.snd.effect.Spatialization;
import src.TimeState;
import collision.CollisionInfo;
import src.Util;
import src.DtsObject;
import h3d.Vector;
import src.ForceObject;
import src.ResourceLoader;
import src.AudioManager;
import src.MarbleWorld;
import src.Marble;

class Trapdoor extends DtsObject {
	var lastContactTime = -1e8;
	var timeout:Float = 0.2;
	var lastDirection:Int;
	var lastCompletion:Float = 0;

	public function new() {
		super();
		this.dtsPath = "data/shapes/hazards/trapdoor.dts";
		this.isCollideable = true;
		this.isTSStatic = false;
		this.identifier = "Trapdoor";
		this.hasNonVisualSequences = true;
		this.enableCollideCallbacks = true;
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/trapdooropen.wav").entry.load(onFinish);
		});
	}

	public override function update(timeState:TimeState) {
		var currentCompletion = this.getCurrentCompletion(timeState);

		// Override the keyframe
		this.sequenceKeyframeOverride.set(this.dts.sequences[0], currentCompletion * (this.dts.sequences[0].numKeyFrames - 1));
		super.update(timeState);

		var diff = (currentCompletion - this.lastCompletion);
		var direction = 0;
		if (diff > 0)
			direction = 1;
		if (diff < 0)
			direction = -1;
		if (direction != 0 && direction != this.lastDirection) {
			// If the direction has changed, play the sound
			var ch = AudioManager.playSound(ResourceLoader.getResource("data/sound/trapdooropen.wav", ResourceLoader.getAudio, this.soundResources),
				this.getAbsPos().getPosition());
		}

		this.lastCompletion = currentCompletion;
		this.lastDirection = direction;
	}

	function getCurrentCompletion(timeState:TimeState) {
		var elapsed = timeState.timeSinceLoad - this.lastContactTime;
		var completion = Util.clamp(elapsed / 1.6666676998138428, 0, 1);
		if (elapsed > 5)
			completion = Util.clamp(1 - (elapsed - 5) / 1.6666676998138428, 0, 1);
		return completion;
	}

	override function onMarbleContact(marble:Marble, time:TimeState, ?contact:CollisionInfo) {
		super.onMarbleContact(marble, time, contact);
		if (time.timeSinceLoad - this.lastContactTime <= 0)
			return; // The trapdoor is queued to open, so don't do anything.
		var currentCompletion = this.getCurrentCompletion(time);

		// Set the last contact time accordingly so that the trapdoor starts closing (again)
		this.lastContactTime = time.timeSinceLoad - currentCompletion * 1.6666676998138428;
		if (currentCompletion == 0)
			this.lastContactTime += this.timeout;

		// this.level.replay.recordMarbleContact(this);
	}

	override function postProcessMaterial(matName:String, material:h3d.mat.Material) {
		if (matName == "trapdoor") {
			var diffuseTex = ResourceLoader.getTexture("data/shapes/hazards/trapdoor.png").resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;
			var shader = new shaders.DefaultDiffuseMaterial(diffuseTex);
			var dtsTex = material.mainPass.getShader(shaders.DtsTexture);
			dtsTex.passThrough = true;
			material.mainPass.removeShader(material.textureShader);
			material.mainPass.addShader(shader);
			var thisprops:Dynamic = material.getDefaultProps();
			thisprops.light = false; // We will calculate our own lighting
			material.props = thisprops;
			material.shadows = false;
			material.receiveShadows = true;
		}
	}
}
