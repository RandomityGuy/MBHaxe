package shaders;

class Gamma extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture:Sampler2D;
		@param var gammaMap:Sampler2D;
		@param var gammaRampInvSize:Float;
		function fragment() {
			var c = texture.get(input.uv);
			c = c * (1 - gammaRampInvSize) + 0.5 * gammaRampInvSize;
			c.x = gammaMap.get(vec2(c.x, 0)).x;
			c.y = gammaMap.get(vec2(c.y, 0)).x;
			c.z = gammaMap.get(vec2(c.z, 0)).x;
			c.a = 1;

			output.color = c;
		}
	}

	public function new(gammaMap, gammaRampInvSize) {
		super();
		this.gammaMap = gammaMap;
		this.gammaRampInvSize = gammaRampInvSize;
	}
}
