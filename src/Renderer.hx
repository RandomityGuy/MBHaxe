package src;

import hxd.Window;
import src.ResourceLoader;
import shaders.GammaRamp;
import h3d.mat.Texture;
import h3d.Vector;
import shaders.Blur;
import h3d.pass.ScreenFx;
import h3d.mat.DepthBuffer;

class Renderer extends h3d.scene.Renderer {
	var def(get, never):h3d.pass.Base;

	public var depth:h3d.pass.Base = new h3d.scene.fwd.Renderer.DepthPass();
	public var normal:h3d.pass.Base = new h3d.scene.fwd.Renderer.NormalPass();
	public var shadow = new h3d.pass.DefaultShadowMap(1024);

	var glowBuffer:h3d.mat.Texture;

	static var sfxBuffer:h3d.mat.Texture;

	var curentBackBuffer = 0;
	var blurShader:ScreenFx<Blur>;
	var growBufferTemps:Array<h3d.mat.Texture>;
	var copyPass:h3d.pass.Copy;
	var backBuffer:h3d.mat.Texture;

	public function new() {
		super();
		defaultPass = new h3d.pass.Default("default");
		allPasses = [defaultPass, depth, normal, shadow];
		blurShader = new ScreenFx<Blur>(new Blur());
		copyPass = new h3d.pass.Copy();
		sfxBuffer = new Texture(512, 512, [Target]);
		Window.getInstance().addResizeEvent(() -> onResize());
	}

	public inline static function getSfxBuffer() {
		return sfxBuffer;
	}

	inline function get_def()
		return defaultPass;

	// can be overriden for benchmark purposes
	function renderPass(p:h3d.pass.Base, passes, ?sort) {
		p.draw(passes, sort);
	}

	function onResize() {
		if (backBuffer != null) {
			backBuffer.dispose();
			backBuffer = null;
		}
		if (glowBuffer != null) {
			glowBuffer.dispose();
			glowBuffer = null;
		}
	}

	override function getPassByName(name:String):h3d.pass.Base {
		if (name == "alpha"
			|| name == "additive"
			|| name == "glowPre"
			|| name == "glow"
			|| name == "refract"
			|| name == "glowPreNoRender")
			return defaultPass;
		return super.getPassByName(name);
	}

	override function render() {
		if (backBuffer == null) {
			backBuffer = ctx.textures.allocTarget("backBuffer", ctx.engine.width, ctx.engine.height);
		}
		ctx.engine.pushTarget(backBuffer);
		ctx.engine.clear(0, 1);

		if (has("shadow"))
			renderPass(shadow, get("shadow"));

		if (has("depth"))
			renderPass(depth, get("depth"));

		if (has("normal"))
			renderPass(normal, get("normal"));

		if (glowBuffer == null)
			glowBuffer = ctx.textures.allocTarget("glowBuffer", ctx.engine.width, ctx.engine.height);
		if (growBufferTemps == null) {
			growBufferTemps = [
				ctx.textures.allocTarget("gb1", 320, 320, false),
				ctx.textures.allocTarget("gb2", 320, 320, false),
			];
		}
		// ctx.engine.pushTarget(backBuffers[0]);
		// ctx.engine.clear(0, 1);

		renderPass(defaultPass, get("sky"));
		renderPass(defaultPass, get("skyshape"), backToFront);
		renderPass(defaultPass, get("default"));
		renderPass(defaultPass, get("glowPre"));

		// Glow pass
		var glowObjects = get("glow");
		if (!glowObjects.isEmpty()) {
			ctx.engine.pushTarget(glowBuffer);
			ctx.engine.clear(0);
			renderPass(defaultPass, glowObjects);
			bloomPass(ctx);
			ctx.engine.popTarget();
			copyPass.shader.texture = growBufferTemps[0];
			copyPass.pass.blend(One, One);
			copyPass.pass.depth(false, Always);
			copyPass.render();
		}
		// Refraction pass
		var refractObjects = get("refract");
		if (!refractObjects.isEmpty()) {
			h3d.pass.Copy.run(backBuffer, sfxBuffer);
			renderPass(defaultPass, refractObjects);
		}

		renderPass(defaultPass, get("alpha"), backToFront);
		renderPass(defaultPass, get("additive"));

		ctx.engine.popTarget();

		copyPass.pass.blend(One, Zero);
		copyPass.shader.texture = backBuffer;
		copyPass.render();

		// h3d.pass.Copy.run(backBuffers[0], backBuffers[1]);
		// renderPass(defaultPass, get("refract"));
		// ctx.engine.popTarget();
		// h3d.pass.Copy.run(backBuffers[0], null);

		// curentBackBuffer = 1 - curentBackBuffer;
	}

	function bloomPass(ctx:h3d.scene.RenderContext) {
		h3d.pass.Copy.run(glowBuffer, growBufferTemps[0]);

		var offsets = [-7.5, -6.25, -5, -3.75, -2.5, -1.25, 0, 1.25, 2.5, 3.75, 5, 6.25, 7.5];
		var divisors = [0.1, 0.3, 0.4, 0.5, 0.6, 0.7, 1.0, 0.7, 0.5, 0.5, 0.4, 0.3, 0.1];

		var divisor = 0.0;

		var kernel = [];
		for (i in 0...13) {
			kernel.push(new Vector(offsets[i] / 320, 0, divisors[i]));
			divisor += divisors[i];
		}

		blurShader.shader.kernel = kernel;
		blurShader.shader.divisor = divisor;
		blurShader.shader.texture = growBufferTemps[0];
		ctx.engine.pushTarget(growBufferTemps[1]);
		ctx.engine.clear(0, 1);
		blurShader.render();
		ctx.engine.popTarget();

		for (i in 0...13) {
			kernel[i].set(0, offsets[i] / 320, divisors[i]);
		}

		blurShader.shader.kernel = kernel;
		blurShader.shader.divisor = divisor;
		blurShader.shader.texture = growBufferTemps[1];
		ctx.engine.pushTarget(growBufferTemps[0]);
		ctx.engine.clear(0, 1);
		blurShader.render();
		ctx.engine.popTarget();
	}
}
