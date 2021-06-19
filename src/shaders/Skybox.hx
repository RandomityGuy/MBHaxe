package shaders;

class Skybox extends hxsl.Shader {
	static var SRC = {
		var pixelColor:Vec4;
		var transformedNormal:Vec3;
		var transformedPosition:Vec3;
		@param var texture:SamplerCube;
		@global var camera:{
			var position:Vec3;
			var viewProj:Mat4;
			var view:Mat4;
			var proj:Mat4;
		};
		function vertex() {
			transformedNormal = transformedPosition - camera.position;
		}
		function fragment() {
			pixelColor.rgb = texture.get(normalize(transformedNormal)).rgb;
		}
	}

	public function new(texture) {
		super();
		this.texture = texture;
	}
}
