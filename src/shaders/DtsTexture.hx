package shaders;

class DtsTexture extends hxsl.Shader {
	static var SRC = {
		@input var input:{
			var uv:Vec2;
			var normal:Vec3;
		};
		@global var global:{
			@perObject var modelView:Mat4;
		};
		@const var additive:Bool;
		@const var killAlpha:Bool;
		@const var specularAlpha:Bool;
		@range(0, 1) @param var killAlphaThreshold:Float;
		@param var texture:Sampler2D;
		@const var normalizeNormals:Bool;
		@perInstance @param var currentOpacity:Float;
		var calculatedUV:Vec2;
		var pixelColor:Vec4;
		var specColor:Vec3;
		var transformedNormal:Vec3;
		function vertex() {
			calculatedUV = input.uv;
			transformedNormal = (input.normal * global.modelView.mat3());
			if (normalizeNormals) {
				var normalizednorm = transformedNormal.normalize();
				transformedNormal = transformedNormal / (transformedNormal.x * transformedNormal.x + transformedNormal.y * transformedNormal.y
					+ transformedNormal.z * transformedNormal.z);
			}
		}
		function fragment() {
			var c = texture.get(calculatedUV);
			if (killAlpha && c.a - killAlphaThreshold < 0)
				discard;
			if (additive)
				pixelColor = c;
			else
				pixelColor *= c;
			if (specularAlpha)
				specColor *= c.aaa;
			pixelColor.a *= c.a * currentOpacity;
		}
	}

	public function new(?tex) {
		super();
		this.texture = tex;
		killAlphaThreshold = h3d.mat.Defaults.defaultKillAlphaThreshold;
		normalizeNormals = true;
	}
}
