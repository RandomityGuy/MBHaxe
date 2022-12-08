package shaders;

class PhongMaterial extends hxsl.Shader {
	static var SRC = {
		@param var diffuseMap:Sampler2D;
		@param var specularMap:Sampler2D;
		@param var normalMap:Sampler2D;
		@param var shininess:Float;
		@param var specularIntensity:Float;
		@param var ambientLight:Vec3;
		@param var dirLight:Vec3;
		@param var dirLightDir:Vec3;
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
		function lambert(normal:Vec3, lightPosition:Vec3):Float {
			var result = dot(normal, lightPosition);
			return max(result, 0.0);
		}
		function vertex() {
			calculatedUV = input.uv;
		}
		function fragment() {
			// Diffuse part
			var diffuse = diffuseMap.get(calculatedUV);

			var incomingLight = vec3(0.0);
			var specularLight = vec3(0.0);

			incomingLight += ambientLight;
			var n = transformedNormal;
			var nf = unpackNormal(normalMap.get(calculatedUV * secondaryMapUvFactor));
			var tanX = transformedTangent.xyz.normalize();
			var tanY = n.cross(tanX) * -transformedTangent.w;
			transformedNormal = (nf.x * tanX + nf.y * tanY + nf.z * n).normalize();

			var addedLight = dirLight * lambert(transformedNormal, -dirLightDir);
			incomingLight += addedLight;

			var viewDir = normalize(camera.position - transformedPosition.xyz);
			var halfwayDir = normalize(-dirLightDir + camera.dir); // Blinn-Phong

			var spec = pow(max(dot(transformedNormal, halfwayDir), 0.0), shininess);

			spec *= specularMap.get(secondaryMapUvFactor * calculatedUV).r;

			specularLight += vec3(specularIntensity * spec);

			var shaded = diffuse * vec4(incomingLight, 1);
			shaded.rgb += specularLight;

			pixelColor = shaded;
		}
	}

	public function new(diffuse, specular, normal, shininess, specularIntensity, ambientLight, dirLight, dirLightDir, secondaryMapUvFactor) {
		super();
		this.diffuseMap = diffuse;
		this.specularMap = specular;
		this.normalMap = normal;
		this.shininess = shininess;
		this.specularIntensity = specularIntensity;
		this.ambientLight = ambientLight.clone();
		this.dirLight = dirLight.clone();
		this.dirLightDir = dirLightDir.clone();
		this.secondaryMapUvFactor = secondaryMapUvFactor;
	}
}
