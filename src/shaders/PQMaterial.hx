package shaders;

class PQMaterial extends hxsl.Shader {
	static var SRC = {
		@param var diffuseMap:Sampler2D;
		@param var normalMap:Sampler2D;
		@param var shininess:Float;
		@param var specularMap:Sampler2D;
		@param var ambientLight:Vec3;
		@param var dirLight:Vec3;
		@param var dirLightDir:Vec3;
		@param var secondaryUVMapFactor:Float;
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
		var specColor:Vec3;
		var specPower:Float;
		var transformedPosition:Vec3;
		var transformedNormal:Vec3;
		@var var transformedTangent:Vec4;
		function __init__vertex() {
			transformedTangent = vec4(input.tangent * global.modelView.mat3(), input.tangent.dot(input.tangent) > 0.5 ? 1. : -1.);
		}
		function vertex() {
			calculatedUV = input.uv;
		}
		function fragment() {
			// Diffuse part
			var diffuse = diffuseMap.get(calculatedUV);

			var n = transformedNormal;
			var nf = normalMap.get(calculatedUV * secondaryUVMapFactor) * 2.0 - 1.0;
			var tanX = transformedTangent.xyz.normalize();
			var tanY = n.cross(tanX) * transformedTangent.w;
			transformedNormal = (nf.x * tanX + nf.y * tanY + nf.z * n).normalize();

			var cosTheta = clamp(dot(transformedNormal, -dirLightDir), 0, 1);
			var effectiveSun = dirLight * cosTheta + ambientLight;
			effectiveSun = vec3(clamp(effectiveSun.r, 0, 1), clamp(effectiveSun.g, 0, 1), clamp(effectiveSun.b, 0, 1));

			var outCol = vec4(diffuse.rgb * effectiveSun.rgb, 1);

			var specularColor = specularMap.get(calculatedUV * secondaryUVMapFactor);
			var eyeVec = (camera.position - transformedPosition).normalize();
			var halfAng = (eyeVec - dirLightDir).normalize();
			var specValue = saturate(transformedNormal.dot(halfAng));
			var specular = specularColor * pow(specValue, shininess);

			outCol.rgb += specular.rgb * dirLight;
			outCol.a = 1;

			pixelColor = outCol;
		}
	}

	public function new(diffuse, normal, shininess, specularMap, ambientLight, dirLight, dirLightDir, secondaryFactor = 1.0) {
		super();
		this.diffuseMap = diffuse;
		this.normalMap = normal;
		this.shininess = shininess;
		this.specularMap = specularMap;
		this.ambientLight = ambientLight.clone();
		this.dirLight = dirLight.clone();
		this.dirLightDir = dirLightDir.clone();
		this.secondaryUVMapFactor = secondaryFactor;
	}
}
