package triggers;

import src.TimeState;
import src.Marble;
import src.MarbleWorld;
import mis.MisParser;

class PathTrigger extends Trigger {
	public var triggered:Bool = false;

	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		var triggerOnceField = this.element.fields.get("triggeronce");
		var triggerOnce = triggerOnceField == null || MisParser.parseBoolean(triggerOnceField[0]);
		if (triggerOnce && this.triggered)
			return;
		this.triggered = true;

		runObjectPathChain(this.element.fields, this.level);
	}

	override function reset() {
		super.reset();
		this.triggered = false;
	}

	public static function runObjectPathChain(fields:Map<String, Array<String>>, level:MarbleWorld) {
		var path:String = null;
		var i = 1;
		while (true) {
			var objectField = fields.get("object" + i);
			var objectName = objectField != null ? objectField[0] : null;
			if (objectName == null || objectName == "")
				break;
			var target = level.namedGameObjects.get(objectName.toLowerCase());
			if (target == null)
				break;

			var pathField = fields.get("path" + i);
			var pathAtIndex = pathField != null ? pathField[0] : null;
			if (pathAtIndex != null && pathAtIndex != "")
				path = pathAtIndex;

			if (path != null)
				target.moveOnPath(path, level);

			i++;
		}
	}

	public static function collectObjectTargets(fields:Map<String, Array<String>>, level:MarbleWorld):Array<src.GameObject> {
		var targets = [];
		var i = 1;
		while (true) {
			var objectField = fields.get("object" + i);
			var objectName = objectField != null ? objectField[0] : null;
			if (objectName == null || objectName == "")
				break;
			var target = level.namedGameObjects.get(objectName.toLowerCase());
			if (target == null)
				break;
			targets.push(target);
			i++;
		}
		return targets;
	}
}
