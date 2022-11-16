package shaders;

class MarbleReflection extends hxsl.Shader {
	static var SRC = {
		var pixelColor:Vec4;
		var transformedNormal:Vec3;
		@param var texture:SamplerCube;
		@global var camera:{
			var position:Vec3;
		};
		@input var input:{
			var position:Vec3;
			var normal:Vec3;
		};
		var pixelTransformedPosition:Vec3;
		function fresnel(direction:Vec3, normal:Vec3, invert:Bool):Float {
			var nDirection = normalize(direction);
			var nNormal = normalize(normal);
			var halfDirection = normalize(nNormal + nDirection);
			var exponent = 5.0;
			var cosine = dot(halfDirection, nDirection);
			var product = max(cosine, 0.0);
			var factor = invert ? 1.0 - pow(product, exponent) : pow(product, exponent);
			return factor;
		}
		function fragment() {
			var viewDir = normalize(camera.position - pixelTransformedPosition);
			var fac = fresnel(viewDir, transformedNormal, true);

			var incidentRay = normalize(pixelTransformedPosition - camera.position);
			var reflectionRay = reflect(incidentRay, transformedNormal);

			var refl = texture.get(reflectionRay);

			pixelColor = mix(pixelColor, refl, fac * 0.7);
		}
	}

	public function new(texture) {
		super();
		this.texture = texture;
	}
}
