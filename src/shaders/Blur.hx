package shaders;

import h3d.shader.ScreenShader;

class Blur extends ScreenShader {
	static var SRC = {
		@param var texture:Sampler2D;
		@param var kernel:Array<Vec4, 13>;
		@param var divisor:Float;
		function fragment() {
			var accumColor = vec4(0);
			for (i in 0...13) {
				accumColor += texture.get(input.uv + kernel[i].xy) * kernel[i].z;
			}
			pixelColor = accumColor / divisor;
			pixelColor.a = pixelColor.x + pixelColor.y + pixelColor.z / 3.0;
			pixelColor.xyz *= 2.0;
		}
	};
}
