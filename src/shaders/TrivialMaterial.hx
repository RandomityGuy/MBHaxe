package shaders;

class TrivialMaterial extends hxsl.Shader {
	static var SRC = {
		@param var diffuseMap:Sampler2D;
		@global var global:{
			@perObject var modelView:Mat4;
			@perObject var modelViewInverse:Mat4;
		};
		@input var input:{
			var position:Vec3;
			var normal:Vec3;
			var uv:Vec2;
			var t:Vec3;
			var b:Vec3;
			var n:Vec3;
		};
		var calculatedUV:Vec2;
		var pixelColor:Vec4;
		function vertex() {
			calculatedUV = input.uv;
		}
		function fragment() {
			// Diffuse part
			var diffuse = diffuseMap.get(calculatedUV);
			pixelColor = diffuse * vec4(1.08, 1.03, 0.90, 1);
		}
	}

	public function new(diffuse) {
		super();
		this.diffuseMap = diffuse;
	}
}
