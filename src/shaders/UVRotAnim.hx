package shaders;

class UVRotAnim extends hxsl.Shader {
	static var SRC = {
		@global var global:{
			var time:Float;
		};
		@param var offset:Vec2;
		@param var uvRotSpeed:Float;
		var calculatedUV:Vec2;
		function vertex() {
			var s = sin(global.time * uvRotSpeed);
			var c = cos(global.time * uvRotSpeed);
			var v = calculatedUV - offset;
			var vx = v.x * c - v.y * s;
			var vy = v.x * s + v.y * c;

			calculatedUV = vec2(offset.x + vx, offset.y + vy);
		}
	};

	public function new(vx = 0., vy = 0., speed = 1.) {
		super();
		offset.set(vx, vy);
		uvRotSpeed = speed;
	}
}
