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
		function tanh(x:Float):Float {
			return (exp(2.0 * x) - 1.0) / (exp(2.0 * x) + 1.0);
		}
		function sigmoid(x:Float):Float {
			return 0.5 + 0.5 * tanh(2.0 * x - 1.0);
		}
		function atanh(x:Float):Float {
			return 0.5 * log((1.0 + x) / (1.0 - x));
		}
		function invSigmoid(x:Float):Float {
			return 0.5 + 0.5 * atanh(2.0 * x - 1.0);
		}
		function fragment() {
			var viewDir = normalize(camera.position - pixelTransformedPosition);

			var incidentRay = normalize(pixelTransformedPosition - camera.position);
			var reflectionRay = reflect(incidentRay, transformedNormal);

			var refl = texture.get(reflectionRay);

			var reflectAmount = invSigmoid(0.01 + 0.98 * pixelColor.a);
			reflectAmount -= 0.7 * (2.0 * -dot(transformedNormal, viewDir) - 1.0);
			reflectAmount = sigmoid(reflectAmount);
			reflectAmount = 0.95 * reflectAmount;

			pixelColor = vec4(mix(pixelColor.rgb, refl.rgb, reflectAmount), 1.0);
		}
	}

	public function new(texture) {
		super();
		this.texture = texture;
	}
}
