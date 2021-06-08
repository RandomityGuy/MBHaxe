package shaders;

class Billboard extends hxsl.Shader {
	static var SRC = {
		@input var input:{
			var uv:Vec2;
		};
		@global var camera:{
			var view:Mat4;
			var proj:Mat4;
		};
		@global var global:{
			@perObject var modelView:Mat4;
		};
		@param var scale:Float;
		@param var rotation:Float;
		var relativePosition:Vec3;
		var projectedPosition:Vec4;
		var calculatedUV:Vec2;
		function vertex() {
			var mid = 0.5;
			var uv = input.uv;
			calculatedUV.x = cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid;
			calculatedUV.y = cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid;
		}
		function billboard(pos:Vec2, scale:Vec2):Vec4 {
			return (vec4(0, 0, 0, 1) * (global.modelView * camera.view) + vec4(pos * scale, 0, 0));
		}
		function __init__() {
			projectedPosition = billboard(relativePosition.xy, vec2(scale, scale)) * camera.proj;
		}
	}
}
