package shapes;

import h3d.shader.pbr.PropsValues;
import h3d.Vector;
import src.MarbleWorld;
import mis.MissionElement.MissionElementItem;
import src.TimeState;
import src.DtsObject;
import src.ResourceLoaderWorker;
import src.ResourceLoader;
import src.ParticleSystem.ParticleData;
import src.ParticleSystem.ParticleEmitter;
import src.ParticleSystem.ParticleEmitterOptions;
import h3d.mat.BlendMode;
import src.Marble;

/** PQ's per-color gem sparkle (`GemParticle<Color>`/`GemEmitter<Color>`, `server/scripts/gems.cs`) -
	an ambient emitter that runs continuously while the gem is uncollected, cleared on pickup
	(`Gem::onPickup`'s `clearFX`) and restored if un-picked-up (rewind). Base settings shared by
	every color (`GemParticleBase`/`GemEmitterBase`): a small glint, one every 40ms, using standard
	alpha blending (`useInvAlpha = true` in the source maps to `Alpha`, not `Add` - see
	`ParticleOptions.blending`'s doc comment for the general mapping). The
	source's `dragCoeffiecient = 0.1` is misspelled (dead field - the real, unset `dragCoefficient`
	defaults to `ParticleData`'s C++ default of 0), so this is a true 0, not the earlier port's `0.1`.
	`emitterLifetime` substitutes "effectively forever" for the source's own `lifetimeMS = 0`
	sentinel (see `PhysModTrigger.hx`'s note on the same substitution). */
final gemParticleBase:ParticleEmitterOptions = {
	ejectionPeriod: 40,
	periodVariance: 0,
	ambientVelocity: new Vector(0, 0, 0),
	ejectionVelocity: 0.3,
	velocityVariance: 0.01,
	emitterLifetime: 1e9,
	ejectionOffset: 0,
	thetaMin: 0,
	thetaMax: 150,
	phiReferenceVel: 0,
	phiVariance: 360,
	inheritedVelFactor: 0,
	particleOptions: {
		texture: 'particles/glint.png',
		blending: BlendMode.Alpha,
		spinSpeed: 1,
		spinRandomMin: -5.0,
		spinRandomMax: 5.0,
		lifetime: 1500,
		lifetimeVariance: 100,
		dragCoefficient: 0,
		constantAcceleration: 0,
		gravityCoefficient: 0,
		windCoefficient: 0,
		sizes: [0.15, 0.05, 0.05],
		times: [0, 0.75, 1],
		colors: null // set per-color below
	}
};

function gemParticleOptions(colors:Array<Vector>, ?sizes:Array<Float>, ?times:Array<Float>):ParticleEmitterOptions {
	return {
		ejectionPeriod: gemParticleBase.ejectionPeriod,
		periodVariance: gemParticleBase.periodVariance,
		ambientVelocity: gemParticleBase.ambientVelocity,
		ejectionVelocity: gemParticleBase.ejectionVelocity,
		velocityVariance: gemParticleBase.velocityVariance,
		emitterLifetime: gemParticleBase.emitterLifetime,
		ejectionOffset: gemParticleBase.ejectionOffset,
		thetaMin: gemParticleBase.thetaMin,
		thetaMax: gemParticleBase.thetaMax,
		phiReferenceVel: gemParticleBase.phiReferenceVel,
		phiVariance: gemParticleBase.phiVariance,
		inheritedVelFactor: gemParticleBase.inheritedVelFactor,
		particleOptions: {
			texture: gemParticleBase.particleOptions.texture,
			blending: gemParticleBase.particleOptions.blending,
			spinSpeed: gemParticleBase.particleOptions.spinSpeed,
			spinRandomMin: gemParticleBase.particleOptions.spinRandomMin,
			spinRandomMax: gemParticleBase.particleOptions.spinRandomMax,
			lifetime: gemParticleBase.particleOptions.lifetime,
			lifetimeVariance: gemParticleBase.particleOptions.lifetimeVariance,
			dragCoefficient: gemParticleBase.particleOptions.dragCoefficient,
			constantAcceleration: gemParticleBase.particleOptions.constantAcceleration,
			gravityCoefficient: gemParticleBase.particleOptions.gravityCoefficient,
			windCoefficient: gemParticleBase.particleOptions.windCoefficient,
			colors: colors,
			sizes: sizes != null ? sizes : gemParticleBase.particleOptions.sizes,
			times: times != null ? times : gemParticleBase.particleOptions.times
		}
	};
}

final gemParticleOptionsByColor:Map<String, ParticleEmitterOptions> = [
	"base" => gemParticleOptions([
		new Vector(1, 0, 1, 1),
		new Vector(1, 0.382353, 1, 1),
		new Vector(1, 0.490196, 1, 0)
	]),
	"pink" => gemParticleOptions([
		new Vector(1, 0, 1, 1),
		new Vector(1, 0.382353, 1, 1),
		new Vector(1, 0.490196, 1, 0)
	]),
	"green" => gemParticleOptions([
		new Vector(0.2, 1, 0.2, 1),
		new Vector(0.5, 1, 0.5, 1),
		new Vector(0.5, 1, 0.5, 0)
	]),
	"red" => gemParticleOptions([
		new Vector(0.8, 0.1, 0.1, 1),
		new Vector(0.8, 0.3, 0.3, 1),
		new Vector(0.8, 0.3, 0.3, 0)
	]),
	"blue" => gemParticleOptions([
		new Vector(0.2, 0.4, 1, 1),
		new Vector(0.5, 0.7, 1, 1),
		new Vector(0.5, 0.7, 1, 0)
	]),
	"black" => gemParticleOptions([
		new Vector(0.2, 0.2, 0.2, 1),
		new Vector(0.5, 0.5, 0.5, 1),
		new Vector(0.5, 0.5, 0.5, 0)
	]),
	"platinum" => gemParticleOptions([
		new Vector(0.5, 0.5, 0.5, 1),
		new Vector(0.7, 0.7, 0.7, 1),
		new Vector(1, 1, 1, 0.5),
		new Vector(1, 1, 1, 0)
	],
		[0.15, 0.05, 0.05, 0.2], [0, 0.75, 0.95, 1]),
	"yellow" => gemParticleOptions([new Vector(1, 1, 0.2, 1), new Vector(1, 1, 0.5, 1), new Vector(1, 1, 0.5, 0)]),
	"purple" => gemParticleOptions([
		new Vector(0.8, 0.3, 1, 1),
		new Vector(0.8, 0.5, 1, 1),
		new Vector(0.8, 0.5, 1, 0)
	]),
	"orange" => gemParticleOptions([
		new Vector(1, 0.8, 0.2, 1),
		new Vector(1, 0.8, 0.5, 1),
		new Vector(1, 0.8, 0.5, 0)
	]),
	"turquoise" => gemParticleOptions([new Vector(0.2, 1, 1, 1), new Vector(0.5, 1, 1, 1), new Vector(0.5, 1, 1, 0)])
];

class Gem extends DtsObject {
	public var pickedUp:Bool;
	public var netIndex:Int;
	public var pickUpClient:Int = -1;
	public var radarGemColor:Int;
	public var radarGemIndex:Int;

	var gemColor:String;
	var colorLower:String;
	var isPQGem:Bool;
	var spawnGemParticles:Bool;
	var gemParticleData:ParticleData;
	var gemEmitter:ParticleEmitter;

	public function new(element:MissionElementItem) {
		super();
		var isFancy = StringTools.startsWith(element.datablock, "FancyGemItem");
		var isPQ = StringTools.endsWith(element.datablock, "_PQ");
		dtsPath = isFancy ? "data/shapes_pq/gameplay/gems/gem_fancy.dts" : (isPQ ? "data/shapes_pq/gameplay/gems/gem.dts" : "data/shapes/items/gem.dts");
		ambientRotate = true;
		isCollideable = false;
		this.isBoundingBoxCollideable = true;
		pickedUp = false;
		useInstancing = true;
		showSequences = false; // Gems actually have an animation for the little shiny thing, but the actual game ignores that. I get it, it was annoying as hell.

		var GEM_COLORS = ["blue", "red", "yellow", "purple", "green", "turquoise", "orange", "black"];
		var prefixLength = (isFancy ? "FancyGemItem" : "GemItem").length;
		var color = element.datablock.substring(prefixLength);
		for (suffix in ["_PQ", "_MBU", "_MBG"])
			if (StringTools.endsWith(color, suffix))
				color = color.substring(0, color.length - suffix.length);
		if (color.length == 0)
			color = GEM_COLORS[Math.floor(Math.random() * GEM_COLORS.length)];
		if (isFancy) {
			color = element.fields.get("skin")[0];
		}
		// Instancing batches by `identifier`; color alone isn't enough since fancy/PQ/vanilla gems
		// use different mesh geometry (see dtsPath above), not just a different material.
		this.identifier = "Gem" + color + dtsPath;
		this.matNameOverride.set('base.gem', color + ".gem");
		gemColor = color + ".gem";
		var colLower = color.toLowerCase();
		this.colorLower = colLower;
		switch (colLower) {
			case "red":
				radarGemColor = 0xFF0000;
				radarGemIndex = 0;
			case "blue":
				radarGemColor = 0x6666E6;
				radarGemIndex = 2;

			case "yellow":
				radarGemColor = 0xFEFF00;
				radarGemIndex = 1;

			case "green":
				radarGemColor = 0x66E666;
				radarGemIndex = 3;

			case "orange":
				radarGemColor = 0xE6BA66;
				radarGemIndex = 4;

			case "pink":
				radarGemColor = 0xE666E5;
				radarGemIndex = 5;

			case "purple":
				radarGemColor = 0xC566E6;
				radarGemIndex = 6;

			case "turquoise":
				radarGemColor = 0x66E5E6;
				radarGemIndex = 7;

			case "black":
				radarGemColor = 0x666666;
				radarGemIndex = 8;

			case "platinum":
				radarGemColor = 0xA5A5A5;
				radarGemIndex = 9;
		}

		// PQ only spawns the ambient sparkle on its own gems (`GemItem_PQ`/`FancyGemItem_PQ` set
		// `pq = true` specifically "for gemFX"), and only if the level author didn't disable it via
		// the `noParticles` custom field.
		this.isPQGem = isPQ || isFancy;
		var noParticlesField = element.fields != null ? element.fields.get("noparticles") : null;
		var noParticles = noParticlesField != null && mis.MisParser.parseBoolean(noParticlesField[0]);
		this.spawnGemParticles = this.isPQGem && !noParticles;
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			if (this.spawnGemParticles) {
				this.gemParticleData = new ParticleData();
				this.gemParticleData.identifier = "gemParticle" + this.gemColor;
				this.gemParticleData.texture = ResourceLoader.getResource("data/particles/glint.png", ResourceLoader.getTexture, this.textureResources);
				this.startGemEmitter();
			}
			var worker = new ResourceLoaderWorker(onFinish);
			src.AudioManager.preloadPitchedSound("gotDiamond", worker);
			src.AudioManager.preloadPitchedSound("gotAllDiamonds", worker);
			worker.run();
		});
	}

	/** Starts (or restarts) the ambient sparkle - safe to call repeatedly, matching PQ's
		`initFX`/`clearFX` being idempotent from script's perspective. */
	function startGemEmitter() {
		if (!this.spawnGemParticles || this.gemEmitter != null)
			return;
		var options = gemParticleOptionsByColor.exists(this.colorLower) ? gemParticleOptionsByColor.get(this.colorLower) : gemParticleOptionsByColor.get("base");
		this.gemEmitter = this.level.particleManager.createEmitter(options, this.gemParticleData, null,
			() -> this.boundingCollider.boundingBox.getCenter().toVector());
	}

	function stopGemEmitter() {
		if (this.gemEmitter == null)
			return;
		this.level.particleManager.removeEmitter(this.gemEmitter);
		this.gemEmitter = null;
	}

	public override function setHide(hide:Bool) {
		if (hide) {
			this.pickedUp = true;
			this.setOpacity(0);
			this.stopGemEmitter();
		} else {
			this.pickedUp = false;
			this.setOpacity(1);
			this.startGemEmitter();
		}
	}

	override function onMarbleInside(marble:Marble, timeState:TimeState) {
		super.onMarbleInside(marble, timeState);
		if (this.pickedUp || this.level.rewinding)
			return;
		this.pickedUp = true;
		this.setOpacity(0); // Hide the gem
		this.stopGemEmitter();
		this.level.pickUpGem(marble, this);
		// this.level.replay.recordMarbleInside(this);
	}

	override function reset() {
		this.pickedUp = false;
		this.pickUpClient = -1;
		this.setOpacity(1);
		this.startGemEmitter();
	}
}
