package shaders;

class DtsTexture extends hxsl.Shader {
	static var SRC = {
		@input var input:{
			var uv:Vec2;
		};
		@const var additive:Bool;
		@const var killAlpha:Bool;
		@const var specularAlpha:Bool;
		@range(0, 1) @param var killAlphaThreshold:Float;
		@param var texture:Sampler2D;
		@param var currentOpacity:Float;
		var calculatedUV:Vec2;
		var pixelColor:Vec4;
		var specColor:Vec3;
		function vertex() {
			calculatedUV = input.uv;
		}
		function fragment() {
			var c = texture.get(calculatedUV);
			if (killAlpha && c.a - killAlphaThreshold < 0)
				discard;
			if (additive)
				pixelColor += c;
			else
				pixelColor *= c;
			if (specularAlpha)
				specColor *= c.aaa;
			pixelColor.a *= currentOpacity;
		}
	}

	public function new(?tex) {
		super();
		this.texture = tex;
		killAlphaThreshold = h3d.mat.Defaults.defaultKillAlphaThreshold;
	}
}
