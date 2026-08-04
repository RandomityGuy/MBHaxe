package shapes;

import modes.MadnessMode;
import modes.GameMode.GameModeFactory;
import h3d.Vector;
import h3d.mat.BlendMode;
import src.DtsObject;
import src.TimeState;
import src.MarbleWorld;
import src.Marble;
import src.AudioManager;
import src.ResourceLoader;
import src.ResourceLoaderWorker;
import collision.CollisionInfo;
import src.ParticleSystem.ParticleData;
import src.ParticleSystem.ParticleEmitterOptions;
import src.ParticleSystem.ParticleEmitter;
import mis.MissionElement.MissionElementStaticShape;

final iceShardMistOptions:ParticleEmitterOptions = {
	ejectionPeriod: 294,
	periodVariance: 78,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 0,
	velocityVariance: 0,
	emitterLifetime: 1e9,
	ejectionOffset: 0.392157,
	thetaMin: 0,
	thetaMax: 148.235,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/smoke_blur32.png',
		blending: BlendMode.Add,
		spinSpeed: 10,
		spinRandomMin: -90,
		spinRandomMax: 0.5,
		lifetime: 1400,
		lifetimeVariance: 96,
		dragCoefficient: 9.21569,
		constantAcceleration: 0,
		gravityCoefficient: -0.0980392,
		windCoefficient: 0,
		colors: [
			new Vector(0.843137, 0.833333, 0.843137, 0),
			new Vector(0.784314, 0.813725, 0.882353, 0.686275),
			new Vector(0.843137, 0.862745, 0.892157, 0.264706),
			new Vector(0.892157, 0.911765, 0.980392, 0)
		],
		sizes: [0.83, 0.83, 1.08, 1.08],
		times: [0, 0.28, 0.73, 1]
	}
};

final iceShardShineOptions:ParticleEmitterOptions = {
	ejectionPeriod: 275,
	periodVariance: 274,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 3.92157,
	velocityVariance: 2.44098,
	emitterLifetime: 1e9,
	ejectionOffset: 0,
	thetaMin: 0,
	thetaMax: 180,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/glint2.png',
		blending: BlendMode.Alpha,
		spinSpeed: 0,
		spinRandomMin: 0,
		spinRandomMax: 0,
		lifetime: 1500,
		lifetimeVariance: 100,
		dragCoefficient: 10,
		constantAcceleration: 0,
		gravityCoefficient: 0,
		windCoefficient: 0,
		colors: [
			new Vector(0.852941, 0.911765, 1, 0),
			new Vector(0.862745, 0.901961, 1, 0),
			new Vector(0.862745, 0.892157, 1, 1),
			new Vector(0.862745, 0.892157, 1, 0)
		],
		sizes: [0.15, 0, 0.15, 0],
		times: [0, 0.78, 0.88, 1]
	}
};

final iceShardBreak1Options:ParticleEmitterOptions = {
	ejectionPeriod: 2,
	periodVariance: 1,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 2,
	velocityVariance: 0.05,
	emitterLifetime: 166,
	inheritedVelFactor: 0,
	thetaMin: 65.29412,
	thetaMax: 155.2941,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0.2,
	particleOptions: {
		texture: 'particles/fireball_1b.png',
		blending: BlendMode.Add,
		spinSpeed: 6.47059,
		spinRandomMin: -90,
		spinRandomMax: 0.5,
		dragCoefficient: 2.352941,
		lifetime: 422,
		lifetimeVariance: 421,
		constantAcceleration: 0,
		gravityCoefficient: 0.1176471,
		windCoefficient: 0.2745098,
		colors: [
			new Vector(0.842520, 0.700787, 0.653543, 0.0),
			new Vector(0.779528, 0.598425, 0.519685, 1.0),
			new Vector(0.881890, 0.519685, 0.370079, 0.574803),
			new Vector(0.889764, 0.905512, 0.976378, 0.0)
		],
		sizes: [0.1, 0.24, 0.34, 0.29],
		times: [0, 0.28, 0.74, 1]
	}
};

final iceShardBreak2Options:ParticleEmitterOptions = {
	ejectionPeriod: 4,
	periodVariance: 3,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 2.45098,
	velocityVariance: 0.05,
	emitterLifetime: 160,
	inheritedVelFactor: 0,
	thetaMin: 40.58823,
	thetaMax: 150,
	phiReferenceVel: 0,
	phiVariance: 360,
	ejectionOffset: 0.09803922,
	particleOptions: {
		texture: 'particles/fireball_2b.png',
		blending: BlendMode.Add,
		spinSpeed: 9.11765,
		spinRandomMin: -100,
		spinRandomMax: 0.5,
		dragCoefficient: 0.3921569,
		lifetime: 480,
		lifetimeVariance: 235,
		constantAcceleration: 0.392157,
		gravityCoefficient: 0.1764706,
		windCoefficient: 0,
		colors: [
			new Vector(0.842520, 0.826772, 0.842520, 0.440945),
			new Vector(0.779528, 0.811024, 0.881890, 1.0),
			new Vector(0.842520, 0.858268, 0.889764, 0.0),
			new Vector(0.889764, 0.905512, 0.976378, 0.0)
		],
		sizes: [0.78, 0.93, 0, 0],
		times: [0, 0.28, 0.74, 1]
	}
};

class IceShard extends DtsObject {
	public static inline final FREEZE_TIME = 2.0;
	public static inline final INVULN_TIME = 1.0;

	public var destroyed:Bool = false;

	var freezeSound:hxd.res.Sound;
	var crackSound:hxd.res.Sound;
	var smashSound:hxd.res.Sound;
	var element:MissionElementStaticShape;

	public var gotoTargetTriggered:Bool = false;

	var mistEmitter:ParticleEmitter;
	var shineEmitter:ParticleEmitter;
	var mistData:ParticleData;
	var shineData:ParticleData;
	var breakData1:ParticleData;
	var breakData2:ParticleData;

	var points = 0;

	public function new(element:MissionElementStaticShape) {
		super();
		this.element = element;
		var isShard2 = element.datablock.toLowerCase() == "iceshard2" || element.datablock.toLowerCase() == "pointiceshard2";
		this.dtsPath = isShard2 ? "data/shapes_pq/gameplay/hazards/ice_shard_2.dts" : "data/shapes_pq/gameplay/hazards/ice_shard.dts";
		this.isCollideable = true;
		this.identifier = "IceShard" + this.dtsPath;
		this.enableCollideCallbacks = true;

		var skinField = element.fields.get("skin");
		if (skinField != null && skinField[0] != "")
			this.skinOverride = skinField[0];
		if (this.skinOverride != null) {
			switch (this.skinOverride) {
				case "red":
					this.points = 1;
				case "yellow":
					this.points = 2;
				case "blue":
					this.points = 5;
				case "platinum":
					this.points = 10;
			}
		}
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			this.mistData = new ParticleData();
			this.mistData.identifier = "iceShardMist";
			this.mistData.texture = ResourceLoader.getResource("data/particles/smoke_blur32.png", ResourceLoader.getTexture, this.textureResources);

			this.shineData = new ParticleData();
			this.shineData.identifier = "iceShardShine";
			this.shineData.texture = ResourceLoader.getResource("data/particles/glint2.png", ResourceLoader.getTexture, this.textureResources);

			this.breakData1 = new ParticleData();
			this.breakData1.identifier = "IceShardBreak1Particle";
			this.breakData1.texture = ResourceLoader.getResource("data/particles/fireball_1b.png", ResourceLoader.getTexture, this.textureResources);

			this.breakData2 = new ParticleData();
			this.breakData2.identifier = "IceShardBreak2Particle";
			this.breakData2.texture = ResourceLoader.getResource("data/particles/fireball_2b.png", ResourceLoader.getTexture, this.textureResources);

			if (this.points == 0) {
				this.mistEmitter = this.level.particleManager.createEmitter(iceShardMistOptions, this.mistData, null, () -> this.getAbsPos().getPosition());
				this.shineEmitter = this.level.particleManager.createEmitter(iceShardShineOptions, this.shineData, null, () -> this.getAbsPos().getPosition());
			}

			var worker = new ResourceLoaderWorker(onFinish);
			worker.addTask(fwd -> ResourceLoader.load("sound/ice_freeze.wav").entry.load(() -> {
				this.freezeSound = ResourceLoader.getResource("data/sound/ice_freeze.wav", ResourceLoader.getAudio, this.soundResources);
				fwd();
			}));
			worker.addTask(fwd -> ResourceLoader.load("sound/ice_crack.wav").entry.load(() -> {
				this.crackSound = ResourceLoader.getResource("data/sound/ice_crack.wav", ResourceLoader.getAudio, this.soundResources);
				fwd();
			}));
			worker.addTask(fwd -> ResourceLoader.load("sound/ice_smash.wav").entry.load(() -> {
				this.smashSound = ResourceLoader.getResource("data/sound/ice_smash.wav", ResourceLoader.getAudio, this.soundResources);
				fwd();
			}));
			worker.run();
		});
	}

	public override function reset() {
		super.reset();

		this.gotoTargetTriggered = false;
		if (this.destroyed)
			this.setDestroyed(false);
	}

	public function playFreezeSound(marble:Marble) {
		if (marble == this.level.marble && this.freezeSound != null)
			AudioManager.playSound(this.freezeSound);
	}

	public function playCrackSound(marble:Marble) {
		if (marble == this.level.marble && this.crackSound != null)
			AudioManager.playSound(this.crackSound);
	}

	public function setDestroyed(destroyed:Bool) {
		this.destroyed = destroyed;
		this.isCollideable = !destroyed;
		this.setOpacity(destroyed ? 0 : 1);
		if (destroyed) {
			if (this.mistEmitter != null) {
				this.level.particleManager.removeEmitter(this.mistEmitter);
				this.mistEmitter = null;
			}
			if (this.shineEmitter != null) {
				this.level.particleManager.removeEmitter(this.shineEmitter);
				this.shineEmitter = null;
			}
		} else {
			if (this.points == 0) {
				this.mistEmitter = this.level.particleManager.createEmitter(iceShardMistOptions, this.mistData, null, () -> this.getAbsPos().getPosition());
				this.shineEmitter = this.level.particleManager.createEmitter(iceShardShineOptions, this.shineData, null, () -> this.getAbsPos().getPosition());
			}
		}
	}

	public function destroyByFireball() {
		if (this.destroyed)
			return;
		this.setDestroyed(true);

		var pos = this.getAbsPos().getPosition().add(new Vector(0, 0, -0.5));
		this.level.particleManager.createEmitter(iceShardBreak1Options, this.breakData1, pos);
		this.level.particleManager.createEmitter(iceShardBreak2Options, this.breakData2, pos);

		// Give points
		if (this.points != 0) {
			var gm = GameModeFactory.findMode(this.level.gameMode, MadnessMode);
			switch (points) {
				case 1:
					@:privateAccess level.playGui.addMiddleMessage('+1', 0xFF6666);
				case 2:
					@:privateAccess level.playGui.addMiddleMessage('+2', 0xFFFF66);
				case 5:
					@:privateAccess level.playGui.addMiddleMessage('+5', 0x6666FF);
				case 10:
					@:privateAccess level.playGui.addMiddleMessage('+10', 0xdddddd);
			}
			@:privateAccess gm.score += this.points;
			@:privateAccess level.playGui.formatGemHuntCounter(@:privateAccess gm.score);
		}
	}

	override function onMarbleContact(marble:Marble, timeState:TimeState, ?contact:CollisionInfo) {
		super.onMarbleContact(marble, timeState, contact);
		if (this.destroyed)
			return;

		if (marble.fireball) {
			this.destroyByFireball();
			marble.deductFireballTime(0.5);
			if (marble == this.level.marble && this.smashSound != null)
				AudioManager.playSound(this.smashSound);
			this.runGotoTarget(marble, timeState);
			return;
		}

		if (!marble.isFrozen && marble.lastFreezeTime + FREEZE_TIME + INVULN_TIME < timeState.currentAttemptTime)
			marble.freeze(this, timeState);

		this.runGotoTarget(marble, timeState);
	}

	function runGotoTarget(marble:Marble, timeState:TimeState) {
		var gotoTargetField = this.element.fields.get("gototarget");
		if (gotoTargetField == null || !mis.MisParser.parseBoolean(gotoTargetField[0]))
			return;

		var triggerOnceField = this.element.fields.get("triggeronce");
		var triggerOnce = triggerOnceField == null || mis.MisParser.parseBoolean(triggerOnceField[0]);
		if (triggerOnce && this.gotoTargetTriggered)
			return;
		this.gotoTargetTriggered = true;

		triggers.PathTrigger.runObjectPathChain(this.element.fields, this.level);

		var i = 1;
		while (true) {
			var interiorField = this.element.fields.get("pathedinterior" + i);
			var interiorName = interiorField != null ? interiorField[0].toLowerCase() : null;
			if (interiorName == null || interiorName == "")
				break;
			var target = this.level.namedGameObjects.get(interiorName);
			if (target == null || !(target is src.PathedInterior))
				break;

			var targetTimeField = this.element.fields.get("targettime" + i);
			var targetTime = targetTimeField != null ? mis.MisParser.parseNumber(targetTimeField[0]) : 999999;
			if (targetTime > 0)
				targetTime /= 1000;
			(cast target : src.PathedInterior).setTargetTime(timeState, targetTime);
			i++;
		}

		var textField = this.element.fields.get("text");
		if (textField != null && textField[0] != "") {
			var extendedField = this.element.fields.get("extended");
			var extended = extendedField != null && mis.MisParser.parseBoolean(extendedField[0]);
			if (extended)
				this.level.displayHelp(textField[0], 5);
			else
				this.level.displayAlert(textField[0]);
		}
	}
}
