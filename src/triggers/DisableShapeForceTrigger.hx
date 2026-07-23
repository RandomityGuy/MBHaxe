package triggers;

import src.TimeState;
import src.Marble;
import src.ForceObject;
import mis.MisParser;

class DisableShapeForceTrigger extends Trigger {
	function forEachTarget(callback:ForceObject->Void) {
		var targetField = this.element.fields.get("target");
		if (targetField == null)
			return;
		for (name in targetField) {
			if (name == null || name == "")
				continue;
			var named = this.level.namedObjects.get(name);
			if (named != null && named.obj is ForceObject)
				callback(cast named.obj);
		}
	}

	function invert():Bool {
		var invertField = this.element.fields.get("invert");
		return invertField != null && MisParser.parseBoolean(invertField[0]);
	}

	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		var inv = invert();
		forEachTarget(target -> target.setPowered(inv));
	}

	override function onMarbleLeave(marble:Marble, timeState:TimeState) {
		var inv = invert();
		forEachTarget(target -> target.setPowered(!inv));
	}
}
