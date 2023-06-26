package shaders.marble;

class ClassicGlass extends hxsl.Shader {
	static var SRC = {
		@param var diffuseMap:Sampler2D;
		@param var normalMap:Sampler2D;
		@param var envMap:SamplerCube;
		@param var shininess:Float;
		@param var specularColor:Vec4;
		@param var uvScaleFactor:Float;
		@global var camera:{
			var position:Vec3;
			@var var dir:Vec3;
		};
		@global var global:{
			@perObject var modelView:Mat4;
			@perObject var modelViewInverse:Mat4;
		};
		@input var input:{
			var normal:Vec3;
			var t:Vec3;
			var uv:Vec2;
		};
		var calculatedUV:Vec2;
		var pixelColor:Vec4;
		var specColor:Vec3;
		var specPower:Float;
		var transformedPosition:Vec3;
		var transformedNormal:Vec3;
		var pixelTransformedPosition:Vec3;
		@var var transformedTangent:Vec4;
		@var var fragLightW:Float;
		@var var cubeEyePos:Vec3;
		function lambert(normal:Vec3, lightPosition:Vec3):Float {
			var result = dot(normal, lightPosition);
			return saturate(result);
		}
		function transposeMat3(m:Mat3):Mat3 {
			return mat3(vec3(m[0].x, m[1].x, m[2].x), vec3(m[0].y, m[1].y, m[2].y), vec3(m[0].z, m[1].z, m[2].z));
		}
		function __init__vertex() {
			transformedTangent = vec4(input.t * global.modelView.mat3(), input.t.dot(input.t) > 0.5 ? 1. : -1.);
		}
		function vertex() {
			calculatedUV = input.uv * uvScaleFactor;
			var dirLight = vec3(-0.5732, 0.27536, -0.77176);
			fragLightW = step(-0.5, dot(dirLight, input.normal));

			var cubeTrans = mat3(global.modelView);
			cubeEyePos = camera.position - global.modelView[3].xyz;
			cubeEyePos.x *= -1;
			cubeEyePos = cubeEyePos.normalize();
		}
		function fragment() {
			// Diffuse part
			var texColor = diffuseMap.get(calculatedUV);
			var bumpColor = normalMap.get(calculatedUV);

			var norm = normalize(bumpColor * 2 - 1).xyz;

			var dirLight = vec4(1.08, 1.03, 0.90, 1);
			var dirLightDir = vec3(-0.5732, 0.27536, -0.77176);

			// Normal
			var n = transformedNormal;
			var nf = normalize(bumpColor.xyz * 2 - 1);
			var tanX = transformedTangent.xyz.normalize();
			var tanY = n.cross(tanX) * transformedTangent.w;
			transformedNormal = (nf.x * tanX + nf.y * tanY + nf.z * n).normalize();

			var diffuse = dirLight * (dot(norm, -dirLightDir) + 1.3) * 0.5;

			// Specular
			var eyeVec = (camera.position - transformedPosition).normalize();
			var halfAng = (eyeVec - dirLightDir).normalize();
			var specValue = saturate(norm.dot(halfAng)) * fragLightW;
			var specular = specularColor * pow(specValue, shininess);

			var viewDir = normalize(camera.position - pixelTransformedPosition);

			norm = (norm * mat3(global.modelView)).normalize();

			// Fresnel
			var fresnelBias = 0.0;
			var fresnelPow = 1.2;
			var fresnelScale = 1.0;
			var fresnelTerm = fresnelBias + fresnelScale * (1.0 - fresnelBias) * pow(1.0 - max(dot(viewDir, norm), 0.0), fresnelPow);

			var reflectVec = 2 * norm.dot(cubeEyePos) * norm - cubeEyePos * norm.dot(norm);
			var incidentRay = normalize(pixelTransformedPosition - camera.position);
			var reflectionRay = reflect(incidentRay, transformedNormal).normalize();

			var reflectColor = envMap.get(reflectionRay);

			var outCol = mix(texColor * 1.2, reflectColor, fresnelTerm);
			outCol *= diffuse;
			outCol += specular * bumpColor.a;

			pixelColor = outCol;
		}
	}

	public function new(diffuse, normal, skybox, shininess, specularVal, uvScaleFactor) {
		super();
		this.diffuseMap = diffuse;
		this.normalMap = normal;
		this.envMap = skybox;
		this.shininess = shininess;
		this.specularColor = specularVal;
		this.uvScaleFactor = uvScaleFactor;
	}
}
