package shaders;

class DefaultCubemapMaterial extends hxsl.Shader {
	static var SRC = {
		@param var diffuseMap:Sampler2D;
		@param var specularColor:Vec4;
		@param var normalMap:Sampler2D;
		@param var cubeMap:SamplerCube;
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
		var pixelTransformedPosition:Vec3;
		var transformedNormal:Vec3;
		@const var doGammaRamp:Bool;
		// @var var outReflectVec:Vec3;
		@var var outLightVec:Vec4;
		@var var outPos:Vec3;
		@var var outEyePos:Vec3;
		@var var outNormal:Vec3;
		function lambert(normal:Vec3, lightPosition:Vec3):Float {
			var result = dot(normal, lightPosition);
			return saturate(result);
		}
		function transposeMat3(m:Mat3):Mat3 {
			return mat3(vec3(m[0].x, m[1].x, m[2].x), vec3(m[0].y, m[1].y, m[2].y), vec3(m[0].z, m[1].z, m[2].z));
		}
		function vertex() {
			var eyePos = camera.position * mat3x4(global.modelViewInverse);
			eyePos.x *= -1;
			// eyePos /= vec3(global.modelViewInverse[0].x, global.modelViewInverse[1].y, global.modelViewInverse[2].z);
			var cubeTrans = mat3(global.modelView);
			var cubeEyePos = camera.position - global.modelView[3].xyz;
			cubeEyePos.x *= -1;
			calculatedUV = input.uv;

			var objToTangentSpace = mat3(input.t, input.b, input.n);
			outLightVec = vec4(0);

			outNormal = input.normal;
			outNormal.x *= -1;

			var inLightVec = vec3(-0.5732, 0.27536, -0.77176) * transposeMat3(mat3(global.modelView));
			inLightVec.x *= -1;
			outLightVec.xyz = -inLightVec * objToTangentSpace;
			// var cubeVertPos = input.position * cubeTrans;
			// var cubeNormal = input.normal * cubeTrans;
			// var eyeToVert = (cubeVertPos - cubeEyePos).normalize();
			// outReflectVec = reflect(eyeToVert, cubeNormal);
			var p = input.position;
			p.x *= -1;
			outPos = (p / 100.0) * objToTangentSpace;
			outEyePos = (eyePos / 100.0) * objToTangentSpace;
			outLightVec.w = step(-0.5, dot(outNormal, -inLightVec));
		}
		function fragment() {
			var ambient = vec4(0.472, 0.424, 0.475, 1.00);
			var shading = vec4(1.08, 1.03, 0.90, 1);

			var diffuse = diffuseMap.get(calculatedUV);
			var outCol = diffuse;
			var bumpNormal = normalMap.get(calculatedUV * secondaryMapUvFactor).xyz * 2 - 1;
			bumpNormal.y *= -1;

			var incidentRay = normalize(pixelTransformedPosition - camera.position);
			var reflectionRay = reflect(incidentRay, transformedNormal);

			var bumpDot = ((dot(bumpNormal, outLightVec.xyz) + 1) * 0.5);
			outCol *= (shading * bumpDot) + ambient;
			outCol += diffuse.a * cubeMap.get(reflectionRay);

			var eyeVec = (outEyePos - outPos).normalize();
			var halfAng = (eyeVec + outLightVec.xyz).normalize();
			var specValue = saturate(bumpNormal.dot(halfAng)) * outLightVec.w;
			var specular = specularColor * pow(specValue, shininess);

			outCol += specular * diffuse.a;

			// Gamma correction using our regression model
			if (doGammaRamp) {
				var a = 1.00759;
				var b = 1.18764;
				outCol.x = a * pow(outCol.x, b);
				outCol.y = a * pow(outCol.y, b);
				outCol.z = a * pow(outCol.z, b);
			}

			// outCol *= 0.001;
			// outCol += diffuse;
			// outCol *= (shading * bumpDot) + ambient;
			pixelColor = outCol;
		}
	}

	public function new(diffuse, normal, shininess, specularColor, secondaryMapUvFactor, skybox) {
		super();
		this.diffuseMap = diffuse;
		this.cubeMap = skybox;
		this.normalMap = normal;
		this.shininess = shininess;
		this.specularColor = specularColor;
		this.secondaryMapUvFactor = secondaryMapUvFactor;
		this.doGammaRamp = true;
	}
}
