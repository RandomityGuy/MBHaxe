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

	var lastContactTime:Float = -1e8;

	var fadingState:Int = 0;
	var fadingLevel:Int = 1;
	var fadingInitialState:Int = 0;
	var lastFadingContactTime:Float = -1e8;

	static inline final FADING_CONTACT_COOLDOWN = 0.25;

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
			return f != null && f[0] != "" ? f[0].toLowerCase() : null;
		}

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

	function applyCloak(cloakLevel:Float) {
		if (this.dtsShaders == null) {
			this.dtsShaders = [for (material in this.materials) material.mainPass.getShader(DtsTexture)];
			this.originalTextures = [for (shader in this.dtsShaders) shader != null ? shader.texture : null];
			this.whiteTexture = ResourceLoader.getResource("data/shapes/pads/white.jpg", ResourceLoader.getTexture, this.textureResources);
		}
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
					this.applyCloak(0); // restores the original texture
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
					this.setCollisionEnabled(false);
					this.setOpacity(0);
				} else if (progress - hideEnd < this.fadeInTime) {
					this.setCollisionEnabled(true);
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
				var isVisible = this.lastContactTime <= -1e7
					|| (!this.permanent
						&& timeState.currentAttemptTime - this.lastContactTime >= this.fadeOutTime + this.invisibleTime + this.fadeInTime);
				if (isVisible)
					this.lastContactTime = timeState.currentAttemptTime;
			case "fading":
				if (timeState.currentAttemptTime - this.lastFadingContactTime < FADING_CONTACT_COOLDOWN)
					return;
				this.lastFadingContactTime = timeState.currentAttemptTime;
				this.fadingState++;
		}
	}

	public override function reset() {
		super.reset();

		switch (this.functionality) {
			case "fading":
				this.fadingState = this.fadingInitialState;
				this.lastFadingContactTime = -1e8;
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
