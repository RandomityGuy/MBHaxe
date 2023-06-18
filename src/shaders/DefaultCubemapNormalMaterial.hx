package shaders;

class DefaultCubemapNormalMaterial extends hxsl.Shader {
	static var SRC = {
		@param var diffuseMap:Sampler2D;
		@param var specularColor:Vec4;
		@param var shininess:Float;
		@param var secondaryMapUvFactor:Float;
		@param var cubeMap:SamplerCube;
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
		@const var doGammaRamp:Bool;
		@var var outShading:Vec4;
		@var var outLightVec:Vec4;
		@var var outEyePos:Vec3;
		@var var outReflectVec:Vec3;
		@var var outNormal:Vec3;
		@var var outPos:Vec3;
		function lambert(normal:Vec3, lightPosition:Vec3):Float {
			var result = dot(normal, lightPosition);
			return saturate(result);
		}
		function transposeMat3(m:Mat3):Mat3 {
			return mat3(vec3(m[0].x, m[1].x, m[2].x), vec3(m[0].y, m[1].y, m[2].y), vec3(m[0].z, m[1].z, m[2].z));
		}
		function vertex() {
			calculatedUV = input.uv;
			outLightVec = vec4(0);
			var inLightVec = vec3(-0.5732, 0.27536, -0.77176) * transposeMat3(mat3(global.modelView));
			inLightVec.x *= -1;
			var eyePos = camera.position * mat3x4(global.modelViewInverse);
			eyePos.x *= -1;
			outNormal = input.normal;
			outNormal.x *= -1;
			// eyePos /= vec3(global.modelViewInverse[0].x, global.modelViewInverse[1].y, global.modelViewInverse[2].z);
			outLightVec.xyz = -inLightVec;
			outLightVec.w = step(-0.5, dot(outNormal, -inLightVec));
			outEyePos = eyePos;
			outShading = vec4(saturate(dot(-inLightVec, outNormal)));
			outShading.w = 1;
			outShading *= vec4(1.08, 1.03, 0.90, 1);

			var cubeTrans = mat3(global.modelView);
			var cubeEyePos = camera.position - global.modelView[3].xyz;
			cubeEyePos.x *= -1;

			outPos = input.position;
			outPos.x *= -1;

			var cubeVertPos = input.position * cubeTrans;
			cubeVertPos.x *= -1;
			var cubeNormal = (input.normal * cubeTrans).normalize();
			cubeNormal.x *= -1;
			var eyeToVert = cubeVertPos - cubeEyePos;
			outReflectVec = reflect(eyeToVert, cubeNormal);
		}
		function fragment() {
			// Diffuse part
			var diffuse = diffuseMap.get(calculatedUV);
			var ambient = vec4(0.472, 0.424, 0.475, 1.00);

			var outCol = (outShading + ambient) * diffuse;
			outCol += diffuse.a * cubeMap.get(outReflectVec);

			var eyeVec = (outEyePos - outPos).normalize();
			var halfAng = (eyeVec + outLightVec.xyz).normalize();
			var specValue = saturate(outNormal.dot(halfAng)) * outLightVec.w;
			var specular = specularColor * pow(specValue, shininess);

			outCol.a = 1;
			outCol += specular * diffuse.a;

			// Gamma correction using our regression model
			if (doGammaRamp) {
				var a = 1.00759;
				var b = 1.18764;
				outCol.x = a * pow(outCol.x, b);
				outCol.y = a * pow(outCol.y, b);
				outCol.z = a * pow(outCol.z, b);
			}

			pixelColor = outCol;
		}
	}

	public function new(diffuse, cubeMap, shininess, specularColor, secondaryMapUvFactor) {
		super();
		this.diffuseMap = diffuse;
		this.cubeMap = cubeMap;
		this.shininess = shininess;
		this.specularColor = specularColor;
		this.secondaryMapUvFactor = secondaryMapUvFactor;
		this.doGammaRamp = true;
	}
}
