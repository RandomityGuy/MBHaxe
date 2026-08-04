package src;

import src.Mission;
import modes.GameMode.ScoreType;
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

	public static inline function adjustediMod(a:Int, n:Int) {
		var r1 = a % n;
		var r2 = (r1 + n) % n;
		return r2;
	}

	public static inline function normalizeAngle(angle:Float):Float {
		var wrapped = adjustedMod(angle + Math.PI, Math.PI * 2) - Math.PI;
		return wrapped <= -Math.PI ? wrapped + Math.PI * 2 : wrapped;
	}

	public static inline function clamp(value:Float, min:Float, max:Float) {
		if (value < min)
			return min;
		if (value > max)
			return max;
		return value;
	}

	public static inline function imin(a:Int, b:Int) {
		return a < b ? a : b;
	}

	public static inline function imax(a:Int, b:Int) {
		return a > b ? a : b;
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
		switch (bitmap.format) {
			case S3TC(_):
				if (angle == Math.PI / 2)
					transformS3TC(bitmap, 0);
				if (angle == -Math.PI / 2)
					transformS3TC(bitmap, 1);
				if (angle == Math.PI)
					transformS3TC(bitmap, 2);
				return;
			default:
		}
		var curpixels = bitmap.clone();
		if (angle == Math.PI / 2)
			for (x in 0...curpixels.width) {
				for (y in 0...curpixels.height) {
					var psrc = ((y + (curpixels.height - x - 1) * curpixels.width) * @:privateAccess curpixels.bytesPerPixel) + curpixels.offset;
					var pdest = ((x + y * curpixels.width) * @:privateAccess curpixels.bytesPerPixel) + bitmap.offset;

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
						case RGB8 | BGR8:
							bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
							bitmap.bytes.set(pdest + 1, curpixels.bytes.get(psrc + 1));
							bitmap.bytes.set(pdest + 2, curpixels.bytes.get(psrc + 2));
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

					var pdest = ((x + y * curpixels.width) * @:privateAccess curpixels.bytesPerPixel) + bitmap.offset;

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
						case RGB8 | BGR8:
							bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
							bitmap.bytes.set(pdest + 1, curpixels.bytes.get(psrc + 1));
							bitmap.bytes.set(pdest + 2, curpixels.bytes.get(psrc + 2));
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

					var pdest = ((x + y * curpixels.width) * @:privateAccess curpixels.bytesPerPixel) + bitmap.offset;

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
						case RGB8 | BGR8:
							bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
							bitmap.bytes.set(pdest + 1, curpixels.bytes.get(psrc + 1));
							bitmap.bytes.set(pdest + 2, curpixels.bytes.get(psrc + 2));
						default:
							null;
					}
				}
			}
	}

	public static function flipImage(bitmap:hxd.Pixels, hflip:Bool, vflip:Bool) {
		switch (bitmap.format) {
			case S3TC(_):
				if (hflip && vflip)
					transformS3TC(bitmap, 5);
				else if (hflip)
					transformS3TC(bitmap, 3);
				else if (vflip)
					transformS3TC(bitmap, 4);
				return;
			default:
		}
		var curpixels = bitmap.clone();

		if (hflip && vflip) {
			for (x in 0...curpixels.width) {
				for (y in 0...curpixels.height) {
					var psrc = ((curpixels.width - x - 1)
						+ (curpixels.width - y - 1) * curpixels.width) * @:privateAccess curpixels.bytesPerPixel
						+ curpixels.offset;

					var pdest = ((x + y * curpixels.width) * @:privateAccess curpixels.bytesPerPixel) + bitmap.offset;

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
						case RGB8 | BGR8:
							bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
							bitmap.bytes.set(pdest + 1, curpixels.bytes.get(psrc + 1));
							bitmap.bytes.set(pdest + 2, curpixels.bytes.get(psrc + 2));
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

						var pdest = ((x + y * curpixels.width) * @:privateAccess curpixels.bytesPerPixel) + bitmap.offset;

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
							case RGB8 | BGR8:
								bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
								bitmap.bytes.set(pdest + 1, curpixels.bytes.get(psrc + 1));
								bitmap.bytes.set(pdest + 2, curpixels.bytes.get(psrc + 2));
							default:
								null;
						}
					}
				}
			if (vflip)
				for (x in 0...curpixels.width) {
					for (y in 0...curpixels.height) {
						var psrc = (x + (curpixels.width - y - 1) * curpixels.width) * @:privateAccess curpixels.bytesPerPixel + curpixels.offset;

						var pdest = ((x + y * curpixels.width) * @:privateAccess curpixels.bytesPerPixel) + bitmap.offset;

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
							case RGB8 | BGR8:
								bitmap.bytes.set(pdest, curpixels.bytes.get(psrc));
								bitmap.bytes.set(pdest + 1, curpixels.bytes.get(psrc + 1));
								bitmap.bytes.set(pdest + 2, curpixels.bytes.get(psrc + 2));
							default:
								null;
						}
					}
				}
		}
	}

	// mode: 0 = rotate 90, 1 = rotate -90, 2 = rotate 180, 3 = hflip, 4 = vflip, 5 = hflip+vflip
	static inline function s3tcSrcX(mode:Int, x:Int, y:Int, w:Int, h:Int):Int {
		return switch (mode) {
			case 0: y;
			case 1: w - 1 - y;
			case 2, 3, 5: w - 1 - x;
			default: x; // 4
		}
	}

	static inline function s3tcSrcY(mode:Int, x:Int, y:Int, w:Int, h:Int):Int {
		return switch (mode) {
			case 0: h - 1 - x;
			case 1: x;
			case 2, 4, 5: h - 1 - y;
			default: y; // 3
		}
	}

	static inline function getBits(bytes:haxe.io.Bytes, baseByte:Int, bitStart:Int, bitCount:Int):Int {
		var result = 0;
		for (i in 0...bitCount) {
			var bp = bitStart + i;
			var b = bytes.get(baseByte + (bp >> 3));
			var bit = (b >> (bp & 7)) & 1;
			result |= bit << i;
		}
		return result;
	}

	static inline function setBits(bytes:haxe.io.Bytes, baseByte:Int, bitStart:Int, bitCount:Int, value:Int):Void {
		for (i in 0...bitCount) {
			var bp = bitStart + i;
			var byteIdx = baseByte + (bp >> 3);
			var bitIdx = bp & 7;
			var cur = bytes.get(byteIdx);
			if (((value >> i) & 1) != 0)
				cur |= (1 << bitIdx);
			else
				cur &= (~(1 << bitIdx)) & 0xFF;
			bytes.set(byteIdx, cur);
		}
	}

	// Remaps the 16 raster-order bitCount-wide pixel index values of a single 4x4 block
	static function remapBlockIndices(src:haxe.io.Bytes, dst:haxe.io.Bytes, srcBase:Int, dstBase:Int, bitCount:Int, mode:Int) {
		for (dy in 0...4) {
			for (dx in 0...4) {
				var sx = s3tcSrcX(mode, dx, dy, 4, 4);
				var sy = s3tcSrcY(mode, dx, dy, 4, 4);
				var v = getBits(src, srcBase, (sy * 4 + sx) * bitCount, bitCount);
				setBits(dst, dstBase, (dy * 4 + dx) * bitCount, bitCount, v);
			}
		}
	}

	// Rotates/flips an S3TC (DXT1/3/5) compressed image by rearranging blocks and the per-pixel
	// index bits within each block, without ever decompressing the texture data.
	static function transformS3TC(bitmap:hxd.Pixels, mode:Int) {
		var n = switch (bitmap.format) {
			case S3TC(v): v;
			default: return;
		}
		if (n != 1 && n != 2 && n != 3)
			return;

		var width = bitmap.width;
		var height = bitmap.height;
		var bw = width >> 2;
		var bh = height >> 2;
		var blockSize = n == 1 ? 8 : 16;
		var srcBytes = bitmap.bytes;
		var srcOff = bitmap.offset;
		var dstBytes = haxe.io.Bytes.alloc(bw * bh * blockSize);

		for (dby in 0...bh) {
			for (dbx in 0...bw) {
				var sbx = s3tcSrcX(mode, dbx, dby, bw, bh);
				var sby = s3tcSrcY(mode, dbx, dby, bw, bh);
				var srcBlockOff = srcOff + (sby * bw + sbx) * blockSize;
				var dstBlockOff = (dby * bw + dbx) * blockSize;

				switch (n) {
					case 1:
						// color0/color1 endpoints (4 bytes) move with the block unchanged
						dstBytes.blit(dstBlockOff, srcBytes, srcBlockOff, 4);
						// color indices (4 bytes, 16x2bit)
						remapBlockIndices(srcBytes, dstBytes, srcBlockOff + 4, dstBlockOff + 4, 2, mode);
					case 2:
						// explicit alpha (8 bytes, 16x4bit)
						remapBlockIndices(srcBytes, dstBytes, srcBlockOff, dstBlockOff, 4, mode);
						// color0/color1 endpoints (4 bytes)
						dstBytes.blit(dstBlockOff + 8, srcBytes, srcBlockOff + 8, 4);
						// color indices (4 bytes, 16x2bit)
						remapBlockIndices(srcBytes, dstBytes, srcBlockOff + 12, dstBlockOff + 12, 2, mode);
					case 3:
						// alpha0/alpha1 endpoints (2 bytes) move with the block unchanged
						dstBytes.blit(dstBlockOff, srcBytes, srcBlockOff, 2);
						// alpha indices (6 bytes, 16x3bit)
						remapBlockIndices(srcBytes, dstBytes, srcBlockOff + 2, dstBlockOff + 2, 3, mode);
						// color0/color1 endpoints (4 bytes)
						dstBytes.blit(dstBlockOff + 8, srcBytes, srcBlockOff + 8, 4);
						// color indices (4 bytes, 16x2bit)
						remapBlockIndices(srcBytes, dstBytes, srcBlockOff + 12, dstBlockOff + 12, 2, mode);
				}
			}
		}

		bitmap.bytes = dstBytes;
		bitmap.offset = 0;
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

	public static function formatScore(score:Int) {
		var str = '${score}';
		// add commas
		var fin = "";
		var c = -1;
		var i = str.length;
		while (i >= 0) {
			if ("0123456789".indexOf(str.charAt(i)) == -1) {
				fin = str.charAt(i) + fin;
				continue;
			}
			if (c % 3 == 0 && c > 0)
				fin += "," + fin;
			fin = str.charAt(i) + fin;
			i--;
			c++;
		}
		return fin;
	}

	public static function getScoreColor(score:Float, scoreType:ScoreType, mission:Mission) {
		var beatPar = false;
		var beatPlatinum = false;
		var beatUltimate = false;
		var beatAwesome = false;

		switch (scoreType) {
			case Score:
				if (score >= mission.qualifyingScore)
					beatPar = true;
				if (score >= mission.goldScore && mission.qualifyingScore > 0)
					beatPlatinum = true;
				if (score >= mission.ultimateScore && mission.ultimateScore > 0)
					beatUltimate = true;
				if (score >= mission.awesomeScore && mission.awesomeScore > 0)
					beatAwesome = true;
			case Time:
				if (score < mission.qualifyTime)
					beatPar = true;
				if (score < mission.goldTime)
					beatPlatinum = true;
				if (score < mission.ultimateTime)
					beatUltimate = true;
				if (score < mission.awesomeTime)
					beatAwesome = true;
		}
		var scoreColor = "#000000";
		if (beatAwesome)
			scoreColor = "#FF4444";
		else if (beatUltimate)
			scoreColor = "#FFCC33";
		else if (beatPlatinum)
			scoreColor = mission.game == "gold" ? "#FFEE11" : "#CCCCCC";
		return scoreColor;
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

		return '${minutesTen}${minutesOne}:${secondsTen}${secondsOne}.${hundredthTen}${hundredthOne}${thousandth}';
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

	public static function formatMLText(text:String) {
		var start = 0;
		var pos = text.indexOf("<func:", start);
		while (pos != -1) {
			var end = text.indexOf(">", start + 5);
			if (end == -1)
				break;
			var pre = text.substr(0, pos);
			var post = text.substr(end + 1);
			var func = text.substr(pos + 6, end - (pos + 6));
			var funcdata = func.split(' ').map(x -> x.toLowerCase());
			var val = "";
			if (funcdata[0] == "bind") {
				if (funcdata[1] == "moveforward")
					val = Util.getKeyForButton(Settings.controlsSettings.forward);
				if (funcdata[1] == "movebackward")
					val = Util.getKeyForButton(Settings.controlsSettings.backward);
				if (funcdata[1] == "moveleft")
					val = Util.getKeyForButton(Settings.controlsSettings.left);
				if (funcdata[1] == "moveright")
					val = Util.getKeyForButton(Settings.controlsSettings.right);
				if (funcdata[1] == "panup")
					val = Util.getKeyForButton(Settings.controlsSettings.camForward);
				if (funcdata[1] == "pandown")
					val = Util.getKeyForButton(Settings.controlsSettings.camBackward);
				if (funcdata[1] == "turnleft")
					val = Util.getKeyForButton(Settings.controlsSettings.camLeft);
				if (funcdata[1] == "turnright")
					val = Util.getKeyForButton(Settings.controlsSettings.camRight);
				if (funcdata[1] == "jump")
					val = Util.getKeyForButton(Settings.controlsSettings.jump);
				if (funcdata[1] == "mousefire")
					val = Util.getKeyForButton(Settings.controlsSettings.powerup);
				if (funcdata[1] == "freelook")
					val = Util.getKeyForButton(Settings.controlsSettings.freelook);
				if (funcdata[1] == "useblast")
					val = Util.getKeyForButton(Settings.controlsSettings.blast);
			}
			start = val.length + pos;
			text = pre + val + post;
			pos = text.indexOf("<func:", start);
		}
		return text;
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

	public static inline function rightPad(str:String, len:Int, cutOff:Int) {
		str = str.substring(0, len - cutOff);
		while (str.length < len)
			str += " ";
		return str;
	}

	public static inline function m_matF_x_vectorF(m:Matrix, v:Vector) {
		var v0 = v.x, v1 = v.y, v2 = v.z;

		var vresult_0 = m._11 * v0 + m._21 * v1 + m._31 * v2;
		var vresult_1 = m._12 * v0 + m._22 * v1 + m._32 * v2;
		var vresult_2 = m._13 * v0 + m._23 * v1 + m._33 * v2;

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
		var reg = ~/iPad|iPhone|iPod/;
		return reg.match(js.Browser.navigator.userAgent);
		#end
		#if hl
		return false;
		#end
	}

	public static inline function isTablet() {
		#if js
		var reg = ~/iPad|tablet/;
		return reg.match(js.Browser.navigator.userAgent);
		#end
		#if hl
		return false;
		#end
	}

	public static inline function isIPhone() {
		#if js
		var reg = ~/iPhone/;
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

	public static inline function getPlatform() {
		#if js
		return js.Browser.navigator.platform;
		#end
		#if hl
		#if MACOS_BUNDLE
		return "MacOS";
		#elseif linux
		return "Linux";
		#else
		return "Windows";
		#end
		#end
	}
}
