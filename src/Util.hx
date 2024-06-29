package src;

import haxe.io.BytesBuffer;
import haxe.io.Bytes;
import h3d.Matrix;
import hxd.Key;
import h2d.Tile;
import h3d.mat.Texture;
import hxd.BitmapData;
import h3d.Vector;
import src.Settings;

class Util {
	public static inline function mat3x3equal(a:Matrix, b:Matrix) {
		return a._11 == b._11 && a._12 == b._12 && a._13 == b._13 && a._21 == b._21 && a._22 == b._22 && a._23 == b._23 && a._31 == b._31 && a._32 == b._32
			&& a._33 == b._33;
	}

	public static inline function adjustedMod(a:Float, n:Float) {
		var r1 = a % n;
		var r2 = (r1 + n) % n;
		return r2;
	}

	public static inline function clamp(value:Float, min:Float, max:Float) {
		if (value < min)
			return min;
		if (value > max)
			return max;
		return value;
	}

	public static inline function lerp(a:Float, b:Float, t:Float) {
		return a + (b - a) * t;
	}

	public static inline function catmullRom(t:Float, p0:Float, p1:Float, p2:Float, p3:Float) {
		var point = t * t * t * ((-1) * p0 + 3 * p1 - 3 * p2 + p3) / 2;
		point += t * t * (2 * p0 - 5 * p1 + 4 * p2 - p3) / 2;
		point += t * ((-1) * p0 + p2) / 2;
		point += p1;
		return point;
	}

	public static inline function lerpThreeVectors(v1:Vector, v2:Vector, t:Float) {
		return new Vector(lerp(v1.x, v2.x, t), lerp(v1.y, v2.y, t), lerp(v1.z, v2.z, t), lerp(v1.w, v2.w, t));
	}

	public static function rotateImage(bitmap:hxd.Pixels, angle:Float) {
		var curpixels = bitmap.clone();
		if (angle == Math.PI / 2)
			for (x in 0...curpixels.width) {
				for (y in 0...curpixels.height) {
					var psrc = ((y + (curpixels.height - x - 1) * curpixels.width) * @:privateAccess curpixels.bytesPerPixel) + curpixels.offset;
					var pdest = ((x + y * curpixels.width) * @:privateAccess curpixels.bytesPerPixel) + curpixels.offset;

					switch (curpixels.format) {
						case R8:
							bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
						case BGRA | RGBA | ARGB:
							bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
							bitmap.bytes.set(pdest + 1, curpixels.bytes.get(psrc + 1));
							bitmap.bytes.set(pdest + 2, curpixels.bytes.get(psrc + 2));
							bitmap.bytes.set(pdest + 3, curpixels.bytes.get(psrc + 3));
						case RG8:
							bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
							bitmap.bytes.set(pdest + 1, curpixels.bytes.get(psrc + 1));
						default:
							null;
					}

					// bitmap.setPixel(x, y, curpixels.getPixel(y, curpixels.height - x - 1));
				}
			}
		if (angle == -Math.PI / 2)
			for (x in 0...curpixels.width) {
				for (y in 0...curpixels.height) {
					var psrc = ((curpixels.width - y - 1) + x * curpixels.width) * @:privateAccess curpixels.bytesPerPixel + curpixels.offset;

					var pdest = ((x + y * curpixels.width) * @:privateAccess curpixels.bytesPerPixel) + curpixels.offset;

					switch (curpixels.format) {
						case R8:
							bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
						case BGRA | RGBA | ARGB:
							bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
							bitmap.bytes.set(pdest + 1, curpixels.bytes.get(psrc + 1));
							bitmap.bytes.set(pdest + 2, curpixels.bytes.get(psrc + 2));
							bitmap.bytes.set(pdest + 3, curpixels.bytes.get(psrc + 3));
						case RG8:
							bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
							bitmap.bytes.set(pdest + 1, curpixels.bytes.get(psrc + 1));
						default:
							null;
					}
				}
			}
		if (angle == Math.PI)
			for (x in 0...curpixels.width) {
				for (y in 0...curpixels.height) {
					var psrc = ((curpixels.width - x - 1)
						+ (curpixels.height - y - 1) * curpixels.width) * @:privateAccess curpixels.bytesPerPixel
						+ curpixels.offset;

					var pdest = ((x + y * curpixels.width) * @:privateAccess curpixels.bytesPerPixel) + curpixels.offset;

					switch (curpixels.format) {
						case R8:
							bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
						case BGRA | RGBA | ARGB:
							bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
							bitmap.bytes.set(pdest + 1, curpixels.bytes.get(psrc + 1));
							bitmap.bytes.set(pdest + 2, curpixels.bytes.get(psrc + 2));
							bitmap.bytes.set(pdest + 3, curpixels.bytes.get(psrc + 3));
						case RG8:
							bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
							bitmap.bytes.set(pdest + 1, curpixels.bytes.get(psrc + 1));
						default:
							null;
					}
				}
			}
	}

	public static function flipImage(bitmap:hxd.Pixels, hflip:Bool, vflip:Bool) {
		var curpixels = bitmap.clone();

		if (hflip && vflip) {
			for (x in 0...curpixels.width) {
				for (y in 0...curpixels.height) {
					var psrc = ((curpixels.width - x - 1)
						+ (curpixels.width - y - 1) * curpixels.width) * @:privateAccess curpixels.bytesPerPixel
						+ curpixels.offset;

					var pdest = ((x + y * curpixels.width) * @:privateAccess curpixels.bytesPerPixel) + curpixels.offset;

					switch (curpixels.format) {
						case R8:
							bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
						case BGRA | RGBA | ARGB:
							bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
							bitmap.bytes.set(pdest + 1, curpixels.bytes.get(psrc + 1));
							bitmap.bytes.set(pdest + 2, curpixels.bytes.get(psrc + 2));
							bitmap.bytes.set(pdest + 3, curpixels.bytes.get(psrc + 3));
						case RG8:
							bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
							bitmap.bytes.set(pdest + 1, curpixels.bytes.get(psrc + 1));
						default:
							null;
					}
				}
			}
		} else {
			if (hflip)
				for (x in 0...curpixels.width) {
					for (y in 0...curpixels.height) {
						var psrc = ((curpixels.width - x - 1) + y * curpixels.width) * @:privateAccess curpixels.bytesPerPixel + curpixels.offset;

						var pdest = ((x + y * curpixels.width) * @:privateAccess curpixels.bytesPerPixel) + curpixels.offset;

						switch (curpixels.format) {
							case R8:
								bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
							case BGRA | RGBA | ARGB:
								bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
								bitmap.bytes.set(pdest + 1, curpixels.bytes.get(psrc + 1));
								bitmap.bytes.set(pdest + 2, curpixels.bytes.get(psrc + 2));
								bitmap.bytes.set(pdest + 3, curpixels.bytes.get(psrc + 3));
							case RG8:
								bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
								bitmap.bytes.set(pdest + 1, curpixels.bytes.get(psrc + 1));
							default:
								null;
						}
					}
				}
			if (vflip)
				for (x in 0...curpixels.width) {
					for (y in 0...curpixels.height) {
						var psrc = (x + (curpixels.width - y - 1) * curpixels.width) * @:privateAccess curpixels.bytesPerPixel + curpixels.offset;

						var pdest = ((x + y * curpixels.width) * @:privateAccess curpixels.bytesPerPixel) + curpixels.offset;

						switch (curpixels.format) {
							case R8:
								bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
							case BGRA | RGBA | ARGB:
								bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
								bitmap.bytes.set(pdest + 1, curpixels.bytes.get(psrc + 1));
								bitmap.bytes.set(pdest + 2, curpixels.bytes.get(psrc + 2));
								bitmap.bytes.set(pdest + 3, curpixels.bytes.get(psrc + 3));
							case RG8:
								bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
								bitmap.bytes.set(pdest + 1, curpixels.bytes.get(psrc + 1));
							default:
								null;
						}
					}
				}
		}
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
			"\\'" => "'",
			"\\\"" => "\"",
		];

		for (obj => esc in specialCases) {
			str = StringTools.replace(str, obj, esc);
		}

		return str;
	}

	/** Gets the index of a substring like String.prototype.indexOf, but only if that index lies outside of string literals. */
	public static function indexOfIgnoreStringLiterals(str:String, searchString:String, position = 0, strLiteralToken:Int = '"'.code) {
		var inString = false;
		for (i in position...str.length) {
			var c = StringTools.fastCodeAt(str, i);
			if (inString) {
				if (c == strLiteralToken && StringTools.fastCodeAt(str, i - 1) != '\\'.code)
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

	public static inline function formatScore(score:Float) {
		var scoreInt = Std.int(Math.round(score));
		return '${scoreInt}';
	}

	public static function formatTime(time:Float) {
		var et = time * 1000;
		var thousandth = Std.int(et % 10);
		var hundredth = Std.int((et % 1000) / 10);
		var totalSeconds = Std.int(et / 1000);
		var seconds = totalSeconds % 60;
		var minutes = (totalSeconds - seconds) / 60;

		var secondsOne = seconds % 10;
		var secondsTen = (seconds - secondsOne) / 10;
		var minutesOne = minutes % 10;
		var minutesTen = (minutes - minutesOne) / 10;
		var hundredthOne = hundredth % 10;
		var hundredthTen = (hundredth - hundredthOne) / 10;

		return '${minutesTen}${minutesOne}:${secondsTen}${secondsOne}.${hundredthTen}${hundredthOne}';
	}

	public static function formatTimeHours(time:Float) {
		var et = time * 1000;

		var hours = Math.floor(Math.floor(et / 1000) / 3600);
		var minutes = Math.floor(Math.floor(et / 1000) / 60) - (hours * 60);
		var seconds = Math.floor(et / 1000) - (minutes * 60) - (hours * 3600);
		var hundredth = Math.floor((et % 1000) / 10);

		var secondsOne = seconds % 10;
		var secondsTen = Math.floor(seconds / 10);
		var minutesOne = minutes % 10;
		var minutesTen = Math.floor(minutes / 10);
		var hoursOne = hours % 10;
		var hoursTen = Math.floor(hours / 10);
		var hundredthOne = hundredth % 10;
		var hundredthTen = (hundredth - hundredthOne) / 10;
		var thousandth = Math.floor(et % 10);

		return
			'${(hours > 0 ? (hoursTen > 0 ? '${hoursTen}' : '') +'${hoursOne}' + ':' : '')}${minutesTen}${minutesOne}:${secondsTen}${secondsOne}.${hundredthTen}${hundredthOne}${thousandth}';
	}

	public static inline function rightPad(str:String, len:Int, cutOff:Int) {
		str = str.substring(0, len - cutOff);
		while (str.length < len)
			str += " ";
		return str;
	}

	public static inline function getKeyForButton(button:Int) {
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

	public static inline function getKeyForButton2(button:Int) {
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

	public static function m_matF_x_vectorF(matrix:Matrix, v:Vector) {
		var m = matrix.clone();
		m.transpose();

		var v0 = v.x, v1 = v.y, v2 = v.z;

		var vresult_0 = m._11 * v0 + m._12 * v1 + m._13 * v2;
		var vresult_1 = m._21 * v0 + m._22 * v1 + m._23 * v2;
		var vresult_2 = m._31 * v0 + m._23 * v1 + m._33 * v2;

		v.set(vresult_0, vresult_1, vresult_2);
	}

	public static function isTouchDevice() {
		#if js
		switch (Settings.isTouch) {
			case None:
				if (isIOS()) {
					Settings.isTouch = Some(true);
					return true;
				}
				Settings.isTouch = Some(js.lib.Object.keys(js.Browser.window).contains('ontouchstart'));
				return js.lib.Object.keys(js.Browser.window).contains('ontouchstart');
			case Some(val):
				return val;
		}
		// Let's see if this suffices for now actually (this doesn't match my touchscreen laptop)
		#end
		#if hl
		switch (Settings.isTouch) {
			case None:
				#if android
				Settings.isTouch = Some(true);
				return true;
				#else
				Settings.isTouch = Some(false);
				return false;
				#end
			case Some(val):
				return val;
		}
		#if android
		return true;
		#else
		return false;
		#end
		#end
	}

	public static inline function isSafari() {
		#if js
		var reg = ~/^((?!chrome|android).)*safari/;
		return reg.match(js.Browser.navigator.userAgent);
		#end
		#if hl
		return false;
		#end
	}

	public static inline function isIOS() {
		#if js
		var reg = ~/iPad|iPhone|iPod/gm;
		var t1 = reg.match(js.Browser.navigator.userAgent);
		if (!t1) {
			var reg2 = ~/Mac/gm;
			if (reg2.match(js.Browser.navigator.userAgent)
				&& js.Browser.navigator.maxTouchPoints != null
				&& js.Browser.navigator.maxTouchPoints > 2) {
				return true; // Is ipad pro
			}
			return false;
		}
		return true;
		#end
		#if hl
		return false;
		#end
	}

	public static inline function isTablet() {
		#if js
		var reg = ~/iPad|tablet/gm;
		var t1 = reg.match(js.Browser.navigator.userAgent);
		if (!t1) {
			var reg2 = ~/Mac/gm;
			if (reg2.match(js.Browser.navigator.userAgent)
				&& js.Browser.navigator.maxTouchPoints != null
				&& js.Browser.navigator.maxTouchPoints > 2) {
				return true; // Is ipad pro
			}
			return false;
		}
		return true;
		#end
		#if hl
		return false;
		#end
	}

	public static inline function isIPhone() {
		#if js
		var reg = ~/iPhone/gm;
		return reg.match(js.Browser.navigator.userAgent);
		#end
		#if hl
		return false;
		#end
	}

	public static function isIOSInstancingSupported() {
		#if js
		static var _supported = null;
		if (_supported != null)
			return _supported;

		if (isIOS()) {
			var reg = ~/OS (\d+)_(\d+)_?(\d+)?/;
			if (reg.match(js.Browser.navigator.userAgent)) {
				var mainVer = Std.parseInt(reg.matched(1));
				if (mainVer < 17) {
					_supported = false;
					return false;
				} else {
					_supported = true;
					return true;
				}
			} else {
				_supported = false;
				return false;
			}
		} else {
			_supported = true;
			return true;
		}
		#end
		#if hl
		return true;
		#end
	}

	public static inline function isInFullscreen() {
		#if js
		return (js.Browser.window.innerHeight == js.Browser.window.screen.height
			|| (js.Browser.window.screen.orientation.type == js.html.OrientationType.PORTRAIT_PRIMARY
				|| js.Browser.window.screen.orientation.type == js.html.OrientationType.PORTRAIT_SECONDARY)
			&& js.Browser.window.innerHeight == js.Browser.window.screen.width)
			|| js.Browser.document.fullscreenElement != null;
		#end
		#if hl
		return Settings.optionsSettings.isFullScreen;
		#end
	}

	public static inline function toASCII(bytes:haxe.io.Bytes) {
		var totBytes = new BytesBuffer();
		for (i in 0...bytes.length) {
			var utfbytes = Bytes.ofString(String.fromCharCode(bytes.get(i)));
			totBytes.add(utfbytes);
		}

		return totBytes.getBytes().toString();
	}

	public static function getPlatform() {
		return "Android";
	}
}
