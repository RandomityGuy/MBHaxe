package src;

import h3d.Vector;
import src.Console;

class Renderer extends h3d.scene.Renderer {
	var def(get, never):h3d.pass.Base;

	public var shadow = new h3d.pass.DefaultShadowMap(1);

	public function new() {
		super();
		defaultPass = new h3d.pass.Default("default");
		allPasses = [defaultPass, shadow];
		shadow.enabled = false;
	}

	inline function get_def()
		return defaultPass;

	// can be overriden for benchmark purposes
	function renderPass(p:h3d.pass.Base, passes, ?sort) {
		p.draw(passes, sort);
	}

	override function getPassByName(name:String):h3d.pass.Base {
		if (name == "alpha" || name == "additive")
			return defaultPass;
		return super.getPassByName(name);
	}

	override function render() {
		// if (has("shadow"))
		//	renderPass(shadow, get("shadow"));

		// The shadow bullshit
		ctx.setGlobalID(@:privateAccess shadow.shadowMapId, {
			texture: @:privateAccess shadow.dshader.shadowMap,
			channel: @:privateAccess shadow.format == h3d.mat.Texture.nativeFormat ? hxsl.Channel.PackedFloat : hxsl.Channel.R
		});
		ctx.setGlobalID(@:privateAccess shadow.shadowProjId, @:privateAccess shadow.getShadowProj());
		ctx.setGlobalID(@:privateAccess shadow.shadowColorId, new Vector(0, 0, 0, 0));
		ctx.setGlobalID(@:privateAccess shadow.shadowPowerId, 0.0);
		ctx.setGlobalID(@:privateAccess shadow.shadowBiasId, 0.0);

		renderPass(defaultPass, get("skyshape"));
		renderPass(defaultPass, get("default"));
		renderPass(defaultPass, get("shadowPass1"));
		renderPass(defaultPass, get("shadowPass2"));
		renderPass(defaultPass, get("shadowPass3"));
		renderPass(defaultPass, get("marble"));
		renderPass(defaultPass, get("alpha"), backToFront);
		renderPass(defaultPass, get("additive"));
	}
}
