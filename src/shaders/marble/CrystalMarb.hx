package shaders.marble;

class CrystalMarb extends hxsl.Shader {
	static var SRC = {
		@param var diffuseMap:Sampler2D;
		@param var normalMap:Sampler2D;
		@param var envMap:SamplerCube;
		@param var uvScaleFactor:Float;
		@global var camera:{
			var position:Vec3;
			@var var dir:Vec3;
		};
		@global var global:{
			@perObject var modelView:Mat4;
			@perObject var modelViewTranspose:Mat4;
			@perObject var modelViewInverse:Mat4;
		};
		@input var input:{
			var position:Vec3;
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
		function lambert(normal:Vec3, lightPosition:Vec3):Float {
			var result = dot(normal, lightPosition);
			return saturate(result);
		}
		function transposeMat3(m:Mat3):Mat3 {
			return mat3(vec3(m[0].x, m[1].x, m[2].x), vec3(m[0].y, m[1].y, m[2].y), vec3(m[0].z, m[1].z, m[2].z));
		}
		function refract(incident:Vec3, normal:Vec3, eta:Float):Vec3 {
			var ndoti = dot(normal, incident);
			var k = 1.0 - eta * eta * (1.0 - ndoti * ndoti);
			return k < 0.0 ? vec3(0.0) : eta * incident - (eta * ndoti + sqrt(k)) * normal;
		}
		function __init__vertex() {
			transformedTangent = vec4(input.t * global.modelView.mat3(), input.t.dot(input.t) > 0.5 ? 1. : -1.);
		}
		function vertex() {
			calculatedUV = input.uv * uvScaleFactor;
			var dirLight = vec3(-0.5732, 0.27536, -0.77176);
		}
		function fragment() {
			// Diffuse part
			var texColor = diffuseMap.get(calculatedUV);
			var bumpColor = normalMap.get(calculatedUV);

			var norm = normalize(bumpColor.xyz * 2 - 1);
			norm.x *= -1;

			var viewDir = normalize(camera.position - pixelTransformedPosition);

			norm = (norm * mat3(global.modelView)).normalize();

			// Fresnel
			var fresnelBias = 0.2;
			var fresnelPow = 1.3;
			var fresnelScale = 1.0;
			var fresnelTerm = fresnelBias + fresnelScale * (1.0 - fresnelBias) * pow(1.0 - max(dot(viewDir, norm), 0.0), fresnelPow);

			// var reflectVec = 2 * norm.dot(cubeEyePos) * norm - cubeEyePos * norm.dot(norm);
			var incidentRay = normalize(pixelTransformedPosition - camera.position);
			var reflectionRay = reflect(incidentRay, norm);
			var refractVec = refract(-incidentRay, norm, 1);

			var reflectColor = envMap.get(reflectionRay);
			var refractColor = envMap.get(refractVec);

			var outCol = mix(texColor, vec4(1), 0.25) * mix(refractColor, reflectColor, fresnelTerm);

			pixelColor = outCol;
		}
	}

	public function new(diffuse, normal, skybox, uvScaleFactor) {
		super();
		this.diffuseMap = diffuse;
		this.normalMap = normal;
		this.envMap = skybox;
		this.uvScaleFactor = uvScaleFactor;
	}
}
