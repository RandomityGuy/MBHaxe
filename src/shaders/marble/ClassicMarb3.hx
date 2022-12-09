package shaders.marble;

class ClassicMarb3 extends hxsl.Shader {
	static var SRC = {
		@param var diffuseMap:Sampler2D;
		@param var envMap:SamplerCube;
		@param var shininess:Float;
		@param var specularColor:Vec4;
		@param var ambientLight:Vec3;
		@param var dirLight:Vec3;
		@param var dirLightDir:Vec3;
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
			var uv:Vec2;
		};
		var calculatedUV:Vec2;
		var pixelColor:Vec4;
		var specColor:Vec3;
		var specPower:Float;
		var transformedPosition:Vec3;
		var transformedNormal:Vec3;
		var pixelTransformedPosition:Vec3;
		@var var fragLightW:Float;
		function lambert(normal:Vec3, lightPosition:Vec3):Float {
			var result = dot(normal, lightPosition);
			return saturate(result);
		}
		function vertex() {
			calculatedUV = input.uv * uvScaleFactor;
			fragLightW = step(-0.5, dot(dirLight, input.normal));
		}
		function fragment() {
			// Diffuse part
			var texColor = diffuseMap.get(calculatedUV);

			var diffuse = vec4(dirLight, 1) * (dot(transformedNormal, -dirLightDir) + 1.3) * 0.5;

			// Specular
			var r = reflect(dirLightDir, transformedNormal).normalize();
			var specValue = saturate(r.dot((camera.position - transformedPosition).normalize())) * fragLightW;
			var specular = specularColor * pow(specValue, shininess);

			var viewDir = normalize(camera.position - pixelTransformedPosition);

			var incidentRay = normalize(pixelTransformedPosition - camera.position);
			var reflectionRay = reflect(incidentRay, transformedNormal);

			var reflectColor = envMap.get(reflectionRay);

			var avgColor = vec4((reflectColor.r + reflectColor.g + reflectColor.b) / 3.0);
			var finalReflectColor = mix(reflectColor, avgColor, 1);

			var outCol = mix(texColor * diffuse * 1.2, finalReflectColor * diffuse, texColor.a);
			outCol += specular * 0.5;

			pixelColor = outCol;
		}
	}

	public function new(diffuse, skybox, shininess, specularVal, ambientLight, dirLight, dirLightDir, uvScaleFactor) {
		super();
		this.diffuseMap = diffuse;
		this.envMap = skybox;
		this.shininess = shininess;
		this.specularColor = specularVal;
		this.ambientLight = ambientLight.clone();
		this.dirLight = dirLight.clone();
		this.dirLightDir = dirLightDir.clone();
		this.uvScaleFactor = uvScaleFactor;
	}
}
