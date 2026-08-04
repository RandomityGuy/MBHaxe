package shapes;

import h3d.Vector;
import h3d.mat.BlendMode;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import src.Marble;
import src.MarbleWorld;
import src.ResourceLoader;
import src.ParticleSystem.ParticleData;
import src.ParticleSystem.ParticleEmitterOptions;
import src.ParticleSystem.ParticleEmitter;
import mis.MisParser;

final itemBubbleOptions:ParticleEmitterOptions = {
	ejectionPeriod: 25,
	periodVariance: 24,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 1.47059,
	velocityVariance: 0.490196,
	emitterLifetime: 1e9,
	ejectionOffset: 0.05,
	thetaMin: 0,
	thetaMax: 61.7647,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/bubble.png',
		blending: BlendMode.Add,
		spinSpeed: 1,
		spinRandomMin: 0,
		spinRandomMax: 0.5,
		lifetime: 1400,
		lifetimeVariance: 176,
		dragCoefficient: 1.176,
		constantAcceleration: 0,
		gravityCoefficient: 0,
		windCoefficient: 0,
		colors: [
			new Vector(0.843137, 0.833333, 0.843137, 1),
			new Vector(0.784314, 0.813725, 0.882353, 1),
			new Vector(0.843137, 0.862745, 0.892157, 1),
			new Vector(0.892157, 0.911765, 0.980392, 0)
		],
		sizes: [0, 0.05, 0.1, 0],
		times: [0, 0.02, 0.96, 1]
	}
};

class BubbleItem extends PowerUp {
	var time:Float;
	var infinite:Bool;
	var bubbleFxData:ParticleData;
	var bubbleFxEmitter:ParticleEmitter;

	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes_pq/gameplay/powerups/bubble.dts";
		this.identifier = "BubbleItem";
		this.pickUpName = "Bubble PowerUp";
		this.radarIndex = 14;

		var timeField = element.fields.get("time");
		this.time = timeField != null && timeField[0] != "" ? MisParser.parseNumber(timeField[0]) / 1000 : 5;
		var infiniteField = element.fields.get("infinite");
		this.infinite = infiniteField != null && MisParser.parseBoolean(infiniteField[0]);
	}

	public function pickUp(marble:Marble):Bool {
		if (marble.bubbleInfinite)
			return false;
		if (marble.fireball)
			return false;
		marble.setBubbleTime(this.time, this.infinite);
		return true;
	}

	public function use(marble:Marble, timeState:TimeState):Bool {
		return true;
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			this.bubbleFxData = new ParticleData();
			this.bubbleFxData.identifier = "itemBubbleFx";
			this.bubbleFxData.texture = ResourceLoader.getResource("data/particles/bubble.png", ResourceLoader.getTexture, this.textureResources);
			this.bubbleFxEmitter = this.level.particleManager.createEmitter(itemBubbleOptions, this.bubbleFxData, null, () -> this.getAbsPos().getPosition());
			onFinish();
		});
	}

	public override function dispose() {
		if (this.bubbleFxEmitter != null) {
			this.level.particleManager.removeEmitter(this.bubbleFxEmitter);
			this.bubbleFxEmitter = null;
		}
		super.dispose();
	}
}
