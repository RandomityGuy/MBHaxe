package shaders;

import h3d.shader.ScreenShader;

class GammaRamp extends ScreenShader {
	static var SRC = {
		@param var texture:Sampler2D;
		@param var gammaRampInvSize:Float = 0.0009765625;
		function fragment() {
			var getColor = pixelColor * (1 - gammaRampInvSize) + (0.5 * gammaRampInvSize);
			pixelColor.r = texture.get(vec2(getColor.r, 0.5)).r;
			pixelColor.g = texture.get(vec2(getColor.g, 0.5)).g;
			pixelColor.b = texture.get(vec2(getColor.b, 0.5)).b;
			pixelColor.a = 1;
		}
	};

	public function new(texture) {
		super();
		this.texture = texture;
	}
}
