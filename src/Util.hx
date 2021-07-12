package src;

import hxd.Key;
import h2d.Tile;
import h3d.mat.Texture;
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
		return new Vector(lerp(v1.x, v2.x, t), lerp(v1.y, v2.y, t), lerp(v1.z, v2.z, t), lerp(v1.w, v2.w, t));
	}

	public static function rotateImage(bitmap:BitmapData, angle:Float) {
		var curpixels = bitmap.getPixels().clone();
		bitmap.lock();
		if (angle == Math.PI / 2)
			for (x in 0...curpixels.width) {
				for (y in 0...curpixels.height) {
					bitmap.setPixel(x, y, curpixels.getPixel(y, curpixels.height - x - 1));
				}
			}
		if (angle == -Math.PI / 2)
			for (x in 0...curpixels.width) {
				for (y in 0...curpixels.height) {
					bitmap.setPixel(x, y, curpixels.getPixel(curpixels.width - y - 1, x));
				}
			}
		if (angle == Math.PI)
			for (x in 0...curpixels.width) {
				for (y in 0...curpixels.height) {
					bitmap.setPixel(x, y, curpixels.getPixel(curpixels.width - x - 1, curpixels.height - y - 1));
				}
			}
		bitmap.unlock();
	}

	public static function flipImage(bitmap:BitmapData, hflip:Bool, vflip:Bool) {
		var curpixels = bitmap.getPixels().clone();
		bitmap.lock();
		if (hflip)
			for (x in 0...curpixels.width) {
				for (y in 0...curpixels.height) {
					bitmap.setPixel(x, y, curpixels.getPixel(curpixels.height - x - 1, y));
				}
			}
		if (vflip)
			for (x in 0...curpixels.width) {
				for (y in 0...curpixels.height) {
					bitmap.setPixel(x, y, curpixels.getPixel(x, curpixels.width - y - 1));
				}
			}
		bitmap.unlock();
	}

	public static function splitIgnoreStringLiterals(str:String, splitter:String, strLiteralToken = '"') {
		var indices = [];
		var inString = false;
		for (i in 0...str.length) {
			var c = str.charAt(i);
			if (inString) {
				if (c == strLiteralToken && str.charAt(i - 1) != '\\')
					inString = false;
				continue;
			}
			if (c == strLiteralToken)
				inString = true;
			else if (c == splitter)
				indices.push(i);
		}
		var parts = [];
		var remaining = str;
		for (i in 0...indices.length) {
			var index = indices[i] - (str.length - remaining.length);
			var part = remaining.substring(0, index);
			remaining = remaining.substring(index + 1);
			parts.push(part);
		}
		parts.push(remaining);
		return parts;
	}

	public static function unescape(str:String) {
		var specialCases = [
			'\\t' => '\t',
			'\\v' => '\x0B',
			'\\0' => '\x00',
			'\\f' => '\x0C',
			'\\n' => '\n',
			'\\r' => '\r',
			"\\'" => "'"
		];

		for (obj => esc in specialCases) {
			str = StringTools.replace(str, obj, esc);
		}

		return str;
	}

	/** Gets the index of a substring like String.prototype.indexOf, but only if that index lies outside of string literals. */
	public static function indexOfIgnoreStringLiterals(str:String, searchString:String, position = 0, strLiteralToken = '"') {
		var inString = false;
		for (i in position...str.length) {
			var c = str.charAt(i);
			if (inString) {
				if (c == strLiteralToken && str.charAt(i - 1) != '\\')
					inString = false;
				continue;
			}
			if (c == strLiteralToken)
				inString = true;
			#if hl
			else if (Util.startsWithFromIndex(str, searchString, i))
				return i;
			#end
			#if js
			else if ((cast str).startsWith(searchString, i))
				return i;
			#end
		}
		return -1;
	}

	public static function startsWithFromIndex(str:String, searchString:String, index:Int) {
		if (index + searchString.length > str.length)
			return false;
		for (i in 0...searchString.length) {
			if (searchString.charAt(i) != str.charAt(index + i))
				return false;
		}
		return true;
	}

	public static function indexIsInStringLiteral(str:String, index:Int, strLiteralToken = '"') {
		var inString = false;
		for (i in 0...str.length) {
			var c = str.charAt(i);
			if (inString) {
				if (i == index)
					return true;
				if (c == strLiteralToken && str.charAt(i - 1) != '\\')
					inString = false;
				continue;
			}
			if (c == strLiteralToken)
				inString = true;
		}
		return false;
	}

	public static function formatTime(time:Float) {
		var et = time * 1000;
		var thousandth = Math.floor(et % 10);
		var hundredth = Math.floor((et % 1000) / 10);
		var totalSeconds = Math.floor(et / 1000);
		var seconds = totalSeconds % 60;
		var minutes = (totalSeconds - seconds) / 60;

		var secondsOne = seconds % 10;
		var secondsTen = (seconds - secondsOne) / 10;
		var minutesOne = minutes % 10;
		var minutesTen = (minutes - minutesOne) / 10;
		var hundredthOne = hundredth % 10;
		var hundredthTen = (hundredth - hundredthOne) / 10;

		return '${minutesTen}${minutesOne}:${secondsTen}${secondsOne}.${hundredthTen}${hundredthOne}${thousandth}';
	}

	public static function getKeyForButton(button:Int) {
		var keyName = Key.getKeyName(button);
		if (keyName == "MouseLeft")
			keyName = "the Left Mouse Button";
		if (keyName == "MouseRight")
			keyName = "the Right Mouse Button";
		if (keyName == "MouseMiddle")
			keyName = "the Middle Mouse Button";
		if (keyName == "Space")
			keyName = "Space Bar";
		return keyName;
	}

	public static function getKeyForButton2(button:Int) {
		var keyName = Key.getKeyName(button);
		if (keyName == "MouseLeft")
			keyName = "Left Mouse";
		if (keyName == "MouseRight")
			keyName = "Right Mouse";
		if (keyName == "MouseMiddle")
			keyName = "Middle Mouse";
		if (keyName == "Space")
			keyName = "Space Bar";
		return keyName;
	}
}
