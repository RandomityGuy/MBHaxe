package triggers;

import src.TimeState;
import src.Marble;
import mis.MisParser;

/** Assigns a path to one or more named objects on marble-enter. Ported from PQ's
	`PathTrigger::onEnterTrigger` (`platinum/server/scripts/triggers.cs`, explicitly marked
	"UNFINISHED CODE" in the PQ source - reproduced as-is, bugs included, per the standing rule).

	`Object[i]`/`Path[i]` are 1-based indexed fields, read until the first `Object[i]` that doesn't
	resolve to a real placed object. `InitialPosition[i]` is parsed by PQ but never actually used
	(the underlying `moveOnPath` only takes one parameter, so PQ's extra argument is silently
	discarded) - not wired to anything here either. If `Path[i]` is blank, PQ simply doesn't
	reassign its working `%path` variable, so it silently reuses whatever the *previous* index's
	path was - reproduced verbatim, not "fixed" to fall back to null. */
class PathTrigger extends Trigger {
	var triggered:Bool = false;

	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		var triggerOnceField = this.element.fields.get("triggeronce");
		var triggerOnce = triggerOnceField == null || MisParser.parseBoolean(triggerOnceField[0]);
		if (triggerOnce && this.triggered)
			return;
		this.triggered = true;

		var objectField = this.element.fields.get("object");
		var pathField = this.element.fields.get("path");
		if (objectField == null)
			return;

		var path:String = null;
		var i = 1;
		while (true) {
			var objectName = objectField[i];
			if (objectName == null || objectName == "")
				break;
			var target = this.level.namedGameObjects.get(objectName);
			if (target == null)
				break;

			var pathAtIndex = pathField != null ? pathField[i] : null;
			if (pathAtIndex != null && pathAtIndex != "")
				path = pathAtIndex;

			if (path != null)
				target.moveOnPath(path, this.level);

			i++;
		}
	}
}
