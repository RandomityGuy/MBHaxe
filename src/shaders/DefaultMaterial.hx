package shaders;

class DefaultMaterial extends hxsl.Shader {
	static var SRC = {
		@param var diffuseMap:Sampler2D;
		@param var specularColor:Vec4;
		@param var normalMap:Sampler2D;
		@param var shininess:Float;
		@param var secondaryMapUvFactor:Float;
		@global var camera:{
			var position:Vec3;
			@var var dir:Vec3;
		};
		@global var global:{
			@perObject var modelView:Mat4;
			@perObject var modelViewInverse:Mat4;
			@perObject var modelViewTranspose:Mat4;
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
		@var var outLightVec:Vec4;
		@var var outPos:Vec3;
		@var var outEyePos:Vec3;
		@const var isHalfTile:Bool;
		@const var doGammaRamp:Bool;
		function lambert(normal:Vec3, lightPosition:Vec3):Float {
			var result = dot(normal, lightPosition);
			return saturate(result);
		}
		function transposeMat3(m:Mat3):Mat3 {
			return mat3(vec3(m[0].x, m[1].x, m[2].x), vec3(m[0].y, m[1].y, m[2].y), vec3(m[0].z, m[1].z, m[2].z));
		}
		function vertex() {
			calculatedUV = input.uv;
			if (isHalfTile) {
				calculatedUV *= 0.5;
			}
			var objToTangentSpace = mat3(input.t, input.b, input.n);
			outLightVec = vec4(0);
			var inLightVec = vec3(-0.5732, 0.27536, -0.77176) * mat3(global.modelViewTranspose);
			// inLightVec.x *= -1;
			var eyePos = camera.position * mat3x4(global.modelViewInverse);
			// eyePos.x *= -1;
			// eyePos /= vec3(global.modelViewInverse[0].x, global.modelViewInverse[1].y, global.modelViewInverse[2].z);
			outLightVec.xyz = -inLightVec * objToTangentSpace;
			var p = input.position;
			// p.x *= -1;
			outPos = (p / 100.0) * objToTangentSpace;
			outEyePos = (eyePos / 100.0) * objToTangentSpace;
			var pN = input.normal;
			// pN.x *= -1;
			outLightVec.w = isHalfTile ? step(0, dot(pN, -inLightVec)) : step(-0.5, dot(pN, -inLightVec));
		}
		function fragment() {
			var bumpNormal = normalMap.get(calculatedUV * secondaryMapUvFactor).xyz * 2 - 1;
			var bumpDot = isHalfTile ? saturate(dot(bumpNormal, outLightVec.xyz)) : ((dot(bumpNormal, outLightVec.xyz) + 1) * 0.5);
			// Diffuse part
			var diffuse = diffuseMap.get(calculatedUV);
			var ambient = vec4(0.472, 0.424, 0.475, 1.00);

			var outCol = diffuse;
			var shading = vec4(1.08, 1.03, 0.90, 1);
			if (isHalfTile) {
				outCol = shading * diffuse * (bumpDot + ambient);
			} else {
				outCol *= (shading * bumpDot) + ambient;
			}

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

	public function new(diffuse, normal, shininess, specularColor, secondaryMapUvFactor, isHalfTile = false) {
		super();
		this.diffuseMap = diffuse;
		this.normalMap = normal;
		this.shininess = shininess;
		this.specularColor = specularColor;
		this.secondaryMapUvFactor = secondaryMapUvFactor;
		this.isHalfTile = isHalfTile;
		this.doGammaRamp = true;
	}
}
