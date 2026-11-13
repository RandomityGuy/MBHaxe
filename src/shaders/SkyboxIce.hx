package shaders;

class SkyboxIce extends hxsl.Shader {
	static var SRC = {
		@param var diffuseMap:Sampler2D;
		@param var normalMap:Sampler2D;
		@param var specularMap:Sampler2D;
		@param var envMap:SamplerCube;
		@param var shininess:Float;
		@param var reflectivity:Float;
		@param var ambientLight:Vec3;
		@param var dirLight:Vec3;
		@param var dirLightDir:Vec3;
		@param var textureScale:Vec2;
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
			var tangent:Vec3;
			var uv:Vec2;
		};
		var calculatedUV:Vec2;
		var pixelColor:Vec4;
		var transformedPosition:Vec3;
		var transformedNormal:Vec3;
		@var var transformedTangent:Vec4;
		function __init__vertex() {
			transformedTangent = vec4(input.tangent * global.modelView.mat3(), input.tangent.dot(input.tangent) > 0.5 ? 1. : -1.);
		}
		function vertex() {
			calculatedUV = input.uv * textureScale;
		}
		function fragment() {
			// Diffuse + bump-mapped normal, same tangent-space construction as `PQMaterial`.
			var diffuse = diffuseMap.get(calculatedUV);

			var n = transformedNormal;
			var nf = normalMap.get(calculatedUV) * 2.0 - 1.0;
			var tanX = transformedTangent.xyz.normalize();
			var tanY = n.cross(tanX) * transformedTangent.w;
			var bumpNormal = (nf.x * tanX + nf.y * tanY + nf.z * n).normalize();
			transformedNormal = bumpNormal;

			var lightNormal = -dirLightDir;
			var cosTheta = clamp(dot(bumpNormal, lightNormal), 0, 1);
			var effectiveSun = dirLight * cosTheta + ambientLight;
			effectiveSun = vec3(clamp(effectiveSun.r, 0, 1), clamp(effectiveSun.g, 0, 1), clamp(effectiveSun.b, 0, 1));

			var outCol = vec4(diffuse.rgb * effectiveSun.rgb, 1);

			// Skybox reflection
			var eyeVec = (camera.position - transformedPosition).normalize();
			var incidentRay = -eyeVec;
			var reflectionRay = reflect(incidentRay, bumpNormal);
			var reflectionColor = envMap.get(reflectionRay);
			outCol = vec4(outCol.rgb.mix(reflectionColor.rgb, reflectivity), 1);

			// Ice is too dark without a little color added, so we adjust it a bit.
			outCol += vec4(0.2, 0.25, 0.3, 1.0) * cosTheta;

			var specularColor = specularMap.get(calculatedUV);
			var lightReflection = reflect(-lightNormal, bumpNormal);
			var cosAlpha = clamp(dot(eyeVec, lightReflection), 0, 1);
			var specular = specularColor.rgb * dirLight * pow(cosAlpha, shininess);

			outCol.rgb += specular.rgb;
			outCol.a = 1;

			pixelColor = outCol;
		}
	}

	public function new(diffuse, normal, specular, envMap, shininess, reflectivity, ambientLight, dirLight, dirLightDir, textureScale) {
		super();
		this.diffuseMap = diffuse;
		this.normalMap = normal;
		this.specularMap = specular;
		this.envMap = envMap;
		this.shininess = shininess;
		this.reflectivity = reflectivity;
		this.ambientLight = ambientLight.clone();
		this.dirLight = dirLight.clone();
		this.dirLightDir = dirLightDir.clone();
		this.textureScale = textureScale.clone();
	}
}
