package shaders;

class DefaultDiffuseMaterial extends hxsl.Shader {
	static var SRC = {
		@param var diffuseMap:Sampler2D;
		@global var camera:{
			var position:Vec3;
			@var var dir:Vec3;
		};
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
		@var var outShading:Vec4;
		function vertex() {
			calculatedUV = input.uv;
			var objToTangentSpace = mat3(input.t, input.b, input.n);
			var inLightVec = vec3(-0.5732, 0.27536, -0.77176) * mat3(global.modelViewInverse);
			outShading = vec4(saturate(dot(-inLightVec, input.normal)));
			outShading.w = 1;
			outShading *= vec4(1.08, 1.03, 0.90, 1);
		}
		function fragment() {
			var diffuse = diffuseMap.get(calculatedUV);
			var ambient = vec4(0.472, 0.424, 0.475, 1.00);
			var outCol = outShading + ambient;
			outCol *= diffuse;
			pixelColor = outCol;
		}
	}

	public function new(diffuse) {
		super();
		this.diffuseMap = diffuse;
	}
}
