package src;

import hxd.Key;
import shaders.RendererDefaultPass;
import hxd.Window;
import src.ResourceLoader;
import shaders.GammaRamp;
import h3d.mat.Texture;
import h3d.Vector;
import shaders.Blur;
import h3d.pass.ScreenFx;
import h3d.mat.DepthBuffer;
import src.ProfilerUI;
import src.Settings;

class Renderer extends h3d.scene.Renderer {
	var def(get, never):h3d.pass.Base;

	public var depth:h3d.pass.Base = new h3d.scene.fwd.Renderer.DepthPass();
	public var normal:h3d.pass.Base = new h3d.scene.fwd.Renderer.NormalPass();
	public var shadow = new h3d.pass.DefaultShadowMap(1);

	var glowBuffer:h3d.mat.Texture;

	static var sfxBuffer:h3d.mat.Texture;

	var curentBackBuffer = 0;
	var blurShader:ScreenFx<Blur>;
	var growBufferTemps:Array<h3d.mat.Texture>;
	var copyPass:h3d.pass.Copy;
	var backBuffer:h3d.mat.Texture;

	public static var dirtyBuffers:Bool = true;

	var depthBuffer:DepthBuffer;

	static var pixelRatio:Float = 1;

	public static var cubemapPass:Bool = false;

	public function new() {
		super();
		defaultPass = new RendererDefaultPass("default");
		allPasses = [defaultPass, depth, normal, shadow];
		blurShader = new ScreenFx<Blur>(new Blur());
		copyPass = new h3d.pass.Copy();
		sfxBuffer = new Texture(512, 512, [Target]);
		Window.getInstance().addResizeEvent(() -> onResize());
		shadow.autoShrink = false;
		shadow.power = 0;
		shadow.mode = Static;
		shadow.minDist = 0.1;
		shadow.maxDist = 0.1;
		shadow.bias = 0;
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
		if (depthBuffer != null) {
			depthBuffer.dispose();
			depthBuffer = null;
		}
		pixelRatio = 1;
		pixelRatio = Window.getInstance().windowToPixelRatio / Math.min(Settings.optionsSettings.maxPixelRatio, Window.getInstance().windowToPixelRatio);
	}

	override function getPassByName(name:String):h3d.pass.Base {
		if (name == "alpha" || name == "additive" || name == "glowPre" || name == "glow" || name == "refract" || name == "glowPreNoRender"
			|| name == "interior" || name == "zPass" || name == "marble" || name == "shadowPass1" || name == "shadowPass2" || name == "shadowPass3")
			return defaultPass;
		return super.getPassByName(name);
	}

	override function render() {
		if (backBuffer == null) {
			depthBuffer = new DepthBuffer(cast ctx.engine.width / pixelRatio, cast ctx.engine.height / pixelRatio, Depth24);
			if (depthBuffer.format != Depth24) {
				depthBuffer.dispose();
				depthBuffer = new DepthBuffer(cast ctx.engine.width / pixelRatio, cast ctx.engine.height / pixelRatio, Depth24);
			}
			backBuffer = ctx.textures.allocTarget("backBuffer", cast ctx.engine.width / pixelRatio, cast ctx.engine.height / pixelRatio, false);
			backBuffer.depthBuffer = depthBuffer;
		}
		if (!cubemapPass) { // we push the target separately
			ctx.engine.pushTarget(backBuffer);
		}
		ctx.engine.clear(0, 1, 0);

		if (has("shadow"))
			renderPass(shadow, get("shadow"));

		if (has("depth"))
			renderPass(depth, get("depth"));

		if (has("normal"))
			renderPass(normal, get("normal"));

		if (glowBuffer == null) {
			glowBuffer = ctx.textures.allocTarget("glowBuffer", cast ctx.engine.width / pixelRatio, cast ctx.engine.height / pixelRatio);
			glowBuffer.depthBuffer = depthBuffer;
		}
		if (growBufferTemps == null) {
			growBufferTemps = [
				ctx.textures.allocTarget("gb1", 320, 320, false),
				ctx.textures.allocTarget("gb2", 320, 320, false),
			];
		}
		// ctx.engine.pushTarget(backBuffers[0]);
		// ctx.engine.clear(0, 1);

		if (!cubemapPass)
			ProfilerUI.measure("sky", 0);
		if (!cubemapPass || Settings.optionsSettings.reflectionDetail >= 1) {
			renderPass(defaultPass, get("sky"));
			renderPass(defaultPass, get("skyshape"), backToFront);
		}
		if (!cubemapPass || Settings.optionsSettings.reflectionDetail >= 2) {
			// if (!cubemapPass)
			// 	ProfilerUI.measure("interiorZPass", 0);
			// renderPass(defaultPass, get("zPass"));
			if (!cubemapPass)
				ProfilerUI.measure("interior", 0);
			renderPass(defaultPass, get("interior"));
		}
		if (!cubemapPass)
			ProfilerUI.measure("render", 0);
		if (!cubemapPass || Settings.optionsSettings.reflectionDetail >= 3) {
			renderPass(defaultPass, get("default"));
		}

		renderPass(defaultPass, get("shadowPass1"));
		renderPass(defaultPass, get("shadowPass2"));
		renderPass(defaultPass, get("shadowPass3"));
		renderPass(defaultPass, get("marble"));

		if (!cubemapPass)
			ProfilerUI.measure("glow", 0);
		if (!cubemapPass || Settings.optionsSettings.reflectionDetail >= 4)
			renderPass(defaultPass, get("glowPre"));

		// Glow pass
		if (!cubemapPass || Settings.optionsSettings.reflectionDetail >= 4) {
			var glowObjects = get("glow");
			if (!glowObjects.isEmpty()) {
				if (dirtyBuffers) {
					ctx.engine.pushTarget(glowBuffer);
					ctx.engine.clear(0);
					renderPass(defaultPass, glowObjects);
					bloomPass(ctx);
					ctx.engine.popTarget();
				}
				copyPass.shader.texture = growBufferTemps[0];
				copyPass.pass.blend(One, One);
				copyPass.pass.depth(false, Always);
				copyPass.render();
			}
		}
		if (!cubemapPass)
			ProfilerUI.measure("refract", 0);
		// Refraction pass
		if (!cubemapPass || Settings.optionsSettings.reflectionDetail >= 4) {
			var refractObjects = get("refract");
			if (!refractObjects.isEmpty()) {
				if (dirtyBuffers) {
					h3d.pass.Copy.run(backBuffer, sfxBuffer);
				}
				renderPass(defaultPass, refractObjects);
			}
		}
		if (!cubemapPass)
			ProfilerUI.measure("alpha", 0);

		if (!cubemapPass || Settings.optionsSettings.reflectionDetail >= 4) {
			renderPass(defaultPass, get("alpha"), backToFront);
			renderPass(defaultPass, get("additive"));
		}

		if (!cubemapPass && dirtyBuffers)
			dirtyBuffers = false;

		if (!cubemapPass)
			ctx.engine.popTarget();

		if (!cubemapPass) {
			copyPass.pass.blend(One, Zero);
			copyPass.shader.texture = backBuffer;
			copyPass.render();
		}

		if (!cubemapPass) {
			#if sys
			if (Key.isDown(Key.CTRL) && Key.isPressed(Key.P)) {
				var pixels = backBuffer.capturePixels();
				var filename = StringTools.replace('Screenshot ${Date.now().toString()}.png', ":", ".");
				var pixdata = pixels.toPNG();
				hxd.File.createDirectory("data/screenshots");
				hxd.File.saveBytes("data/screenshots/" + filename, pixdata);
			}
			#end
		}

		// h3d.pass.Copy.run(backBuffers[0], backBuffers[1]);
		// renderPass(defaultPass, get("refract"));
		// ctx.engine.popTarget();
		// h3d.pass.Copy.run(backBuffers[0], null);

		// curentBackBuffer = 1 - curentBackBuffer;
	}

	function bloomPass(ctx:h3d.scene.RenderContext) {
		h3d.pass.Copy.run(glowBuffer, growBufferTemps[0]);

		static var offsets = [-7.5, -6.25, -5, -3.75, -2.5, -1.25, 0, 1.25, 2.5, 3.75, 5, 6.25, 7.5];
		static var divisors = [0.1, 0.3, 0.4, 0.5, 0.6, 0.7, 1.0, 0.7, 0.5, 0.5, 0.4, 0.3, 0.1];

		static var divisor = 0.0;
		static var kernelX = [];
		static var kernelY = [];
		static var kernelComputed = false;
		if (!kernelComputed) {
			for (i in 0...13) {
				kernelX.push(new Vector(offsets[i] / 320, 0, divisors[i]));
				divisor += divisors[i];
			}
			for (i in 0...13) {
				kernelY.push(new Vector(0, offsets[i] / 320, divisors[i]));
			}
			kernelComputed = true;
		}

		blurShader.shader.kernel = kernelX;
		blurShader.shader.divisor = divisor;
		blurShader.shader.texture = growBufferTemps[0];
		ctx.engine.pushTarget(growBufferTemps[1]);
		ctx.engine.clear(0, 1);
		blurShader.render();
		ctx.engine.popTarget();

		blurShader.shader.kernel = kernelY;
		blurShader.shader.divisor = divisor;
		blurShader.shader.texture = growBufferTemps[1];
		ctx.engine.pushTarget(growBufferTemps[0]);
		ctx.engine.clear(0, 1);
		blurShader.render();
		ctx.engine.popTarget();
	}
}
