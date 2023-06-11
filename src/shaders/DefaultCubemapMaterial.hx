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
		function lambert(normal:Vec3, lightPosition:Vec3):Float {
			var result = dot(normal, lightPosition);
			return saturate(result);
		}
		function vertex() {
			var eyePos = camera.position * mat3x4(global.modelViewInverse);
			// eyePos /= vec3(global.modelViewInverse[0].x, global.modelViewInverse[1].y, global.modelViewInverse[2].z);
			var cubeTrans = mat3(global.modelView);
			var cubeEyePos = camera.position - global.modelView[3].xyz;

			calculatedUV = input.uv;

			var objToTangentSpace = mat3(input.t, input.b, input.n);
			outLightVec = vec4(0);

			var inLightVec = vec3(-0.5732, 0.27536, -0.77176) * mat3(global.modelViewInverse);
			outLightVec.xyz = -inLightVec * objToTangentSpace;
			// var cubeVertPos = input.position * cubeTrans;
			// var cubeNormal = input.normal * cubeTrans;
			// var eyeToVert = (cubeVertPos - cubeEyePos).normalize();
			// outReflectVec = reflect(eyeToVert, cubeNormal);
			outPos = (input.position / 100.0) * objToTangentSpace;
			outEyePos = (eyePos / 100.0) * objToTangentSpace;
			outLightVec.w = step(-0.5, dot(input.normal, -inLightVec));
		}
		function fragment() {
			var ambient = vec4(0.472, 0.424, 0.475, 1.00);
			var shading = vec4(1.08, 1.03, 0.90, 1);

			var diffuse = diffuseMap.get(calculatedUV);
			var outCol = diffuse;
			var bumpNormal = unpackNormal(normalMap.get(calculatedUV * secondaryMapUvFactor));

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
