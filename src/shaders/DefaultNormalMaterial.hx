package shaders;

class DefaultNormalMaterial extends hxsl.Shader {
	static var SRC = {
		@param var diffuseMap:Sampler2D;
		@param var specularColor:Vec4;
		@param var shininess:Float;
		@param var secondaryMapUvFactor:Float;
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
		var specColor:Vec3;
		var specPower:Float;
		@var var outShading:Vec4;
		@var var outLightVec:Vec4;
		@var var outEyePos:Vec3;
		function lambert(normal:Vec3, lightPosition:Vec3):Float {
			var result = dot(normal, lightPosition);
			return saturate(result);
		}
		function vertex() {
			calculatedUV = input.uv;
			outLightVec = vec4(0);
			var inLightVec = vec3(-0.5732, 0.27536, -0.77176) * mat3(global.modelViewInverse);
			var eyePos = camera.position * mat3x4(global.modelViewInverse);
			eyePos /= vec3(global.modelViewInverse[0].x, global.modelViewInverse[1].y, global.modelViewInverse[2].z);
			outLightVec.xyz = -inLightVec;
			outLightVec.w = step(-0.5, dot(input.normal, -inLightVec));
			outEyePos = eyePos;
			outShading = vec4(saturate(dot(-inLightVec, input.normal)));
			outShading.w = 1;
			outShading *= vec4(1.08, 1.03, 0.90, 1);
		}
		function fragment() {
			// Diffuse part
			var diffuse = diffuseMap.get(calculatedUV);
			var ambient = vec4(0.472, 0.424, 0.475, 1.00);

			var outCol = (outShading + ambient) * diffuse;

			var eyeVec = (outEyePos - input.position).normalize();
			var halfAng = (eyeVec + outLightVec.xyz).normalize();
			var specValue = saturate(input.normal.dot(halfAng)) * outLightVec.w;
			var specular = specularColor * pow(specValue, shininess);

			outCol.a = 1;
			outCol += specular * diffuse.a;

			// Gamma correction using our regression model
			var a = 1.00759;
			var b = 1.18764;
			outCol.x = a * pow(outCol.x, b);
			outCol.y = a * pow(outCol.y, b);
			outCol.z = a * pow(outCol.z, b);

			pixelColor = outCol;
		}
	}

	public function new(diffuse, shininess, specularColor, secondaryMapUvFactor) {
		super();
		this.diffuseMap = diffuse;
		this.shininess = shininess;
		this.specularColor = specularColor;
		this.secondaryMapUvFactor = secondaryMapUvFactor;
	}
}
