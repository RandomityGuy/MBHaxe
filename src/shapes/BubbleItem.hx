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

/** Ported from `server/scripts/particles/ItemBubbleEmitter.cs` - the ambient bubble-fizz `fxEmitter`
	every `BubbleItem` pickup has (`server/scripts/powerups.cs`'s `fxEmitter[0] = "ItemBubbleEmitter"`),
	distinct from the marble's own underwater-breathing bubble trail (`Marble.hx`'s
	`TrailBubble` particle slot) despite sharing the same `bubble.png` texture as the real engine. */
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

/** Ported from PQ's `BubbleItem` (`server/scripts/powerups.cs`) - unlike every other `PowerUp`,
	picking one up doesn't occupy the single `heldPowerup` inventory slot at all; it just banks
	time directly onto the marble (`Marble.setBubbleTime`, mirroring `client.setBubbleTime`), so the
	slot stays free for another one-shot powerup even while bubble time is banked. `use()` is
	consequently never actually invoked through the normal `heldPowerup.use()` path - the marble's
	own `updateBubble` (hold-to-use, gated on `Move.powerupHeld`) drives activation instead. */
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
		// Matches `BubbleItem::onPickup`'s guard - no sense picking up another one while already
		// infinite.
		if (marble.bubbleInfinite)
			return false;
		// "Can't bubble with fireball" - one-directional (Fireball pickup cancels Bubble, but not
		// vice versa; see `Marble.activateFireball`).
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
			this.bubbleFxEmitter = this.level.particleManager.createEmitter(itemBubbleOptions, this.bubbleFxData, null,
				() -> this.getAbsPos().getPosition());
			onFinish();
		});
	}

	public override function dispose() {
		// Must run before `super.dispose()` - `DtsObject.dispose()` nulls `this.level`.
		if (this.bubbleFxEmitter != null) {
			this.level.particleManager.removeEmitter(this.bubbleFxEmitter);
			this.bubbleFxEmitter = null;
		}
		super.dispose();
	}
}
