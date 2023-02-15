package shaders;

class EnvMap extends hxsl.Shader {
	static var SRC = {
		@param var envMap:SamplerCube;
		@param var shininess:Float;
		@global var camera:{
			var position:Vec3;
			@var var dir:Vec3;
		};
		var pixelColor:Vec4;
		var transformedNormal:Vec3;
		var pixelTransformedPosition:Vec3;
		function fragment() {
			var viewDir = normalize(camera.position - pixelTransformedPosition);

			var incidentRay = normalize(pixelTransformedPosition - camera.position);
			var reflectionRay = reflect(incidentRay, transformedNormal);

			var reflectColor = envMap.get(reflectionRay);

			pixelColor = mix(pixelColor, reflectColor, shininess);
		}
	}

	public function new(skybox, shininess) {
		super();
		this.envMap = skybox;
		this.shininess = shininess;
	}
}
