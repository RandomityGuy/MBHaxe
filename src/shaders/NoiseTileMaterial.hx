package shaders;

class NoiseTileMaterial extends hxsl.Shader {
	static var SRC = {
		@param var diffuseMap:Sampler2D;
		@param var specularMap:Sampler2D;
		@param var normalMap:Sampler2D;
		@param var noiseMap:Sampler2D;
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

			// noise

			var noiseIndex:Vec2;
			var noiseColor1:Vec4;
			var noiseColor2:Vec4;
			var noiseColor3:Vec4;
			var noiseColor4:Vec4;
			var halfPixel = vec2(1.0 / 64.0, 1.0 / 64.0);

			noiseIndex.x = floor(calculatedUV.x - halfPixel.x) / 63.0 + 0.5 / 64.0;
			noiseIndex.y = floor(calculatedUV.y - halfPixel.y) / 63.0 + 0.5 / 64.0;
			noiseColor1 = noiseMap.get(noiseIndex) * 1.0 - 0.5;

			noiseIndex.x = floor(calculatedUV.x - halfPixel.x) / 63.0 + 0.5 / 64.0;
			noiseIndex.y = floor(calculatedUV.y + halfPixel.y) / 63.0 + 0.5 / 64.0;
			noiseColor2 = noiseMap.get(noiseIndex) * 1.0 - 0.5;

			noiseIndex.x = floor(calculatedUV.x + halfPixel.x) / 63.0 + 0.5 / 64.0;
			noiseIndex.y = floor(calculatedUV.y + halfPixel.y) / 63.0 + 0.5 / 64.0;
			noiseColor3 = noiseMap.get(noiseIndex) * 1.0 - 0.5;

			noiseIndex.x = floor(calculatedUV.x + halfPixel.x) / 63.0 + 0.5 / 64.0;
			noiseIndex.y = floor(calculatedUV.y - halfPixel.y) / 63.0 + 0.5 / 64.0;
			noiseColor4 = noiseMap.get(noiseIndex) * 1.0 - 0.5;

			var finalNoiseCol = (noiseColor1 + noiseColor2 + noiseColor3 + noiseColor4) / 4.0;
			diffuse.rgb *= 1.0 + finalNoiseCol.r; // This isn't how MBU does it afaik but it looks good :o

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

			var r = reflect(dirLightDir, transformedNormal).normalize();
			var specColor = specularMap.get(secondaryMapUvFactor * calculatedUV).r;
			var specValue = r.dot((camera.position - transformedPosition).normalize()).max(0.);
			specularLight += specColor * pow(specValue, shininess) * specularIntensity;

			var shaded = diffuse * vec4(incomingLight, 1);
			shaded.rgb += specularLight;

			pixelColor = shaded;
		}
	}

	public function new(diffuse, specular, normal, noise, shininess, specularIntensity, ambientLight, dirLight, dirLightDir, secondaryMapUvFactor) {
		super();
		this.diffuseMap = diffuse;
		this.specularMap = specular;
		this.normalMap = normal;
		this.noiseMap = noise;
		this.shininess = shininess;
		this.specularIntensity = specularIntensity;
		this.ambientLight = ambientLight.clone();
		this.dirLight = dirLight.clone();
		this.dirLightDir = dirLightDir.clone();
		this.secondaryMapUvFactor = secondaryMapUvFactor;
	}
}
