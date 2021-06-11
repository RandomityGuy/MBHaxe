package mis;

import mis.MissionElement.MissionElementType;
import mis.MissionElement.MissionElementScriptObject;
import src.Util;
import h3d.Vector;
import h3d.Quat;

final elementHeadRegEx = ~/new (\w+)\((\w*)\) *{/g;
final blockCommentRegEx = ~/\/\*(.|\n)*?\*\//g;
final lineCommentRegEx = ~/\/\/.*/g;
final assignmentRegEx = ~/(\$(?:\w|\d)+)\s*=\s*(.+?);/g;
final marbleAttributesRegEx = ~/setMarbleAttributes\("(\w+)",\s*(.+?)\);/g;
final activatePackageRegEx = ~/activatePackage\((.+?)\);/g;

class MisParser {
	var text:String;
	var index = 0;
	var currentElementId = 0;
	var variables:Map<String, String>;

	public function new(text:String) {
		this.text = text;
	}

	public function parse() {}

	function readValues() {
		// Values are either strings or string arrays.
		var obj:Map<String, Array<String>> = new Map();
		var endingBraceIndex = Util.indexOfIgnoreStringLiterals(this.text, '};', this.index);
		if (endingBraceIndex == -1)
			endingBraceIndex = this.text.length;
		var section = StringTools.trim(this.text.substring(this.index, endingBraceIndex));
		var statements = Util.splitIgnoreStringLiterals(section, ';').map(x -> StringTools.trim(x)); // Get a list of all statements
		for (statement in statements) {
			if (statement == null || statement == "")
				continue;
			var splitIndex = statement.indexOf('=');
			if (splitIndex == -1)
				continue;
			var parts = [statement.substring(0, splitIndex), statement.substring(splitIndex + 1)].map((part) -> StringTools.trim(part));
			if (parts.length != 2)
				continue;
			var key = parts[0];
			key = key.toLowerCase(); // TorqueScript is case-insensitive here
			if (StringTools.endsWith(key, ']')) {
				// The key is specifying array data, so handle that case.
				var openingIndex = key.indexOf('[');
				var arrayName = key.substring(0, openingIndex);
				var array:Array<String>;
				if (obj.exists(arrayName))
					array = obj.get(arrayName);
				else {
					array = [];
					obj.set(arrayName, array);
				} // Create a new array or use the existing one
				var index = Std.parseInt(key.substring(openingIndex + 1, -1));
				array[index] = this.resolveExpression(parts[1]);
			} else {
				obj.set(key, [this.resolveExpression(parts[1])]);
			}
		}
		this.index = endingBraceIndex + 2;
		return obj;
	}

	function readScriptObject(name:String) {
		var obj = new MissionElementScriptObject();
		obj._type = MissionElementType.ScriptObject;
		obj._name = name;
		var values = this.readValues();

		for (key => value in values) {
			if (value.length > 1) {
				for (i in 0...value.length) {
					Reflect.setField(obj, '${key}${i}', value[i]);
				}
			} else {
				Reflect.setField(obj, key, value[0]);
			}
		}
		return obj;
	}

	/** Resolves a TorqueScript rvalue expression. Currently only supports the concatenation @ operator. */
	function resolveExpression(expr:String) {
		var parts = Util.splitIgnoreStringLiterals(expr, ' @ ').map(x -> {
			x = StringTools.trim(x);
			if (StringTools.startsWith(x, '$ ') && this.variables[x] != null) {
				// Replace the variable with its value
				x = this.resolveExpression(this.variables[x]);
			} else if (StringTools.startsWith(x, ' "') && StringTools.endsWith(x, '" ')) {
				x = Util.unescape(x.substring(1, x.length - 2)); // It' s a string literal, so remove " "
			}
			return x;
		});
		return parts.join('');
	}

	/** Parses a 4-component vector from a string of four numbers. */
	public static function parseVector3(string:String) {
		if (string == null)
			return new Vector();
		var parts = string.split(' ').map((part) -> Std.parseFloat(part));

		if (parts.length < 3)
			return new Vector();
		if (parts.filter(x -> !Math.isFinite(x)).length != 0)
			return new Vector();
		return new Vector(parts[0], parts[1], parts[2]);
	}

	/** Parses a 4-component vector from a string of four numbers. */
	public static function parseVector4(string:String) {
		if (string == null)
			return new Vector();
		var parts = string.split(' ').map((part) -> Std.parseFloat(part));

		if (parts.length < 4)
			return new Vector();
		if (parts.filter(x -> !Math.isFinite(x)).length != 0)
			return new Vector();
		return new Vector(parts[0], parts[1], parts[2], parts[3]);
	}

	/** Returns a quaternion based on a rotation specified from 4 numbers. */
	public static function parseRotation(string:String) {
		if (string == null)
			return new Quat();
		var parts = string.split(' ').map((part) -> Std.parseFloat(part));
		if (parts.length < 4)
			return new Quat();
		if (parts.filter(x -> !Math.isFinite(x)).length != 0)
			return new Quat();
		var quaternion = new Quat();
		// The first 3 values represent the axis to rotate on, the last represents the negative angle in degrees.
		quaternion.initRotateAxis(parts[0], parts[1], parts[2], -parts[3] * Math.PI / 180);
		return quaternion;
	}

	/** Parses a numeric value. */
	public static function parseNumber(string:String):Float {
		if (string == null)
			return 0;
		// Strange thing here, apparently you can supply lists of numbers. In this case tho, we just take the first value.
		var val = Std.parseFloat(string.split(',')[0]);
		if (Math.isNaN(val))
			return 0;
		return val;
	}

	/** Parses a list of space-separated numbers. */
	public static function parseNumberList(string:String) {
		var parts = string.split(' ');
		var result = [];
		for (part in parts) {
			var number = Std.parseFloat(part);
			if (!Math.isNaN(number)) {
				// The number parsed without issues; simply add it to the array.
				result.push(number);
			} else {
				// Since we got NaN, we assume the number did not parse correctly and we have a case where the space between multiple numbers are missing. So "0.0000000 1.0000000" turning into "0.00000001.0000000".
				final assumedDecimalPlaces = 7; // Reasonable assumption
				// Scan the part to try to find all numbers contained in it
				while (part.length > 0) {
					var dotIndex = part.indexOf('.');
					if (dotIndex == -1)
						break;
					var section = part.substring(0, cast Math.min(dotIndex + assumedDecimalPlaces + 1, part.length));
					result.push(Std.parseFloat(section));
					part = part.substring(dotIndex + assumedDecimalPlaces + 1);
				}
			}
		}
		return result;
	}
}
