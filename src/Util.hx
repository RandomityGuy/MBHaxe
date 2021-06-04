package src;

import hxd.BitmapData;
import h3d.Vector;

class Util {
	public static function adjustedMod(a:Float, n:Float) {
		var r1 = a % n;
		var r2 = (r1 + n) % n;
		return r2;
	}

	public static function clamp(value:Float, min:Float, max:Float) {
		if (value < min)
			return min;
		if (value > max)
			return max;
		return value;
	}

	public static function lerp(a:Float, b:Float, t:Float) {
		return a + (b - a) * t;
	}

	public static function catmullRom(t:Float, p0:Float, p1:Float, p2:Float, p3:Float) {
		var point = t * t * t * ((-1) * p0 + 3 * p1 - 3 * p2 + p3) / 2;
		point += t * t * (2 * p0 - 5 * p1 + 4 * p2 - p3) / 2;
		point += t * ((-1) * p0 + p2) / 2;
		point += p1;
		return point;
	}

	public static function lerpThreeVectors(v1:Vector, v2:Vector, t:Float) {
		return new Vector(lerp(v1.x, v2.x, t), lerp(v1.y, v2.y, t), lerp(v1.z, v2.z, t));
	}

	public static function rotateImage(bitmap:BitmapData, angle:Float) {
		// var bmp = new Bitmap(Tile.fromBitmap(bitmap));
		// bmp.rotate(angle);
		// var output = new Texture(bitmap.width, bitmap.height, [TextureFlags.Target]);
		// bmp.drawTo(output);
		// var pixels = output.capturePixels();
		// bitmap.setPixels(pixels);
	}
}
