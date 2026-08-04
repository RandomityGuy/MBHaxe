package src;

import h3d.Vector;
import h3d.Quat;
import h3d.Matrix;
import mis.MisParser;

@:structInit
class PathNodeLiveTransform {
	public var position:Vector;
	public var rotation:Quat;
}

class PathNodeElement {
	public var name:String;
	public var localPosition:Vector;
	public var localRotation:Quat;
	public var localScale:Vector;
	public var fields:Map<String, Array<String>>;

	public var parentName:String;

	public var nextNode:String;
	public var branchNodes:Array<String>;
	public var delay:Float;
	public var timeToNext:Float;
	public var speed:Float;
	public var isBezier:Bool;
	public var isSpline:Bool;
	public var bezierHandle1:String;
	public var bezierHandle2:String;
	public var smooth:Bool;
	public var smoothStart:Bool;
	public var smoothEnd:Bool;
	public var usePosition:Bool;
	public var useRotation:Bool;
	public var useScale:Bool;
	public var reverseRotation:Bool;
	public var rotationMultiplier:Float;
	public var rotationOffset:Matrix;

	public function new(name:String, position:Vector, rotation:Quat, scale:Vector, fields:Map<String, Array<String>>) {
		this.name = name.toLowerCase();
		this.localPosition = position;
		this.localRotation = rotation;
		this.localScale = scale;
		this.fields = fields;

		function field(key:String):String {
			var f = fields.get(key);
			return f != null ? f[0].toLowerCase() : null;
		}
		function boolField(key:String, def:Bool = false):Bool {
			var v = field(key);
			return v == null || v == "" ? def : MisParser.parseBoolean(v);
		}
		function numField(key:String, def:Float = 0):Float {
			var v = field(key);
			return v == null || v == "" ? def : MisParser.parseNumber(v);
		}

		this.parentName = field("parent");
		this.nextNode = field("nextnode");
		var branchStr = field("branchnodes");
		this.branchNodes = branchStr != null ? branchStr.split(' ').map(x -> StringTools.trim(x)).filter(x -> x != "") : [];
		this.delay = numField("delay") / 1000;
		this.timeToNext = field("timetonext") != null ? numField("timetonext") / 1000 : 5;
		this.speed = numField("speed");
		this.isBezier = boolField("bezier");
		this.isSpline = boolField("spline");
		this.bezierHandle1 = field("bezierhandle1");
		this.bezierHandle2 = field("bezierhandle2");
		this.smooth = boolField("smooth");
		this.smoothStart = boolField("smoothstart");
		this.smoothEnd = boolField("smoothend");
		this.usePosition = boolField("useposition", true);
		this.useRotation = boolField("userotation", true);
		this.useScale = boolField("usescale", true);
		this.reverseRotation = boolField("reverserotation");
		this.rotationMultiplier = numField("rotationmultiplier", 1);

		var rotOffsetStr = field("finalrotoffset");
		if (rotOffsetStr != null && rotOffsetStr != "") {
			var parts = MisParser.parseNumberList(rotOffsetStr);
			if (parts.length == 3) {
				var m = new Matrix();
				m.initRotation(parts[0] * Math.PI / 180, parts[1] * Math.PI / 180, parts[2] * Math.PI / 180);
				this.rotationOffset = m;
			} else if (parts.length == 4) {
				var m = new Matrix();
				m.initRotationAxis(new Vector(parts[0], parts[1], parts[2]), parts[3] * Math.PI / 180);
				this.rotationOffset = m;
			}
		}
	}

	/** Whether this node has more than one possible next node (a random pick happens on leaving it). */
	public function isBranching():Bool {
		return this.branchNodes.length > 0;
	}
}
