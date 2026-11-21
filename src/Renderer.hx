package src;

import h3d.Vector;
import h3d.pass.ScreenFx;
import h3d.shader.ScreenShader;
import h3d.mat.Stencil;
import h3d.mat.Data.Compare;
import h3d.mat.Data.StencilOp;
import h3d.mat.Data.Face;
import h3d.mat.Data.Blend;
import src.Console;
import src.Settings;

class Renderer extends h3d.scene.Renderer {
	var def(get, never):h3d.pass.Base;

	public var shadow = new h3d.pass.DefaultShadowMap(1);

	var stencilClear:ScreenFx<StencilScreenShader>;
	var stencilDarken:ScreenFx<StencilScreenShader>;
	var darkenColor:StencilScreenShader;

	public function new() {
		super();
		defaultPass = new h3d.pass.Default("default");
		allPasses = [defaultPass, shadow];
		shadow.enabled = false;

		stencilClear = new ScreenFx(new StencilScreenShader());
		stencilClear.shader.color.set(0, 0, 0, 0);
		stencilClear.pass.depth(false, Always);
		stencilClear.pass.culling = None;
		stencilClear.pass.setColorMask(false, false, false, false);
		stencilClear.pass.blend(One, Zero);
		var clearStencil = new Stencil();
		clearStencil.setFunc(Always, 0, 0xFF, 0xFF);
		clearStencil.setOp(Keep, Keep, Zero);
		stencilClear.pass.stencil = clearStencil;

		stencilDarken = new ScreenFx(new StencilScreenShader());
		darkenColor = stencilDarken.shader;
		darkenColor.color.setColor(0x000026);
		darkenColor.color.w = 0.35;
		stencilDarken.pass.depth(false, Always);
		stencilDarken.pass.culling = None;
		stencilDarken.pass.setColorMask(true, true, true, true);
		stencilDarken.pass.blend(SrcAlpha, OneMinusSrcAlpha);
		var darkenStencil = new Stencil();
		darkenStencil.setFunc(NotEqual, 0, 0xFF, 0xFF);
		darkenStencil.setOp(Keep, Keep, Zero);
		stencilDarken.pass.stencil = darkenStencil;
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

		if (Settings.optionsSettings.shadows) {
			stencilClear.render();
			renderPass(defaultPass, get("interiorShadowVolume"));
			stencilDarken.render();
		}

		renderPass(defaultPass, get("shadowPass1"));
		renderPass(defaultPass, get("shadowPass2"));
		renderPass(defaultPass, get("shadowPass3"));
		renderPass(defaultPass, get("marble"));
		renderPass(defaultPass, get("alpha"), backToFront);
		renderPass(defaultPass, get("additive"));
	}
}

private class StencilScreenShader extends ScreenShader {
	static var SRC = {
		@param var color:Vec4;
		function __init__() {
			// ScreenShader itself writes output.color from pixelColor; make
			// sure it is initialized here instead of using FixedColor.
			pixelColor = color;
			output.color = color;
		}
	};
}
