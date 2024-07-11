package src;

import h3d.Quat;
import h3d.Vector;

class PathedInteriorMarker {
	public var msToNext:Float;
	public var smoothingType:Int;
	public var position:Vector;
	public var rotation:Quat;

	public static var SMOOTHING_LINEAR = 0;
	public static var SMOOTHING_ACCELERATE = 1;
	public static var SMOOTHING_SPLINE = 2;

	public function new() {}

	public function clone() {
		var ret = new PathedInteriorMarker();
		ret.msToNext = msToNext;
		ret.smoothingType = smoothingType;
		ret.position = position;
		ret.rotation = rotation;
		return ret;
	}
}
