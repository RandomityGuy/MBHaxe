package src;

import h3d.Vector;
import h3d.Quat;
import mis.MisParser;
import mis.MissionElement.MissionElementScriptObject;

class PlaytestPoint {
	public var index:Int;
	public var position:Vector;
	public var rotation:Quat;

	public function new(index:Int, position:Vector, rotation:Quat) {
		this.index = index;
		this.position = position;
		this.rotation = rotation;
	}

	public static function fromScriptObject(so:MissionElementScriptObject):PlaytestPoint {
		var indexStr = so.fields.exists("index") ? so.fields.get("index")[0] : "0";
		var index = Std.parseInt(indexStr);
		if (index == null)
			index = 0;

		var posStr = so.fields.exists("position") ? so.fields.get("position")[0] : null;
		var pos = MisParser.parseVector3(posStr);
		pos.x *= -1;

		var rotStr = so.fields.exists("rotation") ? so.fields.get("rotation")[0] : null;
		var rot = MisParser.parseRotation(rotStr);
		rot.x *= -1;
		rot.w *= -1;

		return new PlaytestPoint(index, pos, rot);
	}
}
