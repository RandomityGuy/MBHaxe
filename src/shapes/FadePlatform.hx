package shapes;

import h3d.mat.Texture;
import shaders.DtsTexture;
import src.DtsObject;
import src.TimeState;
import src.MarbleWorld;
import src.Util;
import src.ResourceLoader;
import collision.CollisionInfo;
import mis.MisParser;
import mis.MissionElement.MissionElementStaticShape;

/** Ported from PQ's `FadePlatformClass` (`server/scripts/fadingPlatforms.cs`). The original drives
	its cycling with `%obj.schedule(...)`/`cancel(...)` one-shot callbacks (`_hideSch`/`_toggleSch`);
	per the standing rule against schedules for gameplay logic, every mode here is instead computed
	as a pure function of `timeState.currentAttemptTime` (plus, for "trapdoor", a single
	`lastContactTime` timestamp) rather than an explicit state machine with its own elapsed-time
	accumulators - there is nothing to advance per-frame and nothing but plain scalars to persist, so
	rewind/pause/mission-reset all fall out for free without any dedicated snapshot logic.

	The "cloak" `fadeStyle` (confirmed against `OpenMBG-TGEMIT/engine/game/shapeBase.cc`/
	`tempRenderCompat.cpp`) ramps opacity toward `0.125 + (1 - cloakLevel) * 0.875` at a fixed rate
	of 2.0/sec (a 0.5s transition) that is *independent* of `fadeInTime`/`fadeOutTime` - reproduced
	here as a plain function of elapsed time *within the current segment*, computed fresh every call
	rather than accumulated frame-to-frame. */
class FadePlatform extends DtsObject {
	var functionality:String;
	var fadeStyle:String;
	var fadeInTime:Float;
	var fadeOutTime:Float;
	var visibleTime:Float;
	var invisibleTime:Float;
	var startOffset:Float;
	var permanent:Bool;
	var totalTime:Float;

	// "trapdoor" mode only - the sole piece of persisted state this class needs. A sentinel far in
	// the past means "never touched" (fully visible/collideable, the resting state).
	var lastContactTime:Float = -1e8;

	// "fading" mode only: `%obj.state`/`%obj.level` from the original script - state increments
	// once per collision, `level` is the number of hits needed to fully hide. Not part of the
	// original script, but a marble resting in continuous contact would otherwise increment
	// `fadingState` every single physics substep - `lastFadingContactTime` gates it to once per
	// 250ms, the same debounce pattern as `lastContactTime` above.
	var fadingState:Int = 0;
	var fadingLevel:Int = 1;
	var fadingInitialState:Int = 0;
	var lastFadingContactTime:Float = -1e8;
	static inline final FADING_CONTACT_COOLDOWN = 0.25;

	// "cloak" fadeStyle only - all captured lazily on the first call to `applyCloak` (materials
	// aren't ready yet in the constructor) and cached from then on, since `getShader`/
	// `ResourceLoader.getResource` aren't free and this runs every frame while cloaking.
	var dtsShaders:Array<DtsTexture>;
	var originalTextures:Array<Texture>;
	var whiteTexture:Texture;
	var isTextureWhite:Bool = false;

	static inline final CLOAK_RATE = 2.0;

	public function new(element:MissionElementStaticShape) {
		super();

		this.dtsPath = switch (element.datablock.toLowerCase()) {
			case "fadeplatform2_1x1": "data/shapes_pq/gameplay/hazards/FadePlatform/FadePlatform2_1x1.dts";
			case "fadeplatform2_1x2": "data/shapes_pq/gameplay/hazards/FadePlatform/FadePlatform2_1x2.dts";
			case "fadeplatform2_1x3": "data/shapes_pq/gameplay/hazards/FadePlatform/FadePlatform2_1x3.dts";
			case "fadeplatform2_1x5": "data/shapes_pq/gameplay/hazards/FadePlatform/FadePlatform2_1x5.dts";
			case "fadeplatform2_2x2": "data/shapes_pq/gameplay/hazards/FadePlatform/FadePlatform2_2x2.dts";
			case "fadeplatform2_3x3": "data/shapes_pq/gameplay/hazards/FadePlatform/FadePlatform2_3x3.dts";
			case "fadeplatform2_5x5": "data/shapes_pq/gameplay/hazards/FadePlatform/FadePlatform2_5x5.dts";
			case "fadeplatformconcrete": "data/shapes_pq/gameplay/hazards/FadePlatform/fadeplat_concrete_cube_2x2.dts";
			case "fadeplatformgrass": "data/shapes_pq/gameplay/hazards/FadePlatform/fadeplat_grass_cube_2x2.dts";
			case "fadeplatformice": "data/shapes_pq/gameplay/hazards/FadePlatform/fadeplat_ice_cube_2x2.dts";
			default: "data/shapes_pq/gameplay/hazards/FadePlatform/FadePlatform.dts";
		}
		this.isCollideable = true;
		this.enableCollideCallbacks = true;
		this.identifier = "FadePlatform" + this.dtsPath;

		function field(key:String):String {
			var f = element.fields.get(key);
			return f != null && f[0] != "" ? f[0] : null;
		}

		// The concrete/grass/ice variants disallow skinning entirely in the original (`skin[0] =
		// ""`), so a skin field is only meaningful for the base/size-variant datablocks.
		var isSkinnable = !StringTools.startsWith(element.datablock.toLowerCase(), "fadeplatformconcrete")
			&& !StringTools.startsWith(element.datablock.toLowerCase(), "fadeplatformgrass")
			&& !StringTools.startsWith(element.datablock.toLowerCase(), "fadeplatformice");
		if (isSkinnable) {
			var skin = field("skin");
			if (skin == null)
				skin = field("skinname");
			this.skinOverride = skin != null ? skin : "skin0";
		}

		this.functionality = field("functionality");
		if (this.functionality == null)
			this.functionality = "trapdoor";
		this.fadeStyle = field("fadestyle");
		if (this.fadeStyle == null)
			this.fadeStyle = "cloak";

		this.fadeInTime = parseTime(field("fadeintime"), 500);
		this.fadeOutTime = parseTime(field("fadeouttime"), 500);
		this.visibleTime = Util.clamp(parseTime(field("visibletime"), 500), 0.1, 120);
		this.invisibleTime = Util.clamp(parseTime(field("invisibletime"), 500), 0.1, 120);
		this.startOffset = parseTime(field("startoffset"), 0);
		this.permanent = field("permanent") != null && MisParser.parseBoolean(field("permanent"));
		this.totalTime = this.fadeOutTime + this.invisibleTime + this.fadeInTime + this.visibleTime;

		var levelField = field("level");
		this.fadingLevel = levelField != null ? Std.parseInt(levelField) : 1;
		if (this.fadingLevel <= 0)
			this.fadingLevel = 1;
		var stateField = field("state");
		this.fadingState = stateField != null ? Std.parseInt(stateField) : 0;
		this.fadingInitialState = this.fadingState;

		// The cloak style swaps each material's actual sampled texture (the `DtsTexture` shader's
		// `texture` param - see `applyCloak`, not `Material.texture`, which the render pipeline
		// never reads once `computeMaterials` swaps in that shader) - that param is a
		// per-material/per-batch uniform, not `@perInstance` like `currentOpacity` is, so instanced
		// platforms sharing a material would all flash white together. Only cloak-style platforms
		// need to opt out of instancing here.
		if (this.fadeStyle == "cloak")
			this.useInstancing = false;

		if (this.functionality == "periodic") {
			if (this.fadeStyle != "cloak")
				this.setOpacity(0);
		}
	}

	static function parseTime(field:String, def:Float):Float {
		if (field == null)
			return def / 1000;
		return Std.parseFloat(field) / 1000;
	}

	/** Applies the real engine's cloak visual for a given *physical* cloak amount (0 = fully
		normal, 1 = fully cloaked/white - not a segment-local progress value, so callers must flip
		the ramp direction themselves per segment). Swaps each material's actual sampled texture -
		the `DtsTexture` shader's `texture` param, which is what the fragment shader samples once
		`computeMaterials` swaps that shader in (see `shaders/DtsTexture.hx`); `Material.texture`
		itself is set for bookkeeping but never read by the render pipeline after that swap, so
		mutating it (as an earlier version of this file did) has no visual effect at all. Alpha
		follows `0.125 + (1 - cloakLevel) * 0.875` from `tempRenderCompat.cpp`. */
	function applyCloak(cloakLevel:Float) {
		if (this.dtsShaders == null) {
			this.dtsShaders = [for (material in this.materials) material.mainPass.getShader(DtsTexture)];
			this.originalTextures = [for (shader in this.dtsShaders) shader != null ? shader.texture : null];
			this.whiteTexture = ResourceLoader.getResource("data/shapes/pads/white.jpg", ResourceLoader.getTexture, this.textureResources);
		}
		// The texture only actually needs touching at the two instants it *changes* (entering vs.
		// leaving the cloaked look) - every other frame in between (steady white, steady normal, or
		// mid-fade where it's already white) would otherwise redundantly reassign every material's
		// shader texture, and this runs every frame this platform exists.
		var shouldBeWhite = cloakLevel > 0;
		if (shouldBeWhite != this.isTextureWhite) {
			this.isTextureWhite = shouldBeWhite;
			for (i in 0...this.dtsShaders.length) {
				var shader = this.dtsShaders[i];
				if (shader != null)
					shader.texture = shouldBeWhite ? this.whiteTexture : this.originalTextures[i];
			}
		}
		this.setOpacity(cloakLevel > 0 ? 0.125 + (1 - cloakLevel) * 0.875 : 1);
	}

	public override function update(timeState:TimeState) {
		super.update(timeState);

		if (this.functionality == "fading") {
			// Recomputed every frame (not just in `onMarbleContact`) purely so rewind can restore
			// `fadingState` as a plain Int and have the visual follow automatically, the same way
			// `periodic`/`trapdoor` already re-derive everything from a timestamp every frame.
			var ratio = (this.fadingLevel - this.fadingState) / this.fadingLevel;
			this.setCollisionEnabled(ratio > 0);
			this.setOpacity(Math.max(ratio, 0));
		}

		if (this.functionality == "periodic") {
			var progress = Util.adjustedMod(Math.max(0, timeState.currentAttemptTime - this.startOffset), this.totalTime);
			if (progress < this.fadeOutTime) {
				if (this.fadeStyle == "cloak")
					this.applyCloak(Math.min(progress * CLOAK_RATE, 1));
			} else if (progress - this.fadeOutTime < this.invisibleTime) {
				this.setCollisionEnabled(false);
				this.setOpacity(0);
			} else if (progress - this.fadeOutTime - this.invisibleTime < this.fadeInTime) {
				if (this.fadeStyle == "cloak") {
					var progressIn = Math.min((progress - this.fadeOutTime - this.invisibleTime) * CLOAK_RATE, 1);
					this.applyCloak(1 - progressIn);
				}
			} else {
				this.setCollisionEnabled(true);
				if (this.fadeStyle == "cloak")
					this.applyCloak(0); // restores the original texture, not just opacity
				this.setOpacity(1);
			}
		}

		if (this.functionality == "trapdoor") {
			if (this.lastContactTime > -1e7) {
				var progress = timeState.currentAttemptTime - this.lastContactTime;
				var hideEnd = this.fadeOutTime + this.invisibleTime;
				if (progress < this.fadeOutTime) {
					if (this.fadeStyle == "cloak")
						this.applyCloak(Math.min(progress * CLOAK_RATE, 1));
					else
						this.setOpacity(1 - Util.clamp(progress / Math.max(this.fadeOutTime, 0.001), 0, 1));
				} else if (this.permanent || progress - this.fadeOutTime < this.invisibleTime) {
					// `permanent` only takes effect once the cycle has actually reached this point -
					// gated by `lastContactTime > -1e7` above, so a never-triggered permanent trapdoor
					// stays in its default fully-visible/collideable state.
					this.setCollisionEnabled(false);
					this.setOpacity(0);
				} else if (progress - hideEnd < this.fadeInTime) {
					this.setCollisionEnabled(true); // `hide(false)` fires immediately at fade-in start.
					if (this.fadeStyle == "cloak") {
						var progressIn = Math.min((progress - hideEnd) * CLOAK_RATE, 1);
						this.applyCloak(1 - progressIn);
					} else {
						this.setOpacity(Util.clamp((progress - hideEnd) / Math.max(this.fadeInTime, 0.001), 0, 1));
					}
				} else {
					this.setCollisionEnabled(true);
					if (this.fadeStyle == "cloak")
						this.applyCloak(0); // restores the original texture, not just opacity
					this.setOpacity(1);
				}
			} else {
				// Resting state ("never touched") - also re-applied here every frame, not just in
				// `reset()`, so rewinding back to before this platform was ever touched restores the
				// visual/collision instead of leaving both stuck at whatever `update()` last computed
				// right before the rewind (the actual bug: this branch used to be skipped entirely
				// whenever `lastContactTime <= -1e7`, which is exactly what rewinding-to-never-touched
				// produces).
				this.setCollisionEnabled(true);
				if (this.fadeStyle == "cloak")
					this.applyCloak(0);
				else
					this.setOpacity(1);
			}
		}
	}

	override function onMarbleContact(marble:src.Marble, timeState:TimeState, ?contact:CollisionInfo) {
		super.onMarbleContact(marble, timeState, contact);

		switch (this.functionality) {
			case "trapdoor":
				// `onCollision` only reacts while the platform is currently in its visible resting
				// state (`if (%obj._visible)`) - re-touching it mid-fade/while hidden is a no-op.
				// True both for a never-yet-triggered platform and for a non-permanent platform
				// that's cycled all the way back around to visible; false forever for a permanent
				// platform once it's been triggered once.
				var isVisible = this.lastContactTime <= -1e7
					|| (!this.permanent
						&& timeState.currentAttemptTime - this.lastContactTime >= this.fadeOutTime + this.invisibleTime + this.fadeInTime);
				if (isVisible)
					this.lastContactTime = timeState.currentAttemptTime;
			case "fading":
				if (timeState.currentAttemptTime - this.lastFadingContactTime < FADING_CONTACT_COOLDOWN)
					return;
				this.lastFadingContactTime = timeState.currentAttemptTime;
				this.fadingState++; // visual reapplied every frame in `update()`
		}
	}

	public override function reset() {
		super.reset();

		switch (this.functionality) {
			case "fading":
				this.fadingState = this.fadingInitialState;
				this.lastFadingContactTime = -1e8; // visual reapplied every frame in `update()`
			case "trapdoor":
				this.lastContactTime = -1e8;
				this.setCollisionEnabled(true);
				if (this.fadeStyle == "cloak")
					this.applyCloak(0);
				else
					this.setOpacity(1);
		}
	}
}
