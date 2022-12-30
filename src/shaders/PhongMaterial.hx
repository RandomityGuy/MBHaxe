package shaders;

class PhongMaterial extends hxsl.Shader {
	static var SRC = {
		@param var diffuseMap:Sampler2D;
		@param var normalMap:Sampler2D;
		@param var shininess:Float;
		@param var specularColor:Vec4;
		@param var ambientLight:Vec3;
		@param var dirLight:Vec3;
		@param var dirLightDir:Vec3;
		@param var uvScaleFactor:Float;
		@const var isHalfTile:Bool = false;
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
		@var var fragLightW:Float;
		function __init__vertex() {
			transformedTangent = vec4(input.tangent * global.modelView.mat3(), input.tangent.dot(input.tangent) > 0.5 ? 1. : -1.);
		}
		function lambert(normal:Vec3, lightPosition:Vec3):Float {
			var result = isHalfTile ? dot(normal, lightPosition) : ((dot(normal, lightPosition) + 1) * 0.5);
			return result;
		}
		function vertex() {
			calculatedUV = input.uv * uvScaleFactor;
			fragLightW = step(0, dot(dirLight, input.normal));
		}
		function fragment() {
			// Diffuse part
			var diffuse = diffuseMap.get(calculatedUV);
			var outCol = diffuse;

			var n = transformedNormal;
			var nf = unpackNormal(normalMap.get(calculatedUV));
			var tanX = transformedTangent.xyz.normalize();
			var tanY = n.cross(tanX) * transformedTangent.w;
			transformedNormal = (nf.x * tanX + nf.y * tanY + nf.z * n).normalize();

			var bumpDot = dirLight * lambert(transformedNormal, -dirLightDir);
			outCol.xyz *= bumpDot + ambientLight;

			var eyeVec = (camera.position - transformedPosition).normalize();
			var halfAng = (eyeVec - dirLightDir).normalize();
			var specValue = saturate(transformedNormal.dot(halfAng)) * fragLightW;
			var specular = specularColor * pow(specValue, shininess);

			outCol += specular * diffuse.a;

			pixelColor = outCol;
		}
	}

	public function new(diffuse, normal, shininess, specularVal, ambientLight, dirLight, dirLightDir, uvScaleFactor) {
		super();
		this.diffuseMap = diffuse;
		this.normalMap = normal;
		this.shininess = shininess;
		this.specularColor = specularVal;
		this.ambientLight = ambientLight.clone();
		this.dirLight = dirLight.clone();
		this.dirLightDir = dirLightDir.clone();
		this.uvScaleFactor = uvScaleFactor;
	}
}
