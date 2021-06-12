package mis;

import haxe.Exception;
import mis.MissionElement.MissionElementPathedInterior;
import mis.MissionElement.MissionElementPath;
import mis.MissionElement.MissionElementSimGroup;
import mis.MissionElement.MissionElementBase;
import mis.MissionElement.MissionElementParticleEmitterNode;
import mis.MissionElement.MissionElementTSStatic;
import mis.MissionElement.MissionElementMessageVector;
import mis.MissionElement.MissionElementAudioProfile;
import mis.MissionElement.MissionElementTrigger;
import mis.MissionElement.MissionElementMarker;
import mis.MissionElement.MissionElementItem;
import mis.MissionElement.MissionElementStaticShape;
import mis.MissionElement.MissionElementInteriorInstance;
import mis.MissionElement.MissionElementSun;
import mis.MissionElement.MissionElementSky;
import mis.MissionElement.MissionElementMissionArea;
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

	public function parse() {
		var objectWriteBeginIndex = this.text.indexOf("//--- OBJECT WRITE BEGIN ---");
		var objectWriteEndIndex = this.text.lastIndexOf("//--- OBJECT WRITE END ---");

		var outsideText = this.text.substring(0, objectWriteBeginIndex) + this.text.substring(objectWriteEndIndex);

		// Find all specified variables
		this.variables = ["$usermods" => '""']; // Just make $usermods point to nothing

		var startText = outsideText;

		while (assignmentRegEx.match(startText)) {
			if (!this.variables.exists(assignmentRegEx.matched(1)))
				this.variables.set(assignmentRegEx.matched(1), assignmentRegEx.matched(2));
			startText = assignmentRegEx.matchedRight();
		}

		var marbleAttributes = new Map();

		startText = outsideText;

		while (marbleAttributesRegEx.match(startText)) {
			marbleAttributes.set(marbleAttributesRegEx.matched(1), this.resolveExpression(marbleAttributesRegEx.matched(2)));
			startText = marbleAttributesRegEx.matchedRight();
		}

		var activatedPackages = [];
		startText = outsideText;

		while (activatePackageRegEx.match(startText)) {
			activatedPackages.push(this.resolveExpression(activatePackageRegEx.matched(1)));
			startText = marbleAttributesRegEx.matchedRight();
		}

		if (objectWriteBeginIndex != -1 && objectWriteEndIndex != -1) {
			this.text = this.text.substring(objectWriteBeginIndex, objectWriteEndIndex);
		}

		var currentIndex = 0;
		while (true) {
			// blockCommentRegEx.lastIndex = currentIndex;
			// lineCommentRegEx.lastIndex = currentIndex;

			var blockMatch = blockCommentRegEx.matchSub(this.text, currentIndex);
			var lineMatch = lineCommentRegEx.matchSub(this.text, currentIndex);

			// The detected "comment" might be inside a string literal, in which case we ignore it 'cause it ain't no comment.
			if (blockMatch && Util.indexIsInStringLiteral(this.text, blockCommentRegEx.matchedPos().pos))
				blockMatch = false;
			if (lineMatch && Util.indexIsInStringLiteral(this.text, lineCommentRegEx.matchedPos().pos))
				lineMatch = false;

			if (!blockMatch && !lineMatch)
				break;
			else if (!lineMatch || (blockMatch && lineMatch && blockCommentRegEx.matchedPos().pos < lineCommentRegEx.matchedPos().pos)) {
				this.text = this.text.substring(0, blockCommentRegEx.matchedPos().pos)
					+ this.text.substring(blockCommentRegEx.matchedPos().pos + blockCommentRegEx.matchedPos().len);
				currentIndex += blockCommentRegEx.matchedPos().pos;
			} else {
				this.text = this.text.substring(0, lineCommentRegEx.matchedPos().pos)
					+ this.text.substring(lineCommentRegEx.matchedPos().pos + lineCommentRegEx.matchedPos().len);
				currentIndex += lineCommentRegEx.matchedPos().pos;
			}
		}

		var elements = [];
		while (this.hasNextElement()) {
			var element = this.readElement();
			if (element == null)
				continue;
			elements.push(element);
		}

		if (elements.length != 1) {
			// We expect there to be only one outer element; the MissionGroup SimGroup.
			trace(elements);
			throw new Exception("Mission file doesn't have exactly 1 outer element!");
		}

		var mf = new MisFile();
		mf.root = cast elements[0];
		mf.marbleAttributes = marbleAttributes;
		mf.activatedPackages = activatedPackages;
		return mf;
	}

	function readElement() {
		// Get information about the head
		// elementHeadRegEx.lastIndex = this.index;
		var head = elementHeadRegEx.match(this.text.substring(this.index));
		this.index += elementHeadRegEx.matchedPos().pos + elementHeadRegEx.matchedPos().len;
		var type = elementHeadRegEx.matched(1);
		var name = elementHeadRegEx.matched(2);
		var element:MissionElementBase = null;
		switch (type) {
			case "SimGroup":
				element = this.readSimGroup(name);
			case "ScriptObject":
				element = this.readScriptObject(name);
			case "MissionArea":
				element = this.readMissionArea(name);
			case "Sky":
				element = this.readSky(name);
			case "Sun":
				element = this.readSun(name);
			case "InteriorInstance":
				element = this.readInteriorInstance(name);
			case "StaticShape":
				element = this.readStaticShape(name);
			case "Item":
				element = this.readItem(name);
			case "Path":
				element = this.readPath(name);
			case "Marker":
				element = this.readMarker(name);
			case "PathedInterior":
				element = this.readPathedInterior(name);
			case "Trigger":
				element = this.readTrigger(name);
			case "AudioProfile":
				element = this.readAudioProfile(name);
			case "MessageVector":
				element = this.readMessageVector(name);
			case "TSStatic":
				element = this.readTSStatic(name);
			case "ParticleEmitterNode":
				element = this.readParticleEmitterNode(name);
			default:
				trace("Unknown element type! " + type);
				// Still advance the index
				var endingBraceIndex = Util.indexOfIgnoreStringLiterals(this.text, '};', this.index);
				if (endingBraceIndex == -1)
					endingBraceIndex = this.text.length;
				this.index = endingBraceIndex + 2;
		}
		if (element != null)
			element._id = this.currentElementId++;
		return element;
	}

	function hasNextElement() {
		if (!elementHeadRegEx.match(this.text.substring(this.index)))
			return false;
		if (Util.indexOfIgnoreStringLiterals(this.text.substring(this.index, this.index + elementHeadRegEx.matchedPos().pos), '}') != -1)
			return false;
		return true;
	}

	function readSimGroup(name:String) {
		var elements = [];
		// Read in all elements
		while (this.hasNextElement()) {
			var element = this.readElement();
			if (element == null)
				continue;
			elements.push(element);
		}
		var endingBraceIndex = Util.indexOfIgnoreStringLiterals(this.text, '};', this.index);
		if (endingBraceIndex == -1)
			endingBraceIndex = this.text.length;
		this.index = endingBraceIndex + 2;

		var sg = new MissionElementSimGroup();
		sg._name = name;
		sg._type = MissionElementType.SimGroup;
		sg.elements = elements;
		return sg;
	}

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

	function copyFields(obj:Dynamic) {
		var values = this.readValues();
		var objfields = Type.getInstanceFields(Type.getClass(obj));

		for (key => value in values) {
			if (value.length > 1) {
				for (i in 0...value.length) {
					var fname = '${key}${i}';
					if (objfields.contains(fname))
						Reflect.setField(obj, fname, value[i]);
				}
			} else {
				if (key == "static")
					key = "isStatic";
				if (objfields.contains(key))
					Reflect.setField(obj, key, value[0]);
			}
		}
	}

	function readScriptObject(name:String) {
		var obj = new MissionElementScriptObject();
		obj._type = MissionElementType.ScriptObject;
		obj._name = name;

		copyFields(obj);

		return obj;
	}

	function readMissionArea(name:String) {
		var obj = new MissionElementMissionArea();
		obj._type = MissionElementType.MissionArea;
		obj._name = name;

		copyFields(obj);

		return obj;
	}

	function readSky(name:String) {
		var obj = new MissionElementSky();
		obj._type = MissionElementType.Sky;
		obj._name = name;

		copyFields(obj);

		return obj;
	}

	function readSun(name:String) {
		var obj = new MissionElementSun();
		obj._type = MissionElementType.Sun;
		obj._name = name;

		copyFields(obj);

		return obj;
	}

	function readInteriorInstance(name:String) {
		var obj = new MissionElementInteriorInstance();
		obj._type = MissionElementType.InteriorInstance;
		obj._name = name;

		copyFields(obj);

		return obj;
	}

	function readStaticShape(name:String) {
		var obj = new MissionElementStaticShape();
		obj._type = MissionElementType.StaticShape;
		obj._name = name;

		copyFields(obj);

		return obj;
	}

	function readItem(name:String) {
		var obj = new MissionElementItem();
		obj._type = MissionElementType.Item;
		obj._name = name;

		copyFields(obj);

		return obj;
	}

	function readPath(name:String) {
		var sg:MissionElementSimGroup = cast this.readSimGroup(name);
		var obj = new MissionElementPath();
		obj._type = MissionElementType.Path;
		obj._name = name;
		obj.markers = sg.elements.map(x -> cast x);
		obj.markers.sort((a, b) -> cast MisParser.parseNumber(a.seqnum) - MisParser.parseNumber(b.seqnum));
		copyFields(obj);

		return obj;
	}

	function readMarker(name:String) {
		var obj = new MissionElementMarker();
		obj._type = MissionElementType.Marker;
		obj._name = name;

		copyFields(obj);

		return obj;
	}

	function readPathedInterior(name:String) {
		var obj = new MissionElementPathedInterior();
		obj._type = MissionElementType.PathedInterior;
		obj._name = name;

		copyFields(obj);

		return obj;
	}

	function readTrigger(name:String) {
		var obj = new MissionElementTrigger();
		obj._type = MissionElementType.Trigger;
		obj._name = name;

		copyFields(obj);

		return obj;
	}

	function readAudioProfile(name:String) {
		var obj = new MissionElementAudioProfile();
		obj._type = MissionElementType.AudioProfile;
		obj._name = name;

		copyFields(obj);

		return obj;
	}

	function readMessageVector(name:String) {
		var obj = new MissionElementMessageVector();
		obj._type = MissionElementType.MessageVector;
		obj._name = name;

		copyFields(obj);

		return obj;
	}

	function readTSStatic(name:String) {
		var obj = new MissionElementTSStatic();
		obj._type = MissionElementType.TSStatic;
		obj._name = name;

		copyFields(obj);

		return obj;
	}

	function readParticleEmitterNode(name:String) {
		var obj = new MissionElementParticleEmitterNode();
		obj._type = MissionElementType.ParticleEmitterNode;
		obj._name = name;

		copyFields(obj);

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
