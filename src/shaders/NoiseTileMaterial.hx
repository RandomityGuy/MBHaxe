package shaders;

class NoiseTileMaterial extends hxsl.Shader {
	static var SRC = {
		@param var diffuseMap:Sampler2D;
		@param var specularColor:Vec4;
		@param var normalMap:Sampler2D;
		@param var noiseMap:Sampler2D;
		@param var shininess:Float;
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
			return saturate(result);
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
			var noiseAdd = finalNoiseCol * diffuse.a;

			var outCol = diffuse + noiseAdd;

			var n = transformedNormal;
			var nf = unpackNormal(normalMap.get(calculatedUV * secondaryMapUvFactor));
			var tanX = transformedTangent.xyz.normalize();
			var tanY = n.cross(tanX) * -transformedTangent.w;
			transformedNormal = (nf.x * tanX + nf.y * tanY + nf.z * n).normalize();

			var bumpDot = dirLight * lambert(transformedNormal, -dirLightDir);

			outCol.xyz *= bumpDot * 0.8 + ambientLight;

			var r = reflect(dirLightDir, transformedNormal).normalize();
			var specValue = saturate(r.dot((camera.position - transformedPosition).normalize()));
			var specular = specularColor * pow(specValue, shininess);

			outCol += specular * diffuse.a;
			pixelColor = outCol;
		}
	}

	public function new(diffuse, normal, noise, shininess, specularColor, ambientLight, dirLight, dirLightDir, secondaryMapUvFactor) {
		super();
		this.diffuseMap = diffuse;
		this.normalMap = normal;
		this.noiseMap = noise;
		this.shininess = shininess;
		this.specularColor = specularColor;
		this.ambientLight = ambientLight.clone();
		this.dirLight = dirLight.clone();
		this.dirLightDir = dirLightDir.clone();
		this.secondaryMapUvFactor = secondaryMapUvFactor;
	}
}
