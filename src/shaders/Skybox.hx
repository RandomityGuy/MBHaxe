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
		var projNorm:Vec3;
		function vertex() {
			projNorm = transformedPosition - camera.position;
		}
		function fragment() {
			pixelColor.rgba = texture.get(normalize(projNorm)).rgba;
		}
	}

	public function new(texture) {
		super();
		this.texture = texture;
	}
}
