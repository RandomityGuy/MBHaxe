package shaders;

class DefaultCubemapNormalNoSpecMaterial extends hxsl.Shader {
	static var SRC = {
		@param var diffuseMap:Sampler2D;
		@param var cubeMap:SamplerCube;
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
		var pixelTransformedPosition:Vec3;
		var transformedNormal:Vec3;
		@var var outShading:Vec4;
		@var var outReflectVec:Vec3;
		function lambert(normal:Vec3, lightPosition:Vec3):Float {
			var result = dot(normal, lightPosition);
			return saturate(result);
		}
		function transposeMat3(m:Mat3):Mat3 {
			return mat3(vec3(m[0].x, m[1].x, m[2].x), vec3(m[0].y, m[1].y, m[2].y), vec3(m[0].z, m[1].z, m[2].z));
		}
		function vertex() {
			calculatedUV = input.uv;
			var inLightVec = vec3(-0.5732, 0.27536, -0.77176) * mat3(global.modelViewTranspose);
			// inLightVec.x *= -1;
			var pN = input.normal;
			// pN.x *= -1;
			outShading = vec4(saturate(dot(-inLightVec, pN)));
			outShading.w = 1;
			outShading *= vec4(1.08, 1.03, 0.90, 1);

			// eyePos /= vec3(global.modelViewInverse[0].x, global.modelViewInverse[1].y, global.modelViewInverse[2].z);
			var cubeTrans = mat3(global.modelView);
			var cubeEyePos = camera.position - global.modelView[3].xyz;
			// cubeEyePos.x *= -1;

			var p = input.position;
			// p.x *= -1;

			var cubeVertPos = input.position * cubeTrans;
			var cubeNormal = (input.normal * cubeTrans).normalize();
			var eyeToVert = (cubeVertPos - cubeEyePos);
			outReflectVec = reflect(eyeToVert, cubeNormal);
		}
		function fragment() {
			// Diffuse part
			var diffuse = diffuseMap.get(calculatedUV);
			var ambient = vec4(0.472, 0.424, 0.475, 1.00);

			var outCol = (outShading + ambient) * diffuse;
			var incidentRay = normalize(pixelTransformedPosition - camera.position);
			var reflectionRay = reflect(incidentRay, transformedNormal);
			outCol += diffuse.a * cubeMap.get(outReflectVec);

			pixelColor = outCol;
		}
	}

	public function new(diffuse, secondaryMapUvFactor, skybox) {
		super();
		this.diffuseMap = diffuse;
		this.cubeMap = skybox;
		this.secondaryMapUvFactor = secondaryMapUvFactor;
	}
}
